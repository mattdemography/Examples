library(tigris)
library(spdep)
library(rgdal)
library(rgeos)
library(maptools)
library(stringr)
library(spatstat)
library(raster)
library(dplyr)
library(tmap)

#Function
LongLatToUTM<-function(x,y,zone){
  xy <- data.frame(ID = 1:length(x), X = x, Y = y)
  coordinates(xy) <- c("X", "Y")
  proj4string(xy) <- CRS("+proj=longlat +datum=WGS84")  ## for example
  res <- spTransform(xy, CRS(paste("+proj=utm +zone=",zone," ellps=WGS84",sep='')))
  return(as.data.frame(res))
}

shp <- readOGR("C:/Users/Matthew/Google Drive/Maps/Hurricane Harvey/FEMA Flood Maps", "FEMA_Damage_Assessments_Combined_R")
proj4string(shp)
#transform coordinates from lat/lon to UTM
#Harris County is UTM=15
shp2<-spTransform(shp, CRS("+proj=utm +zone=15 ellps=WGS84"))
proj4string(shp2)


writeOGR(shp2, "C:/Users/Matthew/Google Drive/Maps/Hurricane Harvey/FEMA Flood Maps","FEMA_DAC_R_Project", "ESRI Shapefile")
writeOGR(pixels,"/Users/benjaminbellman/Google Drive/Computer Backup/Projects/Police Deaths/Maps","pixel","ESRI Shapefile",overwrite_layer = T)



#create point pattern object from polygons
cents <- as.ppp(gCentroid(city, byid = T))
marks(cents) <- city@data

#estimate kernel density surface
#note: specify sigma and eps in the units of your coordinates (meters for UTM, decimal degrees for lat/lon, etc.)
dens <- density(cents, weights = city$bprop, sigma=2500, eps=500, kernel="quartic")
plot(dens)