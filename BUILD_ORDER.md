# Build order -- foss/2026.1 toolchain generation

Generated from `eb --robot -D` under EasyBuild 5.4.0 (`ebinit-2026.sh`). Regenerate after any change to a local easyconfig's dependencies:

```bash
source /agr/persist/apps/share/ebinit-2026.sh
eb --robot -D r/R-4.6.1-foss-2026.1-MPI.eb
```

**Upstream pin:** `easybuild-easyconfigs` @ `a5d92f424ff25953d99b6332485b0c70d141ba2a` (2026-09-03), cloned at
`/agr/scratch/projects/2023-nesi_slurm_testing/mattb/upstream-ecs`.

Legend: `[x]` already installed in this user's scratch tree at generation time; `[ ]` still to build. `local` = file lives in this repo; `upstream` = resolved from the pinned clone via `EASYBUILD_ROBOT_PATHS` (see the `easybuild` skill for why this repo is never itself on the robot path).

## Phase 2+3 -- compiler and foss/2026.1 toolchain

(First 73 entries of the R-MPI closure below, up to and including `foss/2026.1` itself. Build in this exact order.)

| # | Status | Module | Source |
|---|---|---|---|
| 1 | [x] | `M4/1.4.20` | upstream |
| 2 | [x] | `zlib/1.3.1` | upstream |
| 3 | [x] | `M4/1.4.19` | upstream |
| 4 | [x] | `Bison/3.8.2` | upstream |
| 5 | [x] | `flex/2.6.4` | upstream |
| 6 | [x] | `binutils/2.45` | upstream |
| 7 | [x] | `GCCcore/15.2.0` | upstream |
| 8 | [x] | `M4/1.4.20-GCCcore-15.2.0` | upstream |
| 9 | [x] | `zlib/2.3.2-GCCcore-15.2.0` | upstream |
| 10 | [x] | `help2man/1.49.3-GCCcore-15.2.0` | upstream |
| 11 | [x] | `Bison/3.8.2-GCCcore-15.2.0` | upstream |
| 12 | [x] | `flex/2.6.4-GCCcore-15.2.0` | upstream |
| 13 | [x] | `binutils/2.45-GCCcore-15.2.0` | upstream |
| 14 | [x] | `libtool/2.5.4-GCCcore-15.2.0` | upstream |
| 15 | [x] | `Perl/5.42.0-GCCcore-15.2.0` | upstream |
| 16 | [x] | `bzip2/1.0.8-GCCcore-15.2.0` | upstream |
| 17 | [x] | `libxml2/2.15.1-GCCcore-15.2.0` | upstream |
| 18 | [x] | `libiconv/1.18-GCCcore-15.2.0` | upstream |
| 19 | [x] | `libpng/1.6.56-GCCcore-15.2.0` | upstream |
| 20 | [x] | `groff/1.24.1-GCCcore-15.2.0` | upstream |
| 21 | [x] | `UnZip/6.0-GCCcore-15.2.0` | upstream |
| 22 | [x] | `Autoconf/2.72-GCCcore-15.2.0` | upstream |
| 23 | [x] | `Automake/1.18.1-GCCcore-15.2.0` | upstream |
| 24 | [x] | `Autotools/20250626-GCCcore-15.2.0` | upstream |
| 25 | [x] | `pkgconf/2.5.1-GCCcore-15.2.0` | upstream |
| 26 | [x] | `ncurses/6.6-GCCcore-15.2.0` | upstream |
| 27 | [x] | `gettext/0.26-GCCcore-15.2.0` | upstream |
| 28 | [x] | `libreadline/8.3-GCCcore-15.2.0` | upstream |
| 29 | [x] | `XZ/5.8.2-GCCcore-15.2.0` | upstream |
| 30 | [x] | `expat/2.7.3-GCCcore-15.2.0` | upstream |
| 31 | [x] | `libidn2/2.3.8-GCCcore-15.2.0` | upstream |
| 32 | [x] | `PCRE2/10.47-GCCcore-15.2.0` | upstream |
| 33 | [x] | `xorg-macros/1.20.2-GCCcore-15.2.0` | upstream |
| 34 | [x] | `libffi/3.5.2-GCCcore-15.2.0` | upstream |
| 35 | [x] | `lz4/1.10.0-GCCcore-15.2.0` | upstream |
| 36 | [x] | `libyaml/0.2.5-GCCcore-15.2.0` | upstream |
| 37 | [x] | `libunistring/1.4.1-GCCcore-15.2.0` | upstream |
| 38 | [x] | `gperf/3.3-GCCcore-15.2.0` | upstream |
| 39 | [x] | `Perl/5.42.0` | upstream |
| 40 | [x] | `libtommath/1.3.0-GCCcore-15.2.0` | upstream |
| 41 | [x] | `Tcl/9.0.3-GCCcore-15.2.0` | upstream |
| 42 | [x] | `SQLite/3.51.1-GCCcore-15.2.0` | upstream |
| 43 | [x] | `NASM/3.01-GCCcore-15.2.0` | upstream |
| 44 | [x] | `gzip/1.14-GCCcore-15.2.0` | upstream |
| 45 | [x] | `zstd/1.5.7-GCCcore-15.2.0` | upstream |
| 46 | [x] | `M4/1.4.21` | upstream |
| 47 | [x] | `Autoconf/2.72` | upstream |
| 48 | [x] | `Automake/1.18.1` | upstream |
| 49 | [x] | `libtool/2.5.4` | upstream |
| 50 | [x] | `giflib/6.1.3-GCCcore-15.2.0` | upstream |
| 51 | [x] | `jbigkit/2.1-GCCcore-15.2.0` | upstream |
| 52 | [x] | `Autotools/20250626` | upstream |
| 53 | [x] | `pkgconf/2.5.1` | upstream |
| 54 | [x] | `OpenSSL/3` | upstream |
| 55 | [x] | `Perl-bundle-CPAN/5.42.0-GCCcore-15.2.0` | upstream |
| 56 | [x] | `Python/3.14.2-GCCcore-15.2.0` | upstream |
| 57 | [x] | `libarchive/3.8.5-GCCcore-15.2.0` | upstream |
| 58 | [x] | `libpsl/0.21.5-GCCcore-15.2.0` | upstream |
| 59 | [x] | `Cython/3.2.4-GCCcore-15.2.0` | upstream |
| 60 | [x] | `psutil/7.2.1-GCCcore-15.2.0` | upstream |
| 61 | [x] | `elfutils/0.195-GCCcore-15.2.0` | upstream |
| 62 | [x] | `lit/18.1.8-GCCcore-15.2.0` | upstream |
| 63 | [x] | `intltool/0.51.0-GCCcore-15.2.0` | upstream |
| 64 | [x] | `Mako/1.3.12-GCCcore-15.2.0` | upstream |
| 65 | [x] | `cURL/8.17.0-GCCcore-15.2.0` | upstream |
| 66 | [x] | `Ninja/1.13.2-GCCcore-15.2.0` | upstream |
| 67 | [x] | `PyYAML/6.0.3-GCCcore-15.2.0` | upstream |
| 68 | [x] | `CMake/4.2.1-GCCcore-15.2.0` | upstream |
| 69 | [x] | `Meson/1.10.2-GCCcore-15.2.0` | upstream |
| 70 | [x] | `Doxygen/1.17.0-GCCcore-15.2.0` | upstream |
| 71 | [x] | `glslang-SPIRV/16.3.0-GCCcore-15.2.0` | upstream |
| 72 | [x] | `pixman/0.46.4-GCCcore-15.2.0` | upstream |
| 73 | [x] | `Brotli/1.2.0-GCCcore-15.2.0` | upstream |
| 74 | [x] | `libjpeg-turbo/3.1.4.1-GCCcore-15.2.0` | upstream |
| 75 | [x] | `libpciaccess/0.19-GCCcore-15.2.0` | upstream |
| 76 | [x] | `util-linux/2.42-GCCcore-15.2.0` | upstream |
| 77 | [x] | `Wayland/1.25.0-GCCcore-15.2.0` | upstream |
| 78 | [x] | `freetype/2.14.3-GCCcore-15.2.0` | upstream |
| 79 | [x] | `GLib/2.89.0-GCCcore-15.2.0` | upstream |
| 80 | [x] | `fontconfig/2.17.1-GCCcore-15.2.0` | upstream |
| 81 | [x] | `X11/20260518-GCCcore-15.2.0` | upstream |
| 82 | [x] | `cairo/1.18.4-GCCcore-15.2.0` | upstream |
| 83 | [x] | `libgit2/1.9.4-GCCcore-15.2.0` | upstream |
| 84 | [x] | `libdrm/2.4.133-GCCcore-15.2.0` | upstream |
| 85 | [x] | `git/2.52.0-GCCcore-15.2.0` | upstream |
| 86 | [x] | `libdeflate/1.25-GCCcore-15.2.0` | upstream |
| 87 | [x] | `Java/21.0.8` | upstream |
| 88 | [x] | `LibTIFF/4.7.1-GCCcore-15.2.0` | upstream |
| 89 | [x] | `Java/21` | upstream |
| 90 | [x] | `libwebp/1.6.0-GCCcore-15.2.0` | upstream |
| 91 | [x] | `libunwind/1.8.3-GCCcore-15.2.0` | upstream |
| 92 | [x] | `Zip/3.0-GCCcore-15.2.0` | upstream |
| 93 | [x] | `GMP/6.3.0-GCCcore-15.2.0` | upstream |
| 94 | [x] | `Tk/9.0.3-GCCcore-15.2.0` | upstream |
| 95 | [x] | `Z3/4.15.4-GCCcore-15.2.0` | upstream |
| 96 | [x] | `nettle/4.0-GCCcore-15.2.0` | upstream |
| 97 | [x] | `LLVM/21.1.8-GCCcore-15.2.0` | upstream |
| 98 | [x] | `libclc/21.1.8-GCCcore-15.2.0` | upstream |
| 99 | [x] | `OpenGL/2026.05-GCCcore-15.2.0` | upstream |
| 100 | [x] | `FriBidi/1.0.16-GCCcore-15.2.0` | upstream |
| 101 | [x] | `GObject-Introspection/1.86.0-GCCcore-15.2.0` | upstream |
| 102 | [x] | `fonttools/4.63.0-GCCcore-15.2.0` | upstream |
| 103 | [x] | `ICU/78.3-GCCcore-15.2.0` | upstream |
| 104 | [x] | `GCC/15.2.0` | upstream |
| 105 | [x] | `HarfBuzz/14.2.0-GCCcore-15.2.0` | upstream |
| 106 | [x] | `FFTW/3.3.10-GCC-15.2.0` | upstream |
| 107 | [x] | `libevent/2.1.12-GCCcore-15.2.0` | upstream |
| 108 | [x] | `BLIS/2.0-GCC-15.2.0` | upstream |
| 109 | [x] | `numactl/2.0.19-GCCcore-15.2.0` | upstream |
| 110 | [x] | `hwloc/2.13.0-GCCcore-15.2.0` | upstream |
| 111 | [x] | `UCX/1.20.0-GCCcore-15.2.0` | upstream |
| 112 | [x] | `AOCL-BLAS/5.2-GCC-15.2.0` | upstream |
| 113 | [x] | `libfabric/2.5.0-GCCcore-15.2.0` | upstream |
| 114 | [x] | `PMIx/6.1.0-GCCcore-15.2.0` | upstream |
| 115 | [x] | `make/4.4.1-GCCcore-15.2.0` | upstream |
| 116 | [x] | `OpenBLAS/0.3.32-GCC-15.2.0` | upstream |
| 117 | [x] | `FlexiBLAS/3.5.0-GCC-15.2.0` | upstream |
| 118 | [x] | `PRRTE/4.1.0-GCCcore-15.2.0` | upstream |
| 119 | [x] | `UCC/1.7.0-GCCcore-15.2.0` | upstream |
| 120 | [x] | `OpenMPI/5.0.10-GCC-15.2.0` | upstream |
| 121 | [x] | `gompi/2026.1` | upstream |
| 122 | [x] | `FFTW.MPI/3.3.10-gompi-2026.1` | upstream |
| 123 | [x] | `ScaLAPACK/2.2.2-gompi-2026.1-fb` | upstream |
| 124 | [x] | `foss/2026.1` | upstream |

## Phase 4b -- R 4.6.1 with MPI (remaining entries)

| # | Status | Module | Source |
|---|---|---|---|
| 125 | [ ] | `R/4.6.1-foss-2026.1-MPI` | local |

## Phase 4a -- R 4.6.1 containerized (independent of the above)

No dependency on Phases 2-3. Only needs `EasyBuild/5.4.0` (Phase 0) and the already-installed `Apptainer` module.

| # | Status | Module | Source |
|---|---|---|---|
| 1 | [x] | `R/4.6.1` | upstream |

## Phase 5 -- application migration

32 of ~40 application easyconfigs ported and dry-run validated (not yet built) -- all 5 groups (A-E) complete. Grouped as in the plan; groups don't depend on each other's *builds*, only (in Group E's case) on other groups' *files* existing to reference.

**Note on validating any of these yourself:** a plain `eb --robot -D <file>.eb` on one of these in isolation will often show OTHER already-ported local files in this repo as falsely "missing" -- this repo is deliberately not on the robot path (see the "Robot-path strategy" note above), so a dependency on another local file only resolves if that file is *also* passed to the same `eb --robot -D` invocation, and even then only if either (a) it's an exact toolchain match, or (b) it carries an explicit toolchain tuple for a subtoolchain-level dependency. See the `easybuild` skill's writeup for the full pattern and worked examples. Don't trust a single-file dry-run's "missing" list at face value for these.

| Group | Files | Status |
|---|---|---|
| A -- plain GCC (15 apps) | ANTLR, BBMap, FragGeneScan, g2clib, g2lib, HDF, IDBA-UD, JasPer, kma, libarchive, libiconv, libtirpc, MaxBin, MetaBAT, Ruby, STAR, Subread, PEAR (GCCcore outlier, preserved) | 16/18 clean. **MaxBin blocked**: needs `Bowtie2`/`HMMER` ported first (neither exists anywhere at this generation). |
| B -- GCCcore direct (2 apps) | CMake, cairo | Both clean. cairo's pre-existing half-commented-dependency bug (from the Phase 1 catalogue) fixed as part of the port. |
| C -- foss apps (7 apps) | CheckM, DAS_Tool, ESMF, eggnog-mapper, FileSender, MEGAHIT, RFPlasmid | 3/7 clean (ESMF, FileSender, MEGAHIT). **4 blocked**, all on the same small set of missing prerequisites: `prodigal`, `HMMER`, `DIAMOND`, `Jellyfish`, and (eRI-local) `BLAST` -- none exist anywhere at this generation yet. DAS_Tool and RFPlasmid additionally depend on `R-4.6.1-foss-2026.1-MPI` (Phase 4b, currently paused). |
| D -- gompi apps (5 apps) | MMseqs2, NCO, ncview, netCDF-C++4, PnetCDF | 4/5 clean (MMseqs2, ncview, netCDF-C++4, PnetCDF -- though PnetCDF has a build-time risk noted in-file: upstream's next version needed an `autoreconf` fix that 1.13.0 might also need). **NCO** needed an explicit toolchain tuple fix for its `ANTLR` builddependency (see skill) -- now clean too, blocked only on genuinely-missing `GSL`/`UDUNITS`/`netCDF`/`HDF5`. |
| E -- NCL (1 app, non-compute) | NCL | Clean. Highest dependency count of any single file in this migration -- 6 explicit toolchain tuples needed for local-only subtoolchain deps (JasPer, HDF, g2lib, g2clib, cairo, libiconv), rest resolved via upstream-provided equivalents at bumped versions (HDF5→2.1.1, netCDF→4.10.0, netCDF-Fortran→4.6.3, GDAL→3.13.0, GSL→2.8, freetype/zlib/libpng/libjpeg-turbo/cURL bumped to match what's already built). Also surfaced that `HDF-4.2.16-GCC-15.2.0.eb`'s own `libtirpc` dependency needs `l/libtirpc-1.3.3-GCC-15.2.0.eb` passed alongside it in any dry-run -- note this for any other future consumer of that HDF file. |
| Out of scope | ~15 SYSTEM-toolchain files | Correctly untouched. |

**Missing prerequisites blocking several Group C/D/E files** (none exist anywhere at GCCcore-15.2.0/foss-2026.1/gompi-2026.1 yet -- upstream or locally): `prodigal`, `HMMER`, `DIAMOND`, `Jellyfish`, `BLAST` (eRI-local package), `GSL` (upstream target confirmed: `GSL-2.8-GCC-15.2.0.eb`), `UDUNITS`, `netCDF`/`netCDF-Fortran`/`HDF5`/`libaec` (upstream targets confirmed: `netCDF-4.10.0-gompi-2026.1.eb`, `netCDF-Fortran-4.6.3-gompi-2026.1.eb`). Porting these is natural follow-on work, not yet started.
