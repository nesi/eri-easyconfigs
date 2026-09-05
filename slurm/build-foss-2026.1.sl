#!/bin/bash
#SBATCH --job-name=build-foss-2026.1
#SBATCH --partition=compute
#SBATCH --cpus-per-task=64
#SBATCH --mem=64G
#SBATCH --time=7-00:00:00
#SBATCH --output=slurm/logs/%x-%j.log
#
# Ordered, resumable driver for the foss/2026.1 toolchain generation build.
#
# WHY THIS DRIVER LOOKS THE WAY IT DOES
# --------------------------------------
# BUILD_ORDER.md lists ~113-125 individual modules, but this script does
# NOT walk that list module-by-module and invoke `eb` per module. That
# would mean re-implementing dependency resolution EasyBuild already does
# for free. Instead it calls `eb --robot` on a handful of TOP-LEVEL
# easyconfig targets (the compiler, the toolchain, R) and lets EasyBuild's
# own robot resolver walk the whole dependency chain per target, correctly
# skipping anything already installed.
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
# allocation) and leaves a clear marker for a human to pick up: fix the
# specific package (see the `easybuild` skill for the fix pattern and
# known traps), then resubmit this same script -- already-completed
# targets are skipped via the completion marker file.
#
# See .claude/skills/easybuild/SKILL.md before touching this script or
# diagnosing a failure it reports.

set -u
REPO="/mnt/gpfs/scratch/projects/2023-nesi_slurm_testing/mattb/eri-easyconfigs"
LOGDIR="${REPO}/slurm/logs"
COMPLETED="${LOGDIR}/completed_targets.txt"
UPSTREAM="/agr/scratch/projects/2023-nesi_slurm_testing/mattb/upstream-ecs/easybuild/easyconfigs"

mkdir -p "${LOGDIR}"
touch "${COMPLETED}"

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

is_completed() {
    grep -qxF "$1" "${COMPLETED}" 2>/dev/null
}

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
    if is_completed "${target}"; then
        echo "=== SKIP (already completed): ${target} ==="
        continue
    fi

    name="$(basename "${target}" .eb)"
    logfile="${LOGDIR}/${name}.log"

    echo "=== BUILDING: ${target} ==="
    echo "    log: ${logfile}"

    clean_stale_locks

    eb --robot --parallel="${SLURM_CPUS_PER_TASK:-10}" "${target}" > "${logfile}" 2>&1
    rc=$?

    if [ "${rc}" -eq 0 ]; then
        echo "${target}" >> "${COMPLETED}"
        echo "=== SUCCESS: ${target} ==="
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
