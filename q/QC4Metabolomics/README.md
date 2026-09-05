# QC4Metabolomics module

QC4Metabolomics is a fully containerized Shiny app (see
`/agr/persist/projects/2026_metabolomics/apps/QC4Metabolomics/`) - there is
nothing for EasyBuild to compile. Following the SVS precedent
(`/agr/persist/apps/eri_rocky8/modules/all/SVS/*.lua`), this is a
**hand-written Lmod module with no matching `.eb` file**: `1.0.12.lua` just
`prepend_path`s `bin/` onto `PATH`, where `bin/qc4metabolomics` is a wrapper
that ensures the Apptainer instance stack is running and opens the Shiny UI
in a browser. Intended for use inside an interactive OnDemand/desktop
session (needs an X11 display + browser), not a batch job.

Since there's no `eb` build step, deploying this to production is a manual
copy, mirroring the SVS software/module layout referenced in its `.lua`
(`/agr/persist/apps/eri_rocky8/software/SVS/<version>/bin`,
`/agr/persist/apps/eri_rocky8/modules/all/SVS/<version>.lua`):

```bash
# as eri-apps-admin
mkdir -p /agr/persist/apps/eri_rocky8/software/QC4Metabolomics/1.0.12/bin
cp bin/qc4metabolomics /agr/persist/apps/eri_rocky8/software/QC4Metabolomics/1.0.12/bin/
mkdir -p /agr/persist/apps/eri_rocky8/modules/all/QC4Metabolomics
cp 1.0.12.lua /agr/persist/apps/eri_rocky8/modules/all/QC4Metabolomics/
```

## Why the wrapper doesn't use `--fakeroot` (unlike the project's own `run_qc.sh`)

No real eRI account has an `/etc/subuid`/`/etc/subgid` range (checked: only template
accounts like `cloud-user`/`podman`/`testuser` do), and `newuidmap`/`newgidmap` aren't
setuid-root either - so `apptainer instance start --fakeroot` silently dies moments
after printing "instance started successfully", on every node this was checked on
(both a login node and a compute node, same account). `run_qc.sh` would hit this too.

This is a cluster config gap for eRI admins to fix (provisioning subuid/subgid ranges
+ restoring setuid on newuidmap/newgidmap), not something fixable from a script. In
the meantime, `bin/qc4metabolomics` runs every instance as your own regular user
instead, which needed three workarounds (all confirmed end-to-end: real
`settings_demo.env`, mariadb provisioned, Shiny UI returning HTTP 200):

- bind a **real host directory** onto any path a container writes outside its own
  data-dir binds (e.g. `/run/mysqld`, `/run`, shiny's log/lib dirs) - apptainer's
  `--writable-tmpfs` overlay upper layer fails with ENODATA/EINVAL for many writes
  (socket binds, chown to a uid other than your own) when it isn't backed by a real
  filesystem under a non-fakeroot userns.
- **mariadb**: its container entrypoint never runs here, so the wrapper does
  first-run bootstrap by hand (`mariadb-install-db`, then creates the app's
  database/user and deletes the default anonymous user, which otherwise intercepts
  localhost auth ahead of the named user). Drop `--user=root` from `mariadbd`. Client
  tools (`mariadb-admin`, `mariadb`) need `--skip-ssl` too, not just the server.
- **qc_shiny**: its `/init` (s6-overlay) entrypoint hard-requires real root to chown
  files to the `shiny` user, so the wrapper bypasses `/init` entirely and execs
  `shiny-server` directly, after substituting a `shiny-server.conf` with `run_as`
  pointed at your own user (shiny-server refuses to start otherwise) and an
  `Renviron.site` built from `settings_demo.env` (shiny-server resets the environment
  for each app's R session, so without this the app sees none of its DB config - this
  is normally done by the image's own s6 cont-init script, which is skipped along
  with the rest of `/init`).

`qc_process`, `ms_converter` and `db_backup` got the same no-fakeroot/real-bind-dir
treatment by analogy but were not exercised as thoroughly as mariadb/qc_shiny - check
their logs under `$STATE_DIR` (printed by the wrapper at startup) if one misbehaves.
