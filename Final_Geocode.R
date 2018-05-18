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

#Change Fields in Student Points Complete that were previously blank. This is caused by students Geocoded in Different Waves
  #Bring in Student Point Shapefile
  library(shapefiles)
  setwd("K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/")
  points<-readOGR(dsn=getwd(), layer="Stu_Points_Complete_temp")
  #Must detach package after this line because package shapefiles affects how read.dbf works
  detach("package:shapefiles", unload=TRUE)
  
  #Mark Duplicates to be dropped. Duplicates Occur from Numerous Geocodes
  points$drop<-ifelse((points$Person==0 & points$Status=="U"), 1, 0) #Person = 0 because this was not recalculated
  points<-subset(points, points$drop==0)
  
  #Recreate Person Counter
  points$Person<-recode(points$drop,"\" \"=0; else=1")
  
  #If any maskedid is a duplicate then tag it
  dup<-tapply(points$Person, INDEX=list(points$maskedid), FUN=sum, na.rm=T)
  dup2<-data.frame(maskedid=names(dup), dup=dup)
  points<-merge(points, y=dup2, by="maskedid", all.x=T)
  
  #Mark Duplicates to be dropped if they have '2' in dup and = 'U' in Status
  points$drop<-ifelse((points$dup==2 & points$Status=='U'), 1, 0)
  points<-subset(points, points$drop==0)
  
  #Change to numeric as they are factors
  points$Student_Zi<-as.character(points$Student_Zi)
  points$Student_Zi<-as.numeric(points$Student_Zi)
  points$Student__3<-as.character(points$Student__3)
  points$Student__3<-as.numeric(points$Student__3)
  points$School_Num<-as.character(points$School_Num)
  points$School_Num<-as.numeric(points$School_Num)
  points$School_N_1<-as.character(points$School_N_1)
  points$School_N_1<-as.numeric(points$School_N_1)
  
  points$Student_Ad<-ifelse(is.na(as.character(points$Student_Ad)), as.character(points$Student__1), as.character(points$Student_Ad))
  points$Student_Ci<-ifelse(is.na(as.character(points$Student_Ci)), as.character(points$Student__2), as.character(points$Student_Ci))
  points$Student_Zi<-ifelse(points$Student_Zi==0, points$Student__3, points$Student_Zi)
  points$School_Nam<-ifelse(is.na(as.character(points$School_Nam)), as.character(points$School_N_2), as.character(points$School_Nam))
  points$School_Num<-ifelse(points$School_Num==0, points$School_N_1, points$School_Num)
  points$Temp_Num<-as.numeric(points$School_Num)
  points$School_Num<-as.character(points$School_Num)
  points$School_Num<-ifelse(points$Temp_Num<=9, paste("00", trim(as.character(points$School_Num)), sep=""),
                            as.character(points$School_Num))
  points$School_Num<-ifelse(points$Temp_Num>9 & points$Temp_Num<=99, paste("0", trim(as.character(points$School_Num)), sep=""),
                            as.character(points$School_Num))
  
  #Mark Elementary, Middle, and High Schools
  #Bring in Shapefiles to create matching lists
  elm<-read.dbf("K:/Library/HISD/Education/Spatial/HISD_Boundaries/Attendance_Boundaries/1617/attend_elem_1617.dbf")
  mid<-read.dbf("K:/Library/HISD/Education/Spatial/HISD_Boundaries/Attendance_Boundaries/1617/attend_middle_1617.dbf")
  high<-read.dbf("K:/Library/HISD/Education/Spatial/HISD_Boundaries/Attendance_Boundaries/1617/attend_high_1617.dbf")
  
  points$elm<-ifelse(points$School_Num %in% elm$Code, 1, 0)
  points$mid<-ifelse(points$School_Num %in% mid$code, 1, 0)
  points$high<-ifelse(points$School_Num %in% high$code, 1, 0)
  points$unzoned<-ifelse(points$elm==0 & points$mid==0 & points$high==0, 1, 0)
  
  #Update School Type through key word searches
  points$elm<-ifelse(grepl("Elementary", points$School_Nam), 1, points$elm)
  points$elm<-ifelse(grepl("ECC", points$School_Nam), 1, points$elm)
  points$mid<-ifelse(grepl("Middle School", points$School_Nam), 1, points$mid)
  points$mid<-ifelse(grepl("Middle School", points$School_Nam), 1, points$mid)
  points$high<-ifelse(grepl("High School", points$School_Nam), 1, points$high)
  points$high<-ifelse(grepl("HS", points$School_Nam), 1, points$high)
  
  #Mark Schools Where Grade Level is Still Unknown After Update
  points$unknown<-ifelse(points$elm==0 & points$mid==0 & points$high==0, 1, 0)
  
  #Get Rid of Unneccessary Variables in Shapefile (Reducing Size)  
  myvars<-(c("Field1", "School_N_1", "School_N_2", "Student__1", "Student__2", "Student__3", "apt_indi_1",
             "User_fld", "Temp_Num", "drop", "dup"))
  points<-points[!(names(points) %in% myvars)]
  
  #Output New Shapefiles
  library(shapefiles)
  setwd("K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/")
  writeOGR(points, dsn=getwd(), paste("Stu_Points_Complete", sep=""), check_exists = TRUE,
           overwrite_layer = TRUE, driver="ESRI Shapefile")
  detach("package:shapefiles", unload=TRUE)
  
  #Bring in Final Geocode for Analysis
  int_geo<-read.dbf("K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/Stu_Points_Complete.dbf")

  #Analyze Final Geocode by School
  int_geo$m<-ifelse(int_geo$Status=="M", 1, 0)
  int_geo$t<-ifelse(int_geo$Status=="T", 1, 0)
  int_geo$u<-ifelse(int_geo$Status=="U", 1, 0)
  schools<-sumby(int_geo[,c("Person","m", "t","u")], int_geo$School_Nam)
  schools$per_unmatch<-(schools$u/schools$Person)*100
  write.csv(schools, "K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Final_Geocode_by_School.csv")
  