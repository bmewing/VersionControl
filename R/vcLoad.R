#' Parses the package.json file associated with a project and loads required libraries.
#'
#' @param installMissing boolean, should missing libraries be installed when run?
#' @param recursive boolean, should the function look recursively for the package.json file
#' @return invisible NULL
#' @details
#' The function will attempt to parse a file called 'package.json' which is ideally in the root of the current working directory.  The structure of this file is described in the vignette.
#' Required libraries, as listed with versions in 'package.json' are loaded. Optionally, missing libraries can be installed at the time of this function running.
#' @examples
#' vcLoad(installMissing = TRUE, recursive = TRUE)
#' @export

vcLoad = function(installMissing = FALSE,recursive = FALSE,...){
  packageJSON = list.files(pattern="package.json",full.names = TRUE,ignore.case = TRUE,recursive = recursive)[1]
  if(is.na(packageJSON)) stop("No package.json found!")
  json = suppressWarnings({paste(readLines(packageJSON),collapse="")})
  json = sub(" *\\} *$","",sub("^.*?\\{ *","",json))
  jsonList = list()
  while(grepl(":",json)){
    if(grepl("^.*?[\"']([^\"']*?)[\"'] *: *\\{",json)){
      kvr = sub(".*?([\"'][^\"']*?[\"'] *: *\\{.*?\\},?).*","\\1",json)
      kv = sub(".*?[\"'](.*?)[\"'] *: *\\{(.*?)\\},?.*","\\1:\\2",json)
      k = gsub("(.*?):.*","\\1",kv)
      v = gsub(".*?:(.*)","\\1",kv)
      `[[`(jsonList,k) = list()
      while(grepl(":",v)){
        skv = sub(".*?[\"'](.*?)[\"'] *: *[\"'](.*?)[\"'],?.*","\\1:\\2",v)
        sk = gsub("(.*?):.*","\\1",skv)
        sv = gsub(".*?:(.*)","\\1",skv)
        `[[`(`[[`(jsonList,k),sk) = sv
        v = sub("[\"'](.*?)[\"'] *: *[\"'](.*?)[\"'],?","",v)
      }
      json = sub(kvr,"",json,fixed = TRUE)
    } else {
      kv = sub(".*?[\"'](.*?)[\"'] *: *[\"'](.*?)[\"'],?.*","\\1:\\2",json)
      k = gsub("(.*?):.*","\\1",kv)
      v = gsub(".*?:(.*)","\\1",kv)
      `[[`(jsonList,k) = v
      json = sub("[\"'](.*?)[\"'] *: *[\"'](.*?)[\"'],","",json)
    }
  }
  if(!is.null(jsonList$name)) cat("Loading project '",jsonList$name,"'\n",sep="")
  if(!is.null(jsonList$description)) cat("  Description:",jsonList$description,"\n")
  if(!is.null(jsonList$author)) cat("  Project Author:",jsonList$author,"\n")
  if(!is.null(jsonList$version)) cat("  Version:",jsonList$version,"\n")
  packages = unlist(jsonList$packages)
  missingPackages = c()
  for(i in seq_along(packages)){
    tv = loadVersion(names(packages)[i],packages[i])
    if(tv == "MISSING" & installMissing) vcInstall(names(packages)[i],packages[i],...) else missingPackages = c(missingPackages,names(packages)[i])
  }
  if(length(missingPackages) > 0) stop(paste0("The following packages are not available and must be installed for the code in this project to work:\n",paste(missingPackages,collapse="\n")))
  vcLibrary(names(jsonList$packages),unlist(jsonList$packages))
  return(invisible(NULL))
}
