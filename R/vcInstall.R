#' Installs a specific version of a package alongside other versions of that package
#'
#' @param package character vector of the names of packages which should be downloaded and installed.
#' @param version character vector of the required versions of packages which should be downloaded and installed.
#' @param type character, indicating the type of package to download and install. Will be "source" by default unless you request "windows" for Windows binaries or "macosx" for MacOS X binaries.
#' @param searchAhead numeric, indicating the number of days to search ahead in the MRAN when looking for a specific version and/or type.
#' @param ... arguments to to be passed to install.packages
#' @return invisible NULL
#' @details
#' The function will attempt to identify where the specific version can be found by checking the current CRAN and CRAN Archives. If the requested version is identified in the archives, it will attempt to install the package from MRAN (Microsoft's snapshot version of CRAN) to ensure dependencies are installed correctly as well.  If the requested version is the current version on CRAN, it installs it from the RStudio mirror.  This means that it does not support installing packages from other repositories (custom, Bioconductor, GitHub, etc.)
#' To support multiple versions of packages being installed side-by-side, this function creates new directories near your primary library based on package name and version.  This supports reusing the same version of a package inside multiple scripts or projects.
#' The version matching includes the use of 'x' for variable versioning.  Package versions are often of the sort major.minor.patch - if your code is resilient against patch versions of the code you could request version 1.1.x which would install the most recent version which has a major version of 1, a minor version of 1 and any patch version.  Note, 1.x.1 is not a supported form of version matching - this will be interpreted as 1.x
#' @examples
#' vcInstall(package = 'coin', version = '1.1x', type = "source")
#' # Identical to
#' vcInstall(package = 'coin', version = '1.1-3', type = "source")
#' @export

vcInstall <- function(package,version,type=c("source","windows","macosx"),searchAhead=7,...) {
  if(length(package) != length(version)) stop("Unequal number of Package Names and Version Numbers - must be one for one.")
  if(length(type) > 1) type = type[1]
  dl = defaultLibrary()
  if(!dir.exists(dl)){
    cat("This appears to be your first time doing version controlled package installation.\nCreating a new directory at the location below to store versioned installation.\n",dl,"\n")
    dir.create(dl)
  }
  for(i in seq_along(package)){
    vcpd = paste(dl,package[i],sep=.Platform$file.sep)
    if(!dir.exists(vcpd)){
      cat("This appears to be the first time the package '",package[i],"' has been installed with version control.\nCreating a new directory at the location below to store versioned installations\n ",vcpd,"\n",sep="")
      dir.create(vcpd)
    }

    mranDate = installVersion(package[i],version[i],type,searchAhead)
    if(mranDate$Version == "NOT FOUND") stop("Requested version cannot be found.")

    vcpdv = paste(vcpd,mranDate$Version,sep=.Platform$file.sep)
    if(!dir.exists(vcpdv)){
      dir.create(vcpdv)
    }

    install.packages(pkgs=package[i],repos = sprintf("https://mran.microsoft.com/snapshot/%s/",mranDate$Date),lib = vcpdv,...)
  }
  return(invisible(NULL))
}
