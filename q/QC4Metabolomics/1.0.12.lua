help([==[

Description
===========
QC4Metabolomics is a containerized QC system for metabolomics studies
(mariadb + processing/conversion workers + a Shiny web UI), run on eRI via
Apptainer instances (see run_qc.sh in the project's app directory). This
module does not build any software - loading it just puts a launcher on
your PATH. Run it from an interactive OnDemand/desktop session (X11 display
+ browser available): it makes sure the stack is up, waits for the Shiny UI
to answer, and opens it in your browser.

Usage
=====
module load QC4Metabolomics
qc4metabolomics

More information
================
 - Homepage: https://github.com/stanstrup/QC4Metabolomics
 - Docs: http://stanstrup.github.io/QC4Metabolomics/
 - eRI deployment: /agr/persist/projects/2026_metabolomics/apps/QC4Metabolomics/README.md
]==])

prepend_path("PATH", "/agr/persist/apps/eri_rocky8/software/QC4Metabolomics/1.0.12/bin")
