library(foreign)
library(car)
library(plyr)

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

##### Estimate Number of Apartment Buildings ####
#Bring in Data
geo<-read.csv("K:/Curation/HISD/Education/Tabular/Student/Stu_Add_EOY_1617.csv")
#Create Record Counter for Aggregation  
geo$Person<-recode(geo$id,"\" \"=0; else=1")

#Tag Unique Streets and Housenumbers - I.E. BUILDINGS
  #First Create Variable that strips 'Apt.'
  geo$new_stuadd<-gsub("[Apt.]", "", geo$Student_Address)
  geo$new_stuadd<-trim((laply(strsplit(as.character(geo$Student_Address), split = " Apt"), "[",1)))

  #Next Count Persons in Buildings  
  geo$build_id<-id(geo[c("new_stuadd")], drop=T)
  units<-sumby(geo[,c("Person","Person")], geo$new_stuadd)
  units<-rename(units, c("Person"="NumPerAdd"))
  myvars<-c("new_stuadd", "NumPerAdd")
  units<-units[myvars]

#Merge Number of Children in Address to Geocode File
  geo<-merge(x=geo, y=units, by="new_stuadd", all.x=T)
  geo$apt_indicator<-ifelse(grepl("Apt. #", geo$Student_Address), 1, 0)  #Make Sure Student Address Variable is Correct

#If any building address has a 'Apt.' then all similar addresses will get the apartment indicator
  max<-tapply(geo$apt_indicator, INDEX=list(geo$new_stuadd), FUN=max, na.rm=T)
  max2<-data.frame(new_stuadd=names(max), apt_build=max)
  geo<-merge(geo, y=max2, by="new_stuadd", all.x=T)
  
  write.csv(geo, "K:/Curation/HISD/Education/Tabular/Student/Stu_Add_EOY_1617_r.csv")
  