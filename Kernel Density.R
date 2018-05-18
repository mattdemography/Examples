library(foreign)
library(car)
library(plyr)
library(spdep)
library(rgdal)
library(stringr)

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

library(shapefiles)
setwd("K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/")
parcel<-readOGR(dsn=getwd(), layer="Parcel_2017_R", stringsAsFactors = F)
#Keep Only Necessary Variables for parcel shapefile
myvars<-c("Parcel_ID", "LocNum", "LocName", "Loc_new")
parcel<-parcel[myvars]

new_est<-readOGR(dsn=getwd(), layer="Parcel_KD25_50", stringsAsFactors = F) 
#Aggregate Values by Parcel_ID
new_est$Count<-recode(new_est$Parcel_ID, "\" \"=0; else=1")  #Create Parcel Counter
new_est_one<-sumby(new_est@data[,c("MAX_new_es", "Count")], new_est$Parcel_ID)
new_est_one$new_est<-new_est_one$MAX_new_es/new_est_one$Count  #Create Average Estimate per parcel
myvars<-c("Parcel_ID", "new_est")
new_est_one<-new_est_one[myvars]

#Make Spatial Weight Matrix - Queen Contiguity
  #parcel_queen<-poly2nb(parcel, queen=F)
  #write.nb.gal(parcel_queen, "K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/Parcel_2017_R_Queen")
  parcel_queen<-read.gal("K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/Parcel_2017_R_Queen")

  #Create List of Neighbors
  neighs<-data.frame(matrix(parcel_queen, byrow=T))
  names(neighs)[1]<-"Full_List"  #Change column name to something usable
  neighs$Full_List<-gsub("[c|(|)]", "", neighs$Full_List, perl = T) #Remove special characters from list
  neighs$Full_List<-gsub("[:]", ", ", neighs$Full_List, perl = T) #Remove special characters from list
  neighs$region.id<-seq(1, nrow(neighs)) #Create Region.id
  neighs$Parcel_ID<-parcel$Parcel_ID #Add Parcel_ID
  neighs<-merge(neighs, new_est_one, by="Parcel_ID", all.x=T) #Add Estimate Values to Parcel_ID
  neighs$Num_neigh<-str_count(neighs$Full_List, ",") + 1 #Counts nunmber of commas then adds 1 for total neigbors
  #Save Neighbor List
  #write.csv(neighs, file = "K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/queenneighbor_list.csv")
  
  max<-max(neighs$Num_neigh) #Maximum number of neighbors = maximum number of columns
  max_replace<-length(neighs$new_est) #Number of replacements loops runs through
  Start<-0  #These numbers must not be identical in order for the loop to work
  End<-1
  cnt<-0
  ID<-neighs$Parcel_ID  #List of Parcel Ids to be used in loop
  Iteration_NewEst<-data.frame(ID)
  
  while (Start!=End){
    #Create new variables equal to maximum number of neighbors
    for (q in 1:1){
      Parcel_ID<-neighs$Parcel_ID  #List of Parcel Ids to be used in loop
      new_est_list<-neighs$new_est   #List of Choices from Kernel Density Estimation
      for (j in 1:4){
      #for (j in 1:max){
        eval(parse(text = paste0('neighs$Region.Neigh_', j, ' <- trim(sapply(strsplit(as.character(neighs$Full_List),\',\'), "[", j))')))
        eval(parse(text = paste0('neighs$NewEs.Neigh_', j, ' <-eval(parse(text = paste0(\'neighs$Region.Neigh_\', j)))')))
        eval(parse(text = paste0('neighs$Replace_', j, '<-0')))
        #Label Neighbors
        for (i in 1:3000){
        #for (i in 1:max_replace){
          eval(parse(text = paste0('neighs$Replace_', j, 
                                   '<-ifelse(Parcel_ID[i]==eval(parse(text = paste0(\'neighs$Region.Neigh_\', j))), (i), 
                                   eval(parse(text = paste0(\'neighs$Replace_\', j))))')))
          eval(parse(text = paste0('neighs$NewEs.Neigh_', j,
                                   '<-ifelse(Parcel_ID[i]==eval(parse(text = paste0(\'neighs$Region.Neigh_\', j))) & 
                                   eval(parse(text = paste0(\'neighs$Replace_\', j)))==(i), 
                                   gsub(neighs$Parcel_ID[i], new_est_list[i], eval(parse(text = paste0(\'neighs$NewEs.Neigh_\', j)))), 
                                   eval(parse(text = paste0(\'neighs$NewEs.Neigh_\', j))))')))
        }
        #Delete Variables No Longer needed *Region.Neigh & Replace
        myvars<-c(paste('Replace_', j, sep = ""), paste('Region.Neigh_', j, sep=""))
        neighs<-neighs[!names(neighs) %in% myvars]
        #Change to Numeric
        eval(parse(text = paste0('neighs$NewEs.Neigh_', j, '<-as.numeric(eval(parse(text = paste0(\'neighs$NewEs.Neigh_\', j))))')))
      }
      
      #Subset data for only Parcels with No Damage
      filled<-subset(neighs, neighs$new_est!=0)
      missing<-subset(neighs, neighs$new_est==0)
      
      #Calculate Summary Statistics of ED-Block Choices. This must be done in a loop like this in order to run
      #rowSums and discard missing values that are sure to exist
      myvars<-NULL
      for (x in 1:max){
        myvars1<-c(paste('NewEs.Neigh_', x, sep = ""))
        myvars<-cbind(myvars1,myvars)
        
      }
      
      missing$Total<-rowSums(missing[,myvars], na.rm=T)
      missing$Max<-apply(missing[,myvars], 1, max ,na.rm=T)
      missing$Min<-apply(missing[,myvars], 1, min, na.rm=T)
      missing$Means<-round(rowMeans(missing[,myvars], na.rm=T),0)
      missing$Means_Comp<-round(((missing$Total - (missing$Max+missing$Min))/(missing$Num_neigh-2)), 2)
      missing$Mode<-apply(missing[,myvars], 1, modefunc)
      
      #Start Renaming Blocks
      missing$new_est<-ifelse(missing$Means==missing$Mode & !is.na(missing$Mode), missing$Mode, missing$new_est)
      missing$new_est<-ifelse(missing$Means_Comp==missing$Mode & !is.na(missing$Mode & missing$new_est==0), missing$Mode, missing$new_est)
      #Keep Only PID and new_est
      myvars<-c("Parcel_ID", "new_est")
      missing<-missing[myvars]
      filled<-filled[myvars]
      All<-rbind(filled, missing)
      
      Start<-table(neighs$new_est!=0)
      Start<-as.numeric(Start[2])
      End<-table(All$new_est!=0)
      End<-as.numeric(End[2])
      
      #Test Iterations of new_est
      neighs$Orig<-neighs$new_est #Keep new_est in Separate Column
      
      myvars<-c("new_est")
      neighs<-neighs[!names(neighs) %in% myvars]
      neighs<-merge(x=neighs, y=All, by="Parcel_ID", all.x=T)
      
      neighs$Changed<-ifelse(neighs$new_est==neighs$Orig, 0, 1)
      myvars<-c("Parcel_ID", "new_est", "Changed")
      FE<-neighs[myvars]
      Iteration_new_est<-merge(x=Iteration_new_est, y=FE, by="Parcel_ID", all.x=T)
      
      cnt=cnt+1
      print(paste("Interation ", cnt))
      print(paste("Number of Blocks Labeled ", End))
    }
  }
  
  