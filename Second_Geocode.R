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

#Bring in Initial Geocode for Analysis
  int_geo<-read.dbf("K:/Curation/HISD/Education/Tabular/Student/Shapefiles/DBF/Stu_Points_1.dbf")

  #Analyze First Geocode by School
  int_geo$m<-ifelse(int_geo$Status=="M", 1, 0)
  int_geo$t<-ifelse(int_geo$Status=="T", 1, 0)
  int_geo$u<-ifelse(int_geo$Status=="U", 1, 0)
  schools<-sumby(int_geo[,c("Person","m", "t","u")], int_geo$School_Nam)
  schools$per_unmatch<-(schools$u/schools$Person)*100
  write.csv(schools, "K:/Curation/HISD/Education/Tabular/Student/Initial_Geocode_by_School.csv")
  
#Create New Address File to be Geocoded
  newgeo<-subset(int_geo, int_geo$Status=="U")
  names(newgeo)
  myvars<-c("maskedid", "School_Num", "School_Nam", "Student_Ad", "Student_Ci", "Student_Zi", 
          "build_id", "NumPerAdd", "apt_indica", "apt_build", "new_stuadd") #Make File Contain Only Necessary Variables
  newgeo<-newgeo[myvars]

#Export CSV
  write.csv(newgeo, "K:/Curation/HISD/Education/Tabular/Student/Stu_Add_EOY_1617_r2.csv")
  