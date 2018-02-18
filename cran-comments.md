## Submission notes

### Resubmission

Fixed the imbalanced single quotes in the title.

### Purpose

Bug fixes and improvements to usability; decreases R version dependency to an earlier version (our newer version dependency was unnecessary).

## Test environments

* local OS X install, R 3.4.3
* ubuntu Ubuntu 14.04.5 LTS (on travis-ci), R 3.4.2
* Windows Server 2012 R2 x64 (build 9600), R 3.4.2 (on Appveyor)
* local Windows 10, R 3.4.2
* win-builder (devel and release)

## R CMD check results

### ERRORs or WARNINGs

None.

### NOTES

None.

## Downstream dependencies

No errors were caused in other packages, using `devtools::revdep_check()` to confirm.

