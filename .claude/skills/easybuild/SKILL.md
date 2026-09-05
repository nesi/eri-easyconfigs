---
name: easybuild
description: eRI-specific EasyBuild knowledge -- environment setup, the 2026.1 (GCC 15.2.0 / foss) toolchain generation, robot-path strategy, and known site traps. Use whenever building, diagnosing, or writing .eb files for this repo.
---

# EasyBuild on eRI

This repo (`eri-easyconfigs`) drives two parallel EasyBuild generations on the
same Rocky 8 cluster: the production `foss-2023a` / `GCC-12.3.0` stack (built
with `EasyBuild/4.9.2`), and the newer `foss-2026.1` / `GCC-15.2.0` stack
(requires `EasyBuild/5.4.0`). Knowing which one you're touching matters —
almost every trap below is a consequence of that split.

## Environment setup: two `ebinit` scripts

Both live in `/agr/persist/apps/share/`, both are `source`d, never executed.

- **`ebinit.sh`** — the original site script. Loads whatever `EasyBuild`
  module is default (currently 4.9.2), points `EASYBUILD_ROBOT_PATHS` at the
  production `ebfiles_repo`. Use for anything foss-2023a/GCC-12.3.0.
- **`ebinit-2026.sh`** — sibling script for the 2026.1 generation. Loads
  `EasyBuild/5.4.0` explicitly, points `EASYBUILD_ROBOT_PATHS` at a clone of
  upstream `easybuild-easyconfigs` (`develop` branch), and auto-adds this
  user's own scratch module tree to `MODULEPATH` (the original script only
  prints a suggestion to do this yourself). Use for anything 2026.1.

Both scripts key off `$USER` for the non-admin path. **On this cluster
`$USER` is `bixleym@agresearch.co.nz`, not `bixleym`** — the literal
`@agresearch.co.nz` is part of it. This changes the actual scratch install
path from what `README.md` documents (which says `$USER` under
`/agr/scratch/projects/2023-nesi_slurm_testing/`) — check `echo $USER` before
assuming a path.

Neither script needs `sudo` or admin rights to source; the branch inside each
script based on `$USER == eri-apps-admin` picks production vs. personal-scratch
paths automatically.

## Why EasyBuild 5.4.0 is a hard requirement for 2026.1

EasyBuild 4.9.2 cannot even *parse* the 2026.1-generation upstream
easyconfigs — confirmed by dry run, it aborts with `NameError:
V_VERSION_TAR_GZ is not defined` on `libdeflate-1.25-GCCcore-15.2.0.eb`, and
separately flags unknown parameters in the Python 3.14 and LLVM 21
easyconfigs (parameters that only exist in EB 5.x's easyblocks). There is no
way to build this generation with 4.9.2; don't try to work around it.

**Bootstrapping EB 5.4.0 itself has a known trap.** Building
`EasyBuild-5.4.0.eb` *via an already-installed EasyBuild* (even 5.4.0 itself,
if the interpreter is old) can hit a Python 3.6 `setuptools`/`easy_install`
bug: three sequential `setup.py install` calls (framework, easyblocks,
easyconfigs) into the same `site-packages` don't reliably append to
`easy-install.pth` — only the first package's entry survives, and the
`EB_EasyBuildMeta` easyblock's sanity check then fails with `Failed to find
pattern '^\./easybuild_easyblocks-5.4' in .../easy-install.pth`. This
reproduced when building with a *loaded* EasyBuild/4.9.2 module. The fix that
worked: **build EasyBuild-5.4.0.eb using a `pip install easybuild==5.4.0`
installation of EB 5.4.0 as the builder**, not the site's 4.9.2. A plain
`pip install easybuild==5.4.0` (in any Python venv, even throwaway) is also
the fastest way to get a working `eb` at all if you just need one immediately.

**No bootstrap Python is needed.** EasyBuild 5.4.0's `eb` wrapper only
requires Python ≥ 3.6 (`REQ_MIN_PY3VER=6`, checked directly in the wrapper
script). It runs — with a deprecation warning — on this cluster's system
Python 3.6.8. Don't build a separate Python module as a prerequisite; it adds
a step nothing here actually needs. If `EB_INSTALLPYTHON` (the interpreter
recorded at install time, e.g. a build venv's `python3`) ever disappears, the
`eb` wrapper degrades gracefully to plain `python3`/`python` on `$PATH` — it's
a soft preference, not a hard dependency, per the wrapper's own fallback
chain (`EB_PYTHON`, then `EB_INSTALLPYTHON`, then `python3`, then `python`,
skipping any that don't exist or can't `import easybuild.framework`).

## Robot-path strategy: upstream only, never shadow it with this repo

The instinctive move — put `eri-easyconfigs/` first on `EASYBUILD_ROBOT_PATHS`
so local files override upstream — is wrong for the 2026.1 generation and
**was verified to actually break dependency resolution.**

`eri-easyconfigs` and the upstream 2026.1 dependency closure share 11
filenames. Ten are the harmless, already-installed bootstrap chain
(M4/Bison/flex/zlib/binutils). The eleventh is `o/OpenSSL-3.eb`, which is a
real, still-needed part of the *2023a* stack (`toolchain = SYSTEM`, wraps the
system OpenSSL 1.1.1k) — but it pins `pkgconf 1.8.0` / `Perl 5.38.2`, two
generations behind what upstream's 2026.1-era `OpenSSL-3.eb` needs
(`pkgconf 2.5.1` / `Perl 5.42.0`). `OpenSSL-3.eb` sits deep in the R 4.6.1
dependency chain (closure position ~57 of ~113). Shadow it with the local
2023a-era copy and the 2026.1 stack silently gets 2023a build tools with no
error — a correctness bug, not a crash.

**The rule:** `EASYBUILD_ROBOT_PATHS` for the 2026.1 generation contains
*only* the upstream clone. Local eRI deltas for this generation (GCCcore's
extra GMP patch, the M4 mirror-timeout fix, the binutils `ld.gold` easyblock
bypass, `R-4.6.1-foss-2026.1-MPI.eb`, ported application `.eb` files) are
always passed to `eb` **by explicit path**, e.g.:

```bash
eb --robot g/GCCcore-15.2.0.eb          # local file, robot resolves its deps upstream
eb --robot r/R-4.6.1-foss-2026.1-MPI.eb # same pattern
```

This works because EasyBuild's dependency resolver treats "the directory
containing the easyconfig you asked for" and "the robot path" as separate,
both-searched locations (confirmed in
`easybuild.framework.easyblock.obtain_file_raise_on_failure`: it always
checks `os.path.dirname(self.cfg.path)` first, *then* falls back to
`self.robot_path` — this applies to source/patch lookup too, not just
easyconfig resolution, so a locally-patched easyconfig can reference patch
files that live only in the upstream clone and vice versa).

`BUILD_ORDER.md` records the exact path used for every entry, so "which file
built this module" is never an artefact of search-path ordering.

## Computing a build order

```bash
source /agr/persist/apps/share/ebinit-2026.sh
eb --robot -D <target.eb>
```

`-D` (`--dry-run`) with `--robot` prints the full resolved dependency chain in
build order, each line marked `[x]` (already installed) or `[ ]` (needs
building), with the full path of the easyconfig file that will actually be
used — the fastest way to confirm a local override is really being picked up
(or isn't). No network or build cost. Re-run this after any change to a local
easyconfig's dependency versions, and after every reconciliation pass against
a moving upstream `develop` branch.

To confirm a specific easyconfig's declared module name/version string
(matters for anything relying on `versionsuffix`, since EasyBuild's default
naming scheme always embeds `toolchain-name-toolchain-version` unless the
toolchain is `SYSTEM`), the `-D` output's `(module: ...)` annotation is
authoritative — trust it over guessing from the filename.

## Known site traps

- **GNU mirror timeouts.** `ftpmirror.gnu.org` (the `GNU_SOURCE` constant)
  times out repeatedly from this cluster for some packages (confirmed:
  M4 1.4.20). Direct `ftp.gnu.org` URLs are the confirmed-working fix. Not
  every GNU package hits this — M4 1.4.19 uses `GNU_SOURCE` unmodified and
  builds fine — so don't pre-emptively rewrite every GNU_SOURCE reference,
  only ones that actually fail.
- **The `ld.gold` easyblock trap.** `easybuild.easyblocks.binutils`
  hardcodes `self.use_gold = get_cpu_family() != RISCV`, and its
  `sanity_check_step()` builds its own `custom_paths` from that — ignoring
  whatever `sanity_check_paths` the easyconfig sets — so on any non-RISC-V
  build it unconditionally expects `ld.gold` to exist. binutils ≥ 2.45 has
  dropped `ld.gold` entirely upstream, so `EB_binutils` can never pass sanity
  checking for a SYSTEM-toolchain binutils ≥ 2.45 build, regardless of what
  the easyconfig says. Fix: bypass the dedicated easyblock
  (`easyblock = 'ConfigureMake'`) and replicate `EB_binutils`'s own configure
  flags by hand. This is a real upstream easyblock/version-interaction bug,
  not a site quirk — it will resurface for anyone building binutils ≥ 2.45
  on a SYSTEM toolchain, on any site.
- **GCC 15 + GMP 6.3.0 conformance break.** GMP 6.3.0's bundled `configure`
  has an ancient K&R-style self-test (`void g(){}` called with 6 arguments)
  that GCC 15's tightened C conformance rejects outright
  ("too many arguments to function 'g'"). This only hits the `EB_GCC`
  easyblock's separate `stage2_stuff` bootstrap sub-build of GMP (a
  standalone PIC-static configure, distinct from the in-tree build that
  `GCCcore-9.3.0_gmp-c99.patch` already covers). Fixed by a local patch
  (`GCCcore-15.2.0_fix-gmp-configure-void-g.patch`) applied via the 2-tuple
  `sourcepath` mechanism (`'../gmp-6.3.0'`, since GMP is extracted as a
  sibling directory of `gcc-15.2.0/`, not a subdirectory — EasyBuild's patch
  framework has no "source index" option, so `sourcepath` is the only way to
  redirect a patch to a sibling source tree). Applies to any GCC ≥ 15 build
  against GMP 6.3.0, on any site.
- **SYSTEM/GCCcore linker-mixing trap** (see also project memory
  `easybuild_toolchain_mixing_gotcha`) — **reproduced directly this session.**
  `binutils` is a `builddependencies` entry for `GCCcore`, not a runtime one,
  so EasyBuild does not emit a Lmod `depends_on("binutils")` in the generated
  `GCCcore/X.Y.Z.lua` module. A bare `module load GCCcore/15.2.0` alone
  leaves `$PATH` pointing at the *system* `ld` (confirmed: reported
  `GNU ld version 2.30-117.el8`, the RHEL8 default, and threw
  `unable to initialize decompress status for section .debug_info` warnings
  compiling anything — GCC 15 emits debug info the old linker doesn't fully
  understand). Compiles still "succeed" in this state, which makes it easy to
  miss. Every *real* package build is unaffected — EasyBuild's own toolchain
  preparation always loads `binutils` alongside `GCCcore`/`GCC` for anything
  declaring that toolchain — but any interactive/manual verification must
  load both explicitly: `module load GCCcore/15.2.0 binutils/2.45`. Don't
  trust a bare `ld --version` or even `which ld` to prove this either — both
  just resolve `$PATH`. The reliable check is what GCC itself would actually
  invoke: `gcc -print-prog-name=ld` (or `-print-prog-name=as`), confirmed
  against `binutils/2.45`'s installdir, not just "some ld exists."
- **OOM-looks-like-ICE trap** (see also project memory
  `eri-slurm-session-memory-limit`). An interactive Claude Code session's
  SLURM allocation can be memory-constrained in ways that produce compiler
  crashes indistinguishable from real ICEs. Before treating a GCC/GCCcore
  build failure as a real compiler bug, check `free -h` and the SLURM job's
  actual `mem=` allocation (`scontrol show job $SLURM_JOB_ID`) — this
  session's allocation has varied from as little as ~2GB to 20GB across
  different runs, so never assume it's adequate.
- **Stale locks from interrupted builds.** An EasyBuild build killed
  mid-compile (OOM, session timeout, `Ctrl-C`) leaves a lock file under
  `<installpath>/software/.locks/` and a partial directory under
  `<installpath>/build/<name>/<version>/`. `eb` refuses to proceed
  ("Lock ... already exists, aborting!") even though nothing is actually
  running. Confirm with `ps` that no matching `make`/`eb` process is alive,
  then `rm -rf` both the lock and the partial build directory before
  retrying — the build directory is ephemeral compilation output, not a
  deliverable, so this is always safe once you've confirmed nothing is live.
- **Apptainer bind paths.** `/etc/apptainer/apptainer.conf` on this cluster
  has `mount hostfs = no` — Apptainer does *not* auto-bind the whole host
  filesystem. `/agr/scratch` and `/agr/persist` *do* work without any
  explicit `--bind` in an interactive shell, because `APPTAINER_BIND=
  /agr/persist,/agr/scratch` is already set globally in the login
  environment — but that's an environment variable, not an Apptainer config
  guarantee, so it won't be present in every context (e.g. a stripped-down
  cron job or a minimal subprocess environment). Any EasyBuild module that
  wraps a container should still pass `--bind /agr/persist,/agr/scratch`
  explicitly in its own wrapper scripts rather than relying on inherited
  environment. Passing both (env var + explicit flag) is harmless — Apptainer
  just warns "destination is already in the mount point list" and continues.
- **Perl's own test suite fails on GPFS.** Both `Perl-5.42.0-GCCcore-15.2.0.eb`
  and the separate SYSTEM-toolchain `Perl-5.42.0.eb` (a different easyconfig,
  needed by the SYSTEM-toolchain Autoconf/Automake/libtool chain -- watch for
  more than one Perl build in a single dependency closure) fail their `make
  test_harness` step identically: 7 of ~1.35 million individual test
  assertions, concentrated in filesystem permission/stat-semantics-sensitive
  tests (`can_write_dir.t`, `stat.t`, `Manifest.t`, `Packlist.t`,
  `Mkbootstrap.t`, `File-Glob/basic.t`) -- a well-known class of false
  failure for Perl's test suite on a network filesystem (this scratch tree is
  GPFS, not local disk). Perl itself configures and builds cleanly in both
  cases; only the test harness trips. Fix: `runtest = False` in a local
  override (EasyBuild's own sanctioned escape hatch, per a comment in
  `easybuild.easyblocks.perl.EB_Perl.test_step`), built standalone once, then
  the main robot build picks it up as already-installed. If a third
  Perl-family or other-CPAN-module test failure shows the same
  filesystem-semantics signature, the same fix applies.
- **The `@` in `$USER` breaks GNU libtool's relink step.** `$USER` on this
  cluster is `bixleym@agresearch.co.nz`, so every non-admin install prefix
  contains a literal `@`. GNU libtool's shared-library relink step (used by
  any Autotools-family package installing a versioned `.so` via libtool --
  confirmed with `BLIS-2.0-GCC-15.2.0.eb`, which links `libblis.so.4` /
  `libblis.so.4.0.0`) uses `sed 's@OLD@NEW@'`-style path substitution
  internally, and that substitution silently corrupts when the path being
  substituted *itself* contains a literal `@`: `make install` exits 0 and
  writes a fully complete, correct install tree, just at the wrong path --
  the literal substring `@agresearch` gets deleted from wherever it occurs.
  Confirmed byte-for-byte:
  `.../bixleym@agresearch.co.nz/.../BLIS/2.0-GCC-15.2.0` became
  `.../bixleym.co.nz/.../BLIS/2.0-GCC-15.2.0`, exactly the string minus
  `@agresearch`. EasyBuild's sanity check then correctly reports every
  expected file missing (it's checking the real, unmangled path). This is
  **not** a BLIS-specific bug and can recur in any future package that does
  libtool shared-library relinking -- watch for a sanity-check failure
  where every single expected file is "missing" right after a `make`/`make
  install` step that itself exited 0, and check whether the real files
  landed under `$(dirname install-prefix)` with `@agresearch` stripped out
  before assuming something is actually broken.
  **Fix pattern** (see `b/BLIS-2.0-GCC-15.2.0.eb`): add `postinstallcmds`
  that computes the mangled path and moves it into the real installdir
  *before* EasyBuild's sanity check runs (`postinstallcmds` execute during
  the "postprocessing" step, which precedes "sanity checking"). Use bash's
  `${var/pattern/replacement}` for the transform, **not** `sed` -- sed's own
  `@`-delimited substitution is the root cause, so don't reintroduce it in
  the fix:
  ```bash
  mangled="%(installdir)s"; mangled="${mangled/@agresearch/}"
  test -d "$mangled" && rm -rf "%(installdir)s" && mv "$mangled" "%(installdir)s"
  ```
  This is a pre-existing site characteristic, not something introduced by
  the 2026.1 work -- the original `foss-2023a` stack has the identical `@`
  in every personal-scratch install prefix (see `ebinit.sh`) and would hit
  the same bug under the same conditions; it just hasn't been provoked
  there yet by a package with this exact libtool usage pattern. Fixing the
  root cause (removing `@` from install paths entirely) would mean
  migrating every already-built module's baked-in absolute paths, which is
  far riskier than patching packages as they're individually hit -- not
  attempted.
- **`srun` has no PMIx plugin; use `mpirun` for MPI verification.**
  `srun --mpi=list` on this cluster offers only `cray_shasta`, `none`,
  `pmi2` -- no `pmix`, even though OpenMPI 5.0.10/PRRTE (built as part of
  `foss/2026.1`) expect PMIx by default. `srun --mpi=pmi2 --ntasks=2 ...`
  runs without erroring but silently launches 2 *independent* rank-0
  singletons (OpenMPI prints "No PMIx server was reachable, but a PMI1/2
  was detected... 2 singletons will be started") rather than one
  2-rank job -- easy to mistake for a working test since it doesn't
  fail loudly. And a plain `srun --ntasks=2` with no `--mpi=` at all just
  hangs (needs `--overlap` to even launch inside an already-running
  interactive job step). Use OpenMPI's own launcher instead:
  `mpirun -np 2 --oversubscribe ./a.out` -- PRRTE detects the SLURM
  allocation itself and coordinates ranks correctly, without going through
  `srun`'s MPI plugin at all (`--oversubscribe` needed in this
  Claude-Code-session context specifically; PRRTE's slot detection
  otherwise reports "not enough slots" for 2 ranks in a 10-CPU allocation,
  root cause not fully diagnosed -- may not be needed in a plain `sbatch`
  script).
- **A `Bundle`'s per-component custom parameter can be rejected even
  though it's valid for that component's own easyblock.** Hit with
  upstream's `Wayland-1.25.0-GCCcore-15.2.0.eb`: `easyblock = 'Bundle'`,
  `default_easyblock = 'MesonNinja'`, and one component sets `'ndebug':
  False` (a real, documented `MesonNinja` parameter, confirmed present in
  `easybuild.easyblocks.generic.mesonninja.MesonNinja.extra_options()`).
  Fails immediately at parse time with `ERROR: Failed to get application
  instance for Wayland (easyblock: Bundle): Use of unknown easyconfig
  parameter 'ndebug'` -- something in how this EasyBuild version's `Bundle`
  validates nested per-component keys rejects it before ever resolving the
  component's own easyblock, even though the parameter is legitimate once
  resolved. Not investigated further (a framework-version-compatibility
  quirk, not a real config error). Fix: drop the offending key in a local
  override if upstream's own comment shows it's only there for that
  component's *own* test suite (as with `ndebug` here, commented "required
  for tests") -- omitting it just reverts to that easyblock's documented
  default. If a future `Bundle`+per-component parameter hits the same
  "unknown easyconfig parameter" error but isn't test-related, this
  shortcut doesn't apply and the actual parameter needs to be preserved
  some other way (e.g. investigating whether the installed easybuild
  version's `Bundle` needs the key in `default_component_specs` instead of
  per-component, or reporting upstream).
- **A bare `builddependencies` tuple can fail to resolve to an
  already-built subtoolchain module, even though the equivalent works
  fine for regular `dependencies`.** Hit porting `NCO-4.8.1-gompi-2026.1.eb`:
  a bare `('ANTLR', '2.7.7')` builddependency failed with `ERROR: Missing
  dependencies: ANTLR/2.7.7-gompi-2026.1 (no easyconfig file or existing
  module found)` even though ANTLR was already built at `GCC-15.2.0` -- a
  genuine subtoolchain of `gompi-2026.1`. Passing both files together to
  `eb --robot -D` did **not** change this -- not a robot-path visibility
  issue. Fix: give it an explicit toolchain tuple,
  `('ANTLR', '2.7.7', '', ('GCC', '15.2.0'))`.
  **This is not a blanket rule, though** -- a bare `('CMake', '4.2.1')`
  builddependency in `g2clib-1.7.0-GCC-15.2.0.eb` (parent toolchain
  `GCC-15.2.0`) resolved perfectly fine against `CMake/4.2.1-GCCcore-15.2.0`
  (a subtoolchain one level down) with no explicit tuple needed. The exact
  boundary of when a builddependency's implicit subtoolchain search does
  or doesn't reach far enough isn't fully characterized -- possibly related
  to gompi's MPI-inclusive hierarchy vs GCC's simpler one, not investigated
  further. Practical upshot: if a builddependency mysteriously fails to
  resolve to a module you can see is already built, try adding an explicit
  toolchain tuple -- don't assume you need to add one everywhere pre-emptively.

  **This turned out to be one instance of a broader, more important
  pattern, confirmed across several Phase 5 app-migration files**: a bare
  dependency tuple (in `dependencies`, not just `builddependencies`) that
  needs a subtoolchain hop to resolve (e.g. parent toolchain `foss-2026.1`,
  dependency built at `GCC-15.2.0` or `gompi-2026.1`) will silently show up
  as `Missing dependencies: ... (no easyconfig file or existing module
  found)` in a dry-run **if the dependency is a local-only easyconfig with
  no upstream equivalent at that exact name+version+toolchain** -- even
  when you pass both files together to `eb --robot -D`. This does NOT
  happen when upstream happens to independently provide a matching
  easyconfig at the needed toolchain (then the robot path satisfies the
  subtoolchain search directly and everything looks fine) -- it only bites
  for genuinely site-local dependencies. Confirmed hitting this for:
  `ESMF-8.4.2-foss-2026.1.eb` → `libarchive` (GCC-15.2.0, no upstream
  equivalent at 3.7.2), `DAS_Tool-...-foss-2026.1-R-4.6.1.eb` → `Ruby`
  (GCC-15.2.0), `eggnog-mapper-...-foss-2026.1-...eb` → `MMseqs2`
  (gompi-2026.1, no upstream equivalent at 15-6f452). Not hit for `R`
  itself or `CheckM` as dependencies elsewhere, because those *were*
  passed with an explicit toolchain tuple already (R) or matched the
  parent's exact toolchain with no hop needed (CheckM under
  RFPlasmid, both foss-2026.1).

  **Practical rule for validating any Phase 5 port**: when a dry-run
  reports a dependency "missing" that you can see is actually a real file
  in this repo, don't just assume it's a genuine gap -- check whether it's
  built at the exact same toolchain as the parent (no fix needed, likely a
  different local-file-visibility issue) or a subtoolchain (add an
  explicit `('Name', 'version', 'versionsuffix', ('Toolchain', 'version'))`
  tuple, then re-test with both files passed to `eb --robot -D` together).
  Only trust a "missing" report as a genuine gap after confirming this.
- **Pin container tags, never `latest`.** eRI already has a cautionary
  example: `/agr/persist/apps/containers/R/geospatial_latest.sif`, pulled
  April 2025, undated in any module, silently stale. Always pull a numbered
  tag and record the pull date/tag in the easyconfig.

## Dev → test → production workflow (from `README.md`)

1. As yourself: `source ebinit.sh` (or `ebinit-2026.sh`), `git pull`,
   `eb <file>.eb` — builds into your personal scratch install path.
2. Test: `module use <your-scratch-installpath>/modules/all`, load, verify.
3. `git push` once it works.
4. As `eri-apps-admin` (`sudo -i -u eri-apps-admin`): `git pull`,
   `eb <file>.eb` — builds into the shared production tree at
   `/agr/persist/apps/eri_rocky8/`.

**Never push to git from `eri-apps-admin`** — README is explicit about this;
it's a promotion account, not a development one.

## House style

- No upstream-style author/license header blocks, and no
  `# Built with EasyBuild version X on DATE` auto-generated headers — this
  repo strips both.
- When a local file deviates from upstream, say *why*, not just *what* — the
  GCCcore, binutils, and M4 files in this repo are the model to follow: a
  comment block explaining the actual failure mode, why the generic fix
  doesn't apply, and (where relevant) that it's confirmed by hand, not just
  theorized.
- Prefer deleting a local file entirely over maintaining a diverged copy, when
  the only reason it exists is old-toolchain-version drift and it now matches
  upstream. Robot-path resolution handles it just as well and there's one
  fewer file to keep in sync.
