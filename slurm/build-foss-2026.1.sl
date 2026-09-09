#!/bin/bash
#SBATCH --job-name=build-foss-2026.1
#SBATCH --partition=compute
#SBATCH --cpus-per-task=64
#SBATCH --mem=64G
#SBATCH --time=7-00:00:00
#SBATCH --output=slurm/logs/%x-%j.log
#
# Ordered, resumable driver for the foss/2026.1 toolchain generation build.
# Works identically for a dev build (as yourself) or a production build (as
# eri-apps-admin) -- it derives all paths from wherever THIS script is
# actually checked out, and installs to wherever `ebinit-2026.sh` points
# for whichever user runs it. Don't hardcode a personal path here again --
# see the "REPO" line below and the fix history in SESSION_STATUS.md for
# why that was a real bug (a previous version hardcoded one person's
# scratch checkout, which broke for every other user/checkout).
#
# WHY THIS DRIVER LOOKS THE WAY IT DOES
# --------------------------------------
# BUILD_ORDER.md lists ~113-125 individual modules, but this script does
# NOT walk that list module-by-module and invoke `eb` per module. That
# would mean re-implementing dependency resolution EasyBuild already does
# for free. Instead it calls `eb --robot` on a handful of TOP-LEVEL
# easyconfig targets (the compiler, the toolchain, R) and lets EasyBuild's
# own robot resolver walk the whole dependency chain per target, correctly
# skipping anything already installed -- natively, via EasyBuild's own
# already-installed detection. There is deliberately no separate
# "completed targets" marker file: a previous version of this script had
# one, and it caused a real bug (it lived under this repo's own checkout
# path, so a different user/checkout either couldn't write to it, or
# worse, silently trusted another user's marker instead of checking their
# own actual install path). `eb --robot` re-checking an already-installed
# target on every run costs a few seconds, not a rebuild -- that's a
# trivial cost for correctness.
#
# This mirrors exactly how this generation was actually built and debugged
# interactively (see SESSION_STATUS.md): every failure hit so far (Perl's
# own test suite failing on this GPFS filesystem, a flaky CPAN test, a GNU
# libtool bug triggered by the literal '@' in this cluster's $USER, a
# Bundle/component parameter-validation quirk, an LLVM test-suite parse
# failure) needed a human to read the actual error, decide whether it's a
# real break or an environment false-failure, and add a small local
# override easyconfig with a comment explaining why. None of that is
# something this script can or should attempt to automate. So on any
# failure, this script STOPS IMMEDIATELY (no automatic retry -- retrying
# an unfixed failure just fails again, identically, wasting the whole
# allocation): fix the specific package (see the `easybuild` skill for the
# fix pattern and known traps), then resubmit this same script --
# already-installed targets are skipped by EasyBuild itself, fast.
#
# See .claude/skills/easybuild/SKILL.md before touching this script or
# diagnosing a failure it reports.
#
# PREREQUISITE: EasyBuild/5.4.0 must already be built as a module for
# whichever user/tree runs this script (`ebinit-2026.sh` loads it by name,
# it does not build it). If you see "Lmod ... unknown module EasyBuild/5.4.0",
# that's this -- build it first:
#   eb e/EasyBuild-5.4.0.eb
# using a *working* EasyBuild 5.4.0 as the builder (not the site's older
# default), e.g. a throwaway `pip install easybuild==5.4.0` venv -- see the
# easybuild skill's "Why EasyBuild 5.4.0 is a hard requirement" section for
# the exact self-hosting bug this works around.

set -u

if [ -n "${SLURM_SUBMIT_DIR:-}" ]; then
    # Confirmed directly (job 5259737): under `sbatch`, Slurm copies the
    # submitted script into a SlurmdSpoolDir directory and executes that
    # copy, not the original file -- so BASH_SOURCE[0] resolves to
    # /var/spool/slurmd/jobNNNNN/... instead of this repo. Every path this
    # script derives from BASH_SOURCE then points into the spool dir too,
    # failing instantly ("mkdir: cannot create directory
    # '/var/spool/slurmd/slurm': Permission denied", then every TARGETS
    # entry "No such file or directory"). This is standard Slurm behaviour,
    # not specific to this cluster or user -- self-locating via
    # BASH_SOURCE simply does not work for a script run via `sbatch`.
    # SLURM_SUBMIT_DIR is the directory `sbatch` was invoked from, which
    # per this repo's own workflow (see README.md) is always the repo
    # root itself -- i.e. run `sbatch slurm/build-foss-2026.1.sl` from
    # inside your eri-easyconfigs checkout, not from within slurm/.
    REPO="${SLURM_SUBMIT_DIR}"
else
    # Not running under Slurm (e.g. `bash slurm/build-foss-2026.1.sl`
    # directly, for interactive testing) -- BASH_SOURCE-based self-location
    # is reliable in that case.
    REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
LOGDIR="${REPO}/slurm/logs"

if [ ! -f "${REPO}/g/GCCcore-15.2.0.eb" ]; then
    echo "ERROR: '${REPO}' doesn't look like the eri-easyconfigs checkout" \
         "(no g/GCCcore-15.2.0.eb found there)." >&2
    echo "SLURM_SUBMIT_DIR='${SLURM_SUBMIT_DIR:-<unset>}' -- if submitted via" \
         "sbatch, run it from the repo root: cd eri-easyconfigs && sbatch" \
         "slurm/build-foss-2026.1.sl" >&2
    exit 1
fi

# Points at a clone of https://github.com/easybuilders/easybuild-easyconfigs
# (develop branch), used as EASYBUILD_ROBOT_PATHS by ebinit-2026.sh. Lives
# in this shared, persistent location (moved here from a personal scratch
# dir, which was a real fragility risk -- a scratch-retention cleanup would
# have broken every future 2026.1-generation build, dev or production).
# Override with the UPSTREAM_ECS_CLONE env var if you need a different
# clone for some reason; otherwise this default must stay in sync with
# ebinit-2026.sh, which hardcodes the same path independently.
UPSTREAM="${UPSTREAM_ECS_CLONE:-/agr/persist/apps/share/upstream-easybuild-easyconfigs/easybuild/easyconfigs}"

mkdir -p "${LOGDIR}"

# Ordered top-level targets. Each entry is resolved+built (with all its
# dependencies) by a single `eb --robot` call. Order matters: each target
# depends on the previous ones already being installed.
#
# An entry can be MORE THAN ONE PATH, space-separated in one string --
# needed whenever the target's dependency closure includes local-override
# easyconfigs that sit deeper than the top-level file itself. EASYBUILD_ROBOT_PATHS
# (set by ebinit-2026.sh) points only at the upstream clone, never this repo
# (see the easybuild skill's "robot-path strategy" section -- shadowing
# upstream with this repo's files broke real dependency resolution once
# already), so any local override not passed explicitly on the command line
# is invisible to automatic dependency resolution, no matter how it's
# referenced in the target's own dependency tree. The loop below invokes
# each entry unquoted specifically so a multi-path entry word-splits into
# separate `eb` arguments.
#
# Update this list as Phase 5 (app migration) easyconfigs are added --
# append new targets at the end; existing ones are unaffected.
TARGETS=(
    "${REPO}/g/GCCcore-15.2.0.eb"
    "${REPO}/g/GCC-15.2.0.eb"
    "${UPSTREAM}/f/foss/foss-2026.1.eb"
    "${REPO}/r/R-4.6.1.eb"
    # R-4.6.1-foss-2026.1-MPI.eb -- re-enabled once the LLVM test-suite
    # failure was fixed (l/LLVM-21.1.8-GCCcore-15.2.0.eb, skip_all_tests).
    # Every local override anywhere in this target's dependency closure
    # must be listed explicitly here (see comment above) -- both Perl
    # builds, Perl-bundle-CPAN, Wayland, and LLVM all sit deep in this
    # tree and none of them are upstream files.
    "${REPO}/g/GCCcore-15.2.0.eb ${REPO}/g/GCC-15.2.0.eb ${REPO}/b/binutils-2.45.eb ${REPO}/p/Perl-5.42.0-GCCcore-15.2.0.eb ${REPO}/p/Perl-5.42.0.eb ${REPO}/p/Perl-bundle-CPAN-5.42.0-GCCcore-15.2.0.eb ${REPO}/w/Wayland-1.25.0-GCCcore-15.2.0.eb ${REPO}/l/LLVM-21.1.8-GCCcore-15.2.0.eb ${REPO}/r/R-4.6.1-foss-2026.1-MPI.eb"
)

source /agr/persist/apps/share/ebinit-2026.sh

# A build killed mid-package (OOM, walltime, a dropped SLURM step) leaves
# a lock file and a partial build/ dir behind even though nothing is still
# running -- see the easybuild skill's "stale locks" section. This driver
# only ever runs one `eb` at a time (never in parallel with itself), so if
# we get here it's safe to assume any existing lock is stale, not live.
clean_stale_locks() {
    # EASYBUILD_INSTALLPATH_SOFTWARE is only explicitly set (differently
    # from ${EASYBUILD_PREFIX}/software) for the eri-apps-admin case in
    # ebinit-2026.sh -- fall back to the PREFIX-derived default otherwise,
    # matching EasyBuild's own resolution order.
    local software_dir="${EASYBUILD_INSTALLPATH_SOFTWARE:-${EASYBUILD_PREFIX}/software}"
    local locks="${software_dir}/.locks"
    if [ -d "${locks}" ] && [ -n "$(ls -A "${locks}" 2>/dev/null)" ]; then
        echo "Removing stale lock(s) from a previous interrupted run:"
        ls "${locks}"
        rm -rf "${locks:?}"/*
    fi
}

for target in "${TARGETS[@]}"; do
    # A multi-path entry's actual build target is always the LAST path
    # listed (everything before it is a local override needed somewhere in
    # its dependency closure) -- name the log after that, not the whole
    # space-joined string.
    name="$(basename "${target##* }" .eb)"
    logfile="${LOGDIR}/${name}.log"

    echo "=== RESOLVING/BUILDING: ${target} ==="
    echo "    log: ${logfile}"

    clean_stale_locks

    # Deliberately unquoted: a multi-path entry must word-split into
    # separate `eb` arguments (see TARGETS comment above). No path in this
    # array contains spaces, so this is safe.
    eb --robot --parallel="${SLURM_CPUS_PER_TASK:-10}" ${target} > "${logfile}" 2>&1
    rc=$?

    if [ "${rc}" -eq 0 ]; then
        echo "=== SUCCESS (or already installed): ${target} ==="
    else
        echo "=== FAILED (exit ${rc}): ${target} ===" >&2
        echo "Full log: ${logfile}" >&2
        echo "" >&2
        echo "This driver stops on first failure -- see the header comment" >&2
        echo "in this script and .claude/skills/easybuild/SKILL.md for why," >&2
        echo "and for the established fix pattern (a small local override" >&2
        echo "easyconfig, tested standalone, then resubmit this script)." >&2
        echo "" >&2
        tail -40 "${logfile}" >&2
        exit "${rc}"
    fi
done

echo "=== ALL TARGETS COMPLETE ==="
