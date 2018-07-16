## Submission notes

### Purpose

Improvements to usability through automating the installation process.

Fixed the following in r-devel:

```
Result: WARN 
    '::' or ':::' import not declared from: ‘quanteda’ 
```

## Test environments

* local macOS 10.13.51, R 3.5.1
* ubuntu Ubuntu 16.04 LTS (on travis-ci), R 3.5.1
* Windows Server 2012 R2 x64 (build 9600), R 3.5.1 (on Appveyor)
* local Windows 10, R 3.5.1
* win-builder (devel and release)

## R CMD check results

### ERRORs or WARNINGs

None.

### NOTES

None.

## Downstream dependencies

No errors were caused in other packages, using `devtools::revdep_check()` to confirm.
