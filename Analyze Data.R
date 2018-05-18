library(foreign)
library(car)
library(plyr)
library(rgdal)

sumby<- function(x,y){
  y1<-deparse(substitute(y))
  y2<-unlist((strsplit(as.character(y1), "[$]")))[2]
  myvars<-"y"
  nrows<-length(x)
  df<-data.frame(x=numeric(), y=numeric())
  df<-rename(df, c(x=y2, y=y))
  for(i in 1:nrows){
    x2<-(colnames(x[i]))
    t<-(tapply(x[,i], INDEX=list(y), FUN=sum, na.rm=T))
    df2<-data.frame(x=names(t), y=t)
    df2<-rename(df2, c(x=y2, y=x2))
    df<-merge(df, df2, by=y2, all=T, accumulate=T)
    df<-df[!names(df) %in% myvars]
  }
  df
}

trim <- function( x ) {
  gsub("(^[[:space:]]+|[[:space:]]+$)", "", x)
}

#Bring in Parcel Data and Fix 'LocName' so that it includes street endings and takes care of unneeded spaces like in 'W  34th'
  parcelin<-read.dbf("K:/Curation/HISD/Education/Tabular/Student/Shapefiles/Parcel_Flood_Damage.dbf")
  parcelin$LocName_new<-gsub("^[0-9]* ","",parcelin$LocAddr) #Captures Street Name with Ending
  parcelin$LocName_new<-gsub("[,|?|`|\"|/]", "", parcelin$LocName_new)  #Eliminates unneeded characters
  parcelin$LocName_new<-gsub("^#[0-9A-Za-z]*", "", parcelin$LocName_new)    #Clean '#0-9 Street Name' Types
  parcelin$LocName_new<-gsub("^-[A-Za-z]*", "", parcelin$LocName_new)    #Clean '-A Street Name' Types
  parcelin$LocName_new<-gsub("  ", " ", parcelin$LocName_new)   #Cleans double space which was preventing W  34th St from geocoding
  
#Output the DBF
  myvars<-c("EVENT_DATE", "EVENT_NAME", "COMMENTS", "USNG") #Drop Variables to make file smaller
  parcelin<-parcelin[!names(parcelin) %in% myvars]

  write.dbf(parcelin, "K:/Curation/HISD/Education/Tabular/Student/Shapefiles/Parcel Flood Damage.dbf")

#Estimate how many apartments will have to be examined for floor number
  test<-subset(geo, !duplicated(geo$Match_addr))
  test<-subset(test, test$NumPerAdd>1 & test$apt_indicator_build==1)
  
#Bring in Second Geocode Results
  geo2<-read.dbf("K:/Curation/HISD/Education/Tabular/Student/Shapefiles/DBF/Stu_Parcel_Points_2.dbf")
  

  
  