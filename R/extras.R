defaultLibrary = function(){
  defaultLibrary = strsplit(normalizePath(.libPaths()[1],winslash = "/"),"/")[[1]]
  return(paste(c(defaultLibrary[-length(defaultLibrary)],"VersionControl"),collapse=.Platform$file.sep))
}

availableVersions = function(package){
  pd = paste(defaultLibrary(),package,sep=.Platform$file.sep)
  versions = list.dirs(pd,full.names=TRUE,recursive=FALSE)
  av = unlist(lapply(lapply(c(.libPaths(),versions),installed.packages),function(x){
    tryCatch({x['dplyr','Version']},
             error=function(x){NULL})
    }))
  return(av)
}

loadVersion = function(package,version){
  av = availableVersions(package)
  avLib = paste(defaultLibrary(),package,version,sep=.Platform$file.sep)
  if(version %in% av) return(list(Version=version))
  if(grepl("x",version,ignore.case=TRUE)){
    version = gsub("x.*","",version)
    avS = substr(av,1,nchar(version))
    if(!version %in% avS) return(list(Version="MISSING")) else return(list(Version=max(av[avS==version])))
  }
  return(list(Version="MISSING"))
}

packageArchive = function(package){
  archive = readLines(sprintf("https://cran.rstudio.com/src/contrib/Archive/%s",package))
  relLines = grep(paste0(package,"_.*?\\.tar\\.gz"),archive,value=TRUE)
  versions = gsub(paste0(package,"_"),"",gsub(paste0("^.*?(",package,"_.*?)\\.tar\\.gz.*$"),"\\1",relLines))
  dates = as.Date(gsub("^.*?([0-9]{2}\\-[A-Z][a-z]+\\-[0-9]{4}).*$","\\1",relLines),format="%d-%b-%Y")
  return(data.frame(Version=versions,Date=dates,stringsAsFactors = FALSE))
}

checkForBinary = function(package,version,date,type,flexible){
  details = readLines(sprintf("https://mran.microsoft.com/snapshot/%s/web/packages/%s/index.html",date,package))
  if(type == "windows"){
    cv = gsub(sprintf("^.*?%s_(.*?)\\.zip.*$",package),"\\1",grep(sprintf("bin/%s/contrib/[0-9]\\.[0-9]+/%s_.*?\\.zip",type,package),details,value=TRUE))
  } else {
    cv = gsub(sprintf("^.*?%s_(.*?)\\.zip.*$",package),"\\1",grep(sprintf("bin/%s/contrib/[0-9]\\.[0-9]+/%s_.*?\\.tgz",type,package),details,value=TRUE))
  }
  if(flexible) return(substr(cv,1,nchar(version)) == version) else return(cv == version)
}

installVersion = function(package,version,type,wait){
  flexible = grepl("x",version,ignore.case=TRUE)
  ap = available.packages(repos = "https://cran.rstudio.com")
  cv = ap[which(rownames(ap) == package),"Version"]
  arch = packageArchive(package)
  if(!flexible){
    if(version == cv) return(list(Date="TODAY",Version=cv))
    if(any(arch$Version == version)){
      d = arch$Date[arch$Version == version]
    } else {
      return(list(Date="NOT FOUND",Version="NOT FOUND"))
    }
  } else if(flexible){
    version = gsub("x.*","",version)
    cvS = substr(cv,1,nchar(version))
    if(cvS == version) return(list(Date="TODAY",Version=cv))
    arch$vs = substr(arch$Version,1,nchar(version))
    if(any(arch$vs == version)){
      d = rev(arch$Date[arch$vs == version])[1]
      version = rev(arch$Version[arch$vs == version])[1]
    } else {
      return(list(Date="NOT FOUND",Version="NOT FOUND"))
    }
  }
  binary = type %in% c('windows','macosx')
  od = d
  found = F
  while(!found){
    ap = available.packages(repos = sprintf("https://mran.microsoft.com/snapshot/%s",as.character(d)))
    ab = ifelse(binary,checkForBinary(package,version,as.character(d),type,flexible),TRUE)
    cv = ap[which(rownames(ap)==package),"Version"]
    found = (cv == version | ifelse(flexible,substr(cv,1,nchar(version))==version,FALSE)) & ab
    if(found) return(list(Date=d,Version=cv))
    if(d > od+wait) return(list(Date="NOT FOUND",Version="NOT FOUND"))
    d = d+1
  }
}
