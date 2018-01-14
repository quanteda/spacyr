## Submission notes

### Resubmission

We submitted a version that failed on Solaris (the only environment for which we ahd no testing platform) because Python was unavailable on that system.  We wish to retain the 1.0 version if possible.

### Purpose

Improvements to usability and robustness.

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

We saw one warning in the **preText** package, because of an incorrect call to a **quanteda** function.  I notified the package maintainer of this in early December.


