#Prepare Parcel Flood Damage Map - Removing Duplicate parcel shapes (i.e. parcels placed in same area but with different owners)
library(plyr)
library(foreign)

#Bring in Parcel File to mark duplicates
parcel_fresh<-read.dbf("K:/Curation/HISD/Education/Tabular/Student/Shapefiles/Parcels.dbf")
parcel_fresh$unique<-paste(parcel_fresh$Shape_STAr, parcel_fresh$Shape_STLe, sep="")
parcel_fresh$dup_unique<-ifelse(duplicated(parcel_fresh$unique), 1, 0)
parcel_fresh$dup_address<-ifelse(duplicated(parcel_fresh$LocAddr), 1, 0)
parcel_fresh$dup<-parcel_fresh$dup_unique * parcel_fresh$dup_address
write.dbf(parcel_fresh, "K:/Curation/HISD/Education/Tabular/Student/Shapefiles/Parcels.dbf")

#Bring In FEMA Damage Point File
fpoints<-read.dbf("K:/Curation/HISD/Education/Tabular/Student/Shapefiles/FEMA_Damage_Assessments_Combined.dbf")
fpoints$unique<-paste(fpoints$X, fpoints$Y, sep="")
fpoints$dup_unique<-ifelse(duplicated(fpoints$unique), 1, 0)

#If any building address has a 'Apt.' then all similar addresses will get the apartment indicator
max<-tapply(fpoints$IN_DEPTH, INDEX=list(fpoints$unique), FUN=max, na.rm=T)
max2<-data.frame(unique=names(max), max_depth=max)
fpoints<-merge(fpoints, y=max2, by="unique", all.x=T)
fpoints$keep<-ifelse(fpoints$IN_DEPTH==fpoints$max_depth, 1, 0)
fpoints$keep<-ifelse(fpoints$STATE=="LA", 0, fpoints$keep)

myvars<-c("max_depth")
fpoints<-fpoints[!(names(fpoints) %in% myvars)]
write.dbf(fpoints, "K:/Curation/HISD/Education/Tabular/Student/Shapefiles/FEMA_Damage_Assessments_Combined.dbf")
