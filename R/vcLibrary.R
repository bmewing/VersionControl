#' Loads a specific version of a package
#'
#' @param package character vector of the names of packages which should be loaded.
#' @param version character vector of the required versions of packages to be loaded.
#' @param unloadFirst binary if a version of the library is already loaded, should it be unloaded first?
#' @param ... arguments to to be passed to library
#' @return invisible NULL
#' @details
#' The function will attempt to load the specific version(s) of the requested package(s) into your namespace.
#' To support multiple versions of packages being installed side-by-side, new directories were created near your primary library based on package name and version during installation.  This supports reusing the same version of a package inside multiple scripts or projects.  The function uses the knowledge of how this was performed to use the correct library to ensure relevant dependencies are also installed.
#' The version matching includes the use of 'x' for variable versioning.  Package versions are often of the sort major.minor.patch - if your code is resilient against patch versions of the code you could request version 1.1.x which would install the most recent version which has a major version of 1, a minor version of 1 and any patch version.  Note, 1.x.1 is not a supported form of version matching - this will be interpreted as 1.x
#' @examples
#' vcLibrary(package = 'coin', version = '1.1x')
#' # Identical result as
#' vcLibrary(package = 'coin', version = '1.1-3')
#' @export

vcLibrary = function(package,version,unloadFirst=FALSE,...){
  if(length(package) != length(version)) stop("Unequal number of Package Names and Version Numbers - must be one for one.")
  dl = defaultLibrary()
  if(!dir.exists(dl)) stop(paste("Version Control does not seem to be initialized on your system.\nExpected to find a directory at the location below but did not.\n",dl))
  for(i in seq_along(package)){
    toLoad = loadVersion(package[i],version[i])
    
    if(toLoad$Version == "MISSING") stop(sprintf("'%s' is not available in version %s - try using vcInstall('%s','%s') to make it available.",package,version,package,version))
    
    if(unloadFirst){
      try({detach(paste0("package:",package),unload=TRUE,character.only=TRUE)},silent=TRUE)
    }
    vcpd = paste(dl,package[i],sep=.Platform$file.sep)
    vcpdv = paste(vcpd,toLoad$Version,sep=.Platform$file.sep)
    if(!dir.exists(vcpd)){
      cat("Attaching version ",toLoad$Version," of '",package[i],"' to the namespace (not installed with VersionControl)",sep="")
      library(package=package[i],character.only=TRUE)
    } else if(!dir.exists(vcpdv)){
      cat("Attaching version ",toLoad$Version," of '",package[i],"' to the namespace (not installed with VersionControl)",sep="")
      library(package=package[i],character.only=TRUE)
    } else {
      cat("Attaching version ",toLoad$Version," of '",package[i],"' to the namespace",sep="")
      tryCatch({
        library(package=package[i],lib.loc=vcpdv,character.only=TRUE)
      }, error=function(x){library(package=package[i],character.only=TRUE)})
    }
  }
  return(invisible(NULL))
}
