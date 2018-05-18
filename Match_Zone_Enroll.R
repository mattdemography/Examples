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

#Bring in Points with HCAD_NUM and Keep For Rest of Analysis
spp<-read.dbf("K:/Curation/HISD/Education/Tabular/Student/Shapefiles/Stu_Points_Parcels.dbf")

myvars<-c("maskedid", "HCAD_NUM")
spp<-spp[myvars]

library(shapefiles)
setwd("K:/Curation/HISD/Education/Tabular/Student/Shapefiles/")
stu_parcels<-readOGR(dsn=getwd(), layer="Stu_Parcels_Complete") #These are the Geocoded Parcels Used to Match School Information to.
#For now I eliminate duplicate maskedid. This exists due to the fact that there are still duplicated parcel shapes on top
#of each other in the original parcel shapefile. These all have different addresses, but are the same geography. Only
#parcels with the same address and same shape were eliminated previously. Another procedure will have to be used to find
#these parcels. Perhaps using the X, Y coordinates will work. With that said, this method did allow points to be correctly
#geocoded as some of the duplicate shapes had incomplete address information for example missing street type or direction.

stu_parcels<-subset(stu_parcels, !duplicated(stu_parcels$maskedid))

myvars<-c("HCAD_NUM")
stu_parcels<-stu_parcels[myvars]

school_type<-c("elm", "mid", "high")
i=3
for (i in 1:3){
  points<-readOGR(dsn=getwd(), layer=paste("points_", school_type[i], sep=""))

#Keep join variable and geocoded facility
  names(points)<-tolower(names(points))
  #Make changes to variable names for middle school facilities
  ifelse(exists("middle_sch", where=points@data), (points$facility=points$middle_sch), 
         (points$join_count=points$join_count))
  ifelse(exists("high_schoo", where=points@data), (points$facility=points$high_schoo), 
         (points$join_count=points$join_count))
  myvars<-(c("maskedid","school_num", "school_nam", "code", "facility", "elm", "mid", "high", "unzoned", "unknown"))
  points<-points[myvars]
  
  #Create Person Counter
  points$Person<-recode(points$maskedid,"\" \"=0; else=1")
  
  #Create variable equal to School Type
  points$Type<-school_type[i]
  points$type_char<-ifelse(points$elm==1, "elm", NA)
  points$type_char<-ifelse(is.na(points$type_char) & points$mid==1, "mid", points$type_char)
  points$type_char<-ifelse(is.na(points$type_char) & points$high==1, "high", points$type_char)
  
  #Create Indicator of Type Match
  points$typematch<-ifelse(points$Type==points$type_char, 1, 0)
    #Take care of schools that are both elementary and middle schools
  points$typematch<-ifelse((as.character(points$code)=="058" | as.character(points$code)=="127" | as.character(points$code)=="382")
                           & points$Type=="mid", 1, points$typematch)
  
  #Create indicator if Zoned School Matches Attend School
  points$zonematch<-ifelse(as.character(points$code)==as.character(points$school_num), 1, 0)
  points$zonematch<-ifelse(is.na(points$zonematch), 0, points$zonematch)
  
  #Merge spp to points file to bring in HCAD_NUM to Match to Parcels
  points<-merge(points, spp, by="maskedid")
  
  #Drop Missing (Unmatched) Cases
  points<-subset(points, !is.na(points$HCAD_NUM))
  
  #Create indicator if School Types Match
  agg<-sumby(points@data[,c("elm", "mid", "high","unzoned", "unknown", "zonematch", "typematch", "Person")], points$HCAD_NUM)
  agg$elm_agg<-agg$elm
  agg$mid_agg<-agg$mid
  agg$high_agg<-agg$high
  agg$unzone_agg<-agg$unzoned
  agg$uk_agg<-agg$unknown
  agg$zone_agg<-agg$zonematch
  agg$type_agg<-agg$typematch
  agg$tot_agg<-agg$Person
  
  myvars<-c("HCAD_NUM", "elm_agg", "mid_agg", "high_agg", "unzone_agg", "uk_agg", "zone_agg", "type_agg", "tot_agg")
  agg<-agg[myvars]
  
  points<-merge(points, agg, by="HCAD_NUM")
  
  #Create Zone Categories for parcels
    # 1= Evidence that parcel has a student who's enrolled school matches zoned school
    # 2= No student in parcel is enrolled in zone school, At least one student in parcel matches on school type
    # 3= No student in parcel is enrolled in zone school or shares same school type, At least one student in parcel in other known type
    # 4= No student in parcel is enrolled in zone school, At least one student in parcel unknown school type
    # 5= No student in parcel is enrolled in zone school, Categories 1-4 do not apply and evidence of any student as unzoned school
  points$zone_cat<-ifelse(points$zone_agg>=1, 1, 0)
  points$zone_cat<-ifelse(points$zone_cat==0 & points$type_agg>=1, 2, points$zone_cat)
  points$zone_cat<-ifelse(points$zone_cat==0 & points$uk_agg==0 & points$unzone_agg==0, 3, points$zone_cat)
  points$zone_cat<-ifelse(points$zone_cat==0 & points$uk_agg>=1, 4, points$zone_cat)
  points$zone_cat<-ifelse(points$zone_cat==0 & points$unzone_agg>=1, 5, points$zone_cat)
  
  #Now Limit to One HCAD_NUM - Fine since all data are now aggregate
  myvars<-c("maskedid","school_num", "school_nam", "code", "facility", "elm", "mid", "high", "unzoned", "unknown", "Person")
  points<-points[!names(points) %in% myvars]
  points<-subset(points, !duplicated(points$HCAD_NUM))
  
  #Merge points to parcel file for output and creating outline colors
  outshape<-merge(stu_parcels, points, by="HCAD_NUM", all.x=T)
  
  #Make Changes to Columns for Writing Out Shapefile
  outshape$elm_agg<-as.numeric(outshape$elm_agg)
  outshape$mid_agg<-as.numeric(outshape$mid_agg)
  outshape$high_agg<-as.numeric(outshape$high_agg)
  outshape$unzone_agg<-as.numeric(outshape$unzone_agg)
  outshape$uk_agg<-as.numeric(outshape$uk_agg)
  outshape$zone_agg<-as.numeric(outshape$zone_agg)
  outshape$type_agg<-as.numeric(outshape$type_agg)
  outshape$tot_agg<-as.numeric(outshape$tot_agg)
  outshape$zone_cat<-as.numeric(outshape$zone_cat)
  
#Output New Shapefiles
  library(shapefiles)
  setwd("K:/Curation/HISD/Education/Tabular/Student/Shapefiles/")
  writeOGR(outshape, dsn=getwd(), paste("Stu_Parcel_", school_type[i], sep=""), check_exists = TRUE,
           overwrite_layer = TRUE, driver="ESRI Shapefile")
  detach("package:shapefiles", unload=TRUE)
}