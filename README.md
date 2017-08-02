# VersionControl

Overview
--------

VersionControl is a method of enabling side-by-side installation of different versions of the same R package to enable improved versioning of package use in R code with the overall motivation of improving reproducibility.  Core challenges in R now are:

-   Locking your repository to a particular checkpoint doesn't allow you to use updated packages in new code
-   Locking your repository also doesn't help with ensuring old code still works
-   Packing installed libraries to your project adds bulk to the project size
-   Packing installed libraries also requires that you potentially install the same version of the same package repeatedly to satisfy differing requirements
-   Existing methods aren't explicit about what version of a package is being used in the code itself

These issues are addressed with two functions, `vcInstall` and `vcLibrary` which explicitly state the package and the required version when installing and loading libraries. 
By creating a new set of directories near your primary library, VersionControl manages to install differing versions of the same package side-by-side which enables reuse by other scripts without needing to reinstall.
Package versions are installed by leveraging Microsoft's MRAN to ensure that the correctly versioned dependencies are also available.

Installation
------------

``` r
# Currently, the only way to install the package is via:
# install.packages("devtools")
devtools::install_github("bmewing/VersionControl")
```

If you encounter a clear bug, please file a minimal reproducible example on [github](https://github.com/bmewing/VersionControl/issues).

Usage
-----

``` r
library(VersionControl)

vcInstall('coin','1.1x')
#This will install the most recent version of the package coin with a version of at least 1.1 but not 1.2 or higher
#Available as of November 29, 2016 as version 1.1-3 at the link below
#https://mran.microsoft.com/snapshot/2016-11-29/web/packages/coin/index.html

vcInstall('coin','1.1-3')
#Identical to the version above

vcInstall('coin','1.1-3',type='windows')
#The type argument indicates we want to install the Windows binary version of the package instead of from source
#Available as of November 30, 2016 from MRAN

vcInstall('coin','1.1-2')
#This will install a second version of the package coin alongside the previously installed version.

vcLibrary('coin','1.1-3')
#This will load version 1.1-3 of coin even though the last version installed was 1.1-2

vcLibrary('coin','1.1-2')
#This will trigger a reloading of the R environment because you cannot have two different versions of a package loaded at the same time.
```
