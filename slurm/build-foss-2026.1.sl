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
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGDIR="${REPO}/slurm/logs"

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

# Ordered top-level targets. Each is resolved+built (with all its
# dependencies) by a single `eb --robot` call. Order matters: each target
# depends on the previous ones already being installed.
#
# Update this list as Phase 5 (app migration) easyconfigs are added --
# append new targets at the end; existing ones are unaffected.
TARGETS=(
    "${REPO}/g/GCCcore-15.2.0.eb"
    "${REPO}/g/GCC-15.2.0.eb"
    "${UPSTREAM}/f/foss/foss-2026.1.eb"
    "${REPO}/r/R-4.6.1.eb"
    # R-4.6.1-foss-2026.1-MPI.eb deliberately excluded here -- paused on an
    # unfixed LLVM test-suite failure (see SESSION_STATUS.md). Add it back
    # once that's resolved.
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
    name="$(basename "${target}" .eb)"
    logfile="${LOGDIR}/${name}.log"

    echo "=== RESOLVING/BUILDING: ${target} ==="
    echo "    log: ${logfile}"

    clean_stale_locks

    eb --robot --parallel="${SLURM_CPUS_PER_TASK:-10}" "${target}" > "${logfile}" 2>&1
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
