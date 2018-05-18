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

##### Summary By Where Students Attend School #####
detach("package:shapefiles", unload=TRUE)

p<-read.dbf("K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/DBF/Stu_Points_Damage.dbf")
p$dmg_aff<-ifelse(p$DMG_LEVEL=="AFF", 1, 0)
p$dmg_aff<-ifelse(is.na(p$DMG_LEVEL), 0, p$dmg_aff)
p$dmg_min<-ifelse(p$DMG_LEVEL=="MIN", 1, 0)
p$dmg_min<-ifelse(is.na(p$DMG_LEVEL), 0, p$dmg_min)
p$dmg_maj<-ifelse(p$DMG_LEVEL=="MAJ", 1, 0)
p$dmg_maj<-ifelse(is.na(p$DMG_LEVEL), 0, p$dmg_maj)
p$dmg_des<-ifelse(p$DMG_LEVEL=="DES", 1, 0)
p$dmg_des<-ifelse(is.na(p$DMG_LEVEL), 0, p$dmg_des)
p$dmg_any<-ifelse(p$dmg_aff==1 | p$dmg_min==1 | p$dmg_maj==1 | p$dmg_des==1, 1, 0)

table(p$dmg_aff)
table(p$dmg_min)
table(p$dmg_maj)
table(p$dmg_des)
table(p$dmg_any)


#If Geocoded
p$geo<-ifelse(p$Status=="M" | p$Status=="T", 1, 0)

agg<-sumby(p[,c("dmg_aff", "dmg_min", "dmg_maj","dmg_des", "dmg_any", "Person")], p$School_Nam)

agg_geo<-sumby(p[,c("dmg_aff", "dmg_min", "dmg_maj","dmg_des", "dmg_any", "geo")], p$School_Nam)
attach(agg_geo)
agg_geo$per_aff<-round((dmg_aff/geo)*100,2)
agg_geo$per_min<-round((dmg_min/geo)*100,2)
agg_geo$per_maj<-round((dmg_maj/geo)*100,2)
agg_geo$per_des<-round((dmg_des/geo)*100,2)
agg_geo$per_any<-round((dmg_any/geo)*100,2)
detach(agg_geo)

t_agg<-merge(agg_geo, agg[c("Person", "School_Nam")], by="School_Nam", all.x=T)
t_agg<-t_agg[,c(1,2,3,4,5,6,8,9,10,11,12,7,13)]

t_agg<-rename(t_agg, c("dmg_aff"="Affected", "dmg_min"="Minor", "dmg_maj"="Major", "dmg_des"="Destroyed",
                        "dmg_any"="Any Damage", "per_aff"="Percent Affected", "per_min"="Percent Minor",
                        "per_maj"="Percent Major", "per_des"="Percent Destroyed", "per_any"="Percent Any Damage",
                        "geo"="Total Students Geocoded", "Person"="Total Students in School"))

write.csv(t_agg, "K:/Projects/p011_HISD_Requests/Hurricane Harvey Maps/Output/SummaryFile_Damage.csv")


###### Summary By Where Parcel (Where Students Live) #####
p<-read.dbf("K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/DBF/Stu_Points_Damage.dbf")
myvars<-c("maskedid", "DMG_LEVEL", "DMG_TYPE", "Status")
p<-p[myvars]
  p$dmg_aff<-ifelse(p$DMG_LEVEL=="AFF", 1, 0)
  p$dmg_aff<-ifelse(is.na(p$DMG_LEVEL), 0, p$dmg_aff)
  p$dmg_min<-ifelse(p$DMG_LEVEL=="MIN", 1, 0)
  p$dmg_min<-ifelse(is.na(p$DMG_LEVEL), 0, p$dmg_min)
  p$dmg_maj<-ifelse(p$DMG_LEVEL=="MAJ", 1, 0)
  p$dmg_maj<-ifelse(is.na(p$DMG_LEVEL), 0, p$dmg_maj)
  p$dmg_des<-ifelse(p$DMG_LEVEL=="DES", 1, 0)
  p$dmg_des<-ifelse(is.na(p$DMG_LEVEL), 0, p$dmg_des)
  p$dmg_any<-ifelse(p$dmg_aff==1 | p$dmg_min==1 | p$dmg_maj==1 | p$dmg_des==1, 1, 0)

#Bring in DBF of Shapefile that has catchment zones attached to student geocodes.
  points_elm<-read.dbf(paste("K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/points_elm.dbf", sep=""))
  points_mid<-read.dbf(paste("K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/points_mid.dbf", sep=""))
  points_high<-read.dbf(paste("K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/points_high.dbf", sep=""))

#Keep join variable and geocoded facility
  names(points_elm)<-tolower(names(points_elm))
  myvars<-(c("maskedid","facility"))
  points_elm<-points_elm[myvars]
  
  names(points_mid)<-tolower(names(points_mid))
  myvars<-(c("maskedid","middle_sch"))
  points_mid<-points_mid[myvars]
  
  names(points_high)<-tolower(names(points_))
  myvars<-(c("maskedid","high_schoo"))
  points_high<-points_high[myvars]
  
#Merge Data 
  points_elm<-merge(x=points_elm, y=p, by="maskedid", all.x=T)
  points_mid<-merge(x=points_mid, y=p, by="maskedid", all.x=T)
  points_high<-merge(x=points_high, y=p, by="maskedid", all.x=T)
  
  #Create Person Counter
    points_elm$Person<-recode(points_elm$maskedid,"\" \"=0; else=1")
    points_mid$Person<-recode(points_mid$maskedid,"\" \"=0; else=1")
    points_high$Person<-recode(points_high$maskedid,"\" \"=0; else=1")
    
  #If Geocoded
    points_elm$geo<-ifelse(points_elm$Status=="M" | points_elm$Status=="T", 1, 0)
    points_mid$geo<-ifelse(points_mid$Status=="M" | points_mid$Status=="T", 1, 0)
    points_high$geo<-ifelse(points_high$Status=="M" | points_high$Status=="T", 1, 0)
  
  agg_elm<-sumby(points_elm[,c("dmg_aff", "dmg_min", "dmg_maj","dmg_des", "dmg_any", "Person")], points_elm$facility)
  agg_geo_elm<-sumby(points_elm[,c("dmg_aff", "dmg_min", "dmg_maj","dmg_des", "dmg_any", "geo")], points_elm$facility)
  attach(agg_geo_elm)
  agg_geo_elm$per_aff<-round((dmg_aff/geo)*100,2)
  agg_geo_elm$per_min<-round((dmg_min/geo)*100,2)
  agg_geo_elm$per_maj<-round((dmg_maj/geo)*100,2)
  agg_geo_elm$per_des<-round((dmg_des/geo)*100,2)
  agg_geo_elm$per_any<-round((dmg_any/geo)*100,2)
  detach(agg_geo_elm)
  
  t_agg_elm<-merge(agg_geo_elm, agg_elm[c("Person", "facility")], by="facility", all.x=T)
  t_agg_elm<-t_agg_elm[,c(1,2,3,4,5,6,8,9,10,11,12,7,13)]
  t_agg_elm<-rename(t_agg_elm, c("dmg_aff"="Affected", "dmg_min"="Minor", "dmg_maj"="Major", "dmg_des"="Destroyed",
                         "dmg_any"="Any Damage", "per_aff"="Percent Affected", "per_min"="Percent Minor",
                         "per_maj"="Percent Major", "per_des"="Percent Destroyed", "per_any"="Percent Any Damage",
                         "geo"="Total Students Geocoded in Attendance Zone"))
  write.csv(t_agg_elm, "K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Output/SummaryFile_Damage_elm.csv")
  
  
  agg_mid<-sumby(points_mid[,c("dmg_aff", "dmg_min", "dmg_maj","dmg_des", "dmg_any", "Person")], points_mid$middle_sch)
  agg_geo_mid<-sumby(points_mid[,c("dmg_aff", "dmg_min", "dmg_maj","dmg_des", "dmg_any", "geo")], points_mid$middle_sch)
  attach(agg_geo_mid)
  agg_geo_mid$per_aff<-round((dmg_aff/geo)*100,2)
  agg_geo_mid$per_min<-round((dmg_min/geo)*100,2)
  agg_geo_mid$per_maj<-round((dmg_maj/geo)*100,2)
  agg_geo_mid$per_des<-round((dmg_des/geo)*100,2)
  agg_geo_mid$per_any<-round((dmg_any/geo)*100,2)
  detach(agg_geo_mid)
  
  t_agg_mid<-merge(agg_geo_mid, agg_mid[c("Person", "middle_sch")], by="middle_sch", all.x=T)
  t_agg_mid<-t_agg_mid[,c(1,2,3,4,5,6,8,9,10,11,12,7,13)]
  t_agg_mid<-rename(t_agg_mid, c("dmg_aff"="Affected", "dmg_min"="Minor", "dmg_maj"="Major", "dmg_des"="Destroyed",
                                 "dmg_any"="Any Damage", "per_aff"="Percent Affected", "per_min"="Percent Minor",
                                 "per_maj"="Percent Major", "per_des"="Percent Destroyed", "per_any"="Percent Any Damage",
                                 "geo"="Total Students Geocoded in Attendance Zone"))
  write.csv(t_agg_mid, "K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Output/SummaryFile_Damage_mid.csv")
  
  
  agg_high<-sumby(points_high[,c("dmg_aff", "dmg_min", "dmg_maj","dmg_des", "dmg_any", "Person")], points_high$high_schoo)
  agg_geo_high<-sumby(points_high[,c("dmg_aff", "dmg_min", "dmg_maj","dmg_des", "dmg_any", "geo")], points_high$high_schoo)
  attach(agg_geo_high)
  agg_geo_high$per_aff<-round((dmg_aff/geo)*100,2)
  agg_geo_high$per_min<-round((dmg_min/geo)*100,2)
  agg_geo_high$per_maj<-round((dmg_maj/geo)*100,2)
  agg_geo_high$per_des<-round((dmg_des/geo)*100,2)
  agg_geo_high$per_any<-round((dmg_any/geo)*100,2)
  detach(agg_geo_high)
  
  t_agg_high<-merge(agg_geo_high, agg_high[c("Person", "high_schoo")], by="high_schoo", all.x=T)
  t_agg_high<-t_agg_high[,c(1,2,3,4,5,6,8,9,10,11,12,7,13)]
  t_agg_high<-rename(t_agg_high, c("dmg_aff"="Affected", "dmg_min"="Minor", "dmg_maj"="Major", "dmg_des"="Destroyed",
                                 "dmg_any"="Any Damage", "per_aff"="Percent Affected", "per_min"="Percent Minor",
                                 "per_maj"="Percent Major", "per_des"="Percent Destroyed", "per_any"="Percent Any Damage",
                                 "geo"="Total Students Geocoded in Attendance Zone"))
  write.csv(t_agg_high, "K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Output/SummaryFile_Damage_high.csv")
    