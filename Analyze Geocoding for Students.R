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

#Bring in Initial Geocode for Analysis
fin_geo<-read.dbf("K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/Stu_Points_Complete.dbf")

#Analyze First Geocode by School
fin_geo$m<-ifelse(fin_geo$Status=="M", 1, 0)
fin_geo$t<-ifelse(fin_geo$Status=="T", 1, 0)
fin_geo$u<-ifelse(fin_geo$Status=="U", 1, 0)
schools<-sumby(fin_geo[,c("Person","m", "t","u")], fin_geo$School_Nam)
schools$per_unmatch<-(schools$u/schools$Person)*100

unmatch<-subset(fin_geo, fin_geo$Status=="U")
unmatch$Student_Ad<-as.character(unmatch$Student_Ad)
unmatch$new_stuadd<-as.character(unmatch$new_stuadd)

um<-sumby(unmatch[,c("Person", "unzoned")], unmatch$Student_Ad)
um<-rename(um, c("Person"="Num_Persons_Student_Ad", "unzoned"="Num_Unzoned_Student_Ad"))
umclean<-sumby(unmatch[,c("Person", "unzoned")], unmatch$new_stuadd)
umclean<-rename(umclean, c("Person"="Num_Persons_new_studadd","unzoned"="Num_Unzoned_new_stuadd"))

#Merge Results from Student_Ad and new_stuadd
#Create Cross Walk for New_stuadd and Student_Ad
myvars<-c("Student_Ad", "new_stuadd","Student_Ci", "Student_Zi", "build_id")
cw<-unmatch[myvars]
cw<-merge(cw, um, by="Student_Ad", all.x=T)
cw<-merge(cw, umclean, by="new_stuadd", all.x=T)
cw$Street_Num_Edit<-""
cw$Street_Name_Edit<-""
cw$Clean_Code<-""

myvars<-c("Num_Unzoned_Student_Ad", "Num_Unzoned_new_stuadd")
cw<-cw[!names(cw) %in% myvars]
cw<-subset(cw, cw$new_stuadd!="NULL")
cw_c<-cw[1:16290,]
cw_j<-cw[16291:32580,]

write.csv(cw_c, "K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Cleaning/StudentData_c.csv")
write.csv(cw_c, "K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Cleaning/StudentData_j.csv")

#Check Parcel for Missing Streets
p<-read.dbf("K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/Parcel_2017_R.dbf")
myvars<-c("LocAddr", "city", "zip", "LocNum", "LocName", "Parcel_ID")
p<-p[myvars]
p<-subset(p, !is.na(p$LocAddr))

p$add_id<-id(p[c("LocAddr", "city", "zip")], drop=T)
p<-subset(p, !duplicated(p$add_id))
write.csv(p, "K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Cleaning/ParcelData.csv")
