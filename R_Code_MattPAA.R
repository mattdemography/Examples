library(jsonlite)
library(car)
library(plyr)
library(stringr)
library(Hmisc)
trim <- function( x ) {
  gsub("(^[[:space:]]+|[[:space:]]+$)", "", x)
}

wd<-"K:/Projects/FY2018-205_Twitter"
Day<-c("08_25", "08_26", "08_27", "08_28", "08_29", "08_30", "08_31", "09_01", "09_02", 
       "09_03", "09_04", "09_05", "09_06", "09_07", "09_08")
Time_h<-c("00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16",
          "17", "18", "19", "20", "21", "22", "23")
Time_m<-c("00", "10", "20", "30", "40", "50")
twitter_main<-twitter[0,(c(1:4))]
myvars<-c("created_at", "id", "text", "source" )

#### Pull Tweets from Zip Files ####
for(i in 1:15){
  for(j in 1:24){
    for(k in 1:6){
      twitter <- stream_in(gzfile(paste0(wd, '/Data/downloads/20170825-20170909_nd0gsjzpk4_2017_', Day[i],'_', Time_h[j],
                              '_', Time_m[k], '_activities.json.gz')))
      twitter <- flatten(twitter)
      twitter<-twitter[myvars]
      twitter_main<-rbind(twitter_main, twitter)
    }
    twitter_main
  }
  write.csv(twitter_main, paste0(wd, "/Data/Matt/", "tweets_", Day[i], "_Matt.csv"))
  twitter_main<-twitter[0,(c(1:4))]
}
rm(twitter, twitter_main)

#### Begin Filtering Tweets for Addresses ####

for(j in 1:length(Day)){
  tweets<-read.csv(paste0(wd, "/Data/Matt/tweets_", Day[j], "_Matt.csv"), stringsAsFactors = F)
  myvars<-names(tweets) %in% c("X", "source")
  tweets<-tweets[!myvars]

  #Clean Text
  tweets$rt<-ifelse(grepl("RT", tweets$text), 1, 0) #Mark Retweets
  tweets$text_new<-gsub("RT ", " ", tweets$text) #Remove 'RT'
  tweets$text_new<-gsub("\\n", " ", tweets$text_new)  #Makes String Exclude line markers
  tweets$text_new<-paste(' ', tweets$text_new, sep = "") #Add Space in Beginning to find  address numbers at start of string
  tweets$text_new<-paste(tweets$text_new, ' ', sep = "") #Add Space in End to find  address numbers at start of string
  tweets$text_new<-gsub("http([A-z0-9:/.]*)", "", tweets$text_new)   #Remove HTTPS
  tweets$text_new<-gsub("#([A-z0-9.]* )", " ", tweets$text_new)   #Remove Any Words Attached to '#'
  tweets$text_new<-gsub("@([A-z0-9]*: )", " ", tweets$text_new)   #Remove Any Words Attached to '@'
  tweets$text_new<-gsub("@([A-z0-9]* )", " ", tweets$text_new)   #Remove Any Words Attached to '@'
  tweets$text_new<-gsub("<([A-z0-9+]*>)", " ", tweets$text_new)   #Remove Any Words Between '<>'
  tweets$text_new<-gsub("[0-9][0-9][0-9][-][0-9][0-9][0-9][-][0-9][0-9][0-9][0-9]", " ",tweets$text_new) #Delete Phone Numbers
  tweets$text_new<-gsub("[<|>|.|+|?|!|,]", " ", tweets$text_new)  #Eliminate Special Characters
  
  #Count Duplicate Tweets
  tweets$counter<-recode(tweets$id, "\" \"=0; else=1")
  tweets$dup_tweet<-ifelse(duplicated(tweets$text_new), 1, 0)
  #Drop Duplicate Tweets
  tweets<-subset(tweets, tweets$dup_tweet==0)
  
  #Mark Tweets with Numbers
  tweets$numerical<-ifelse(grepl("[0-9]", tweets$text_new), 1, 0)
  table(tweets$numerical)
  
  tweets<-subset(tweets, tweets$numerical==1) #Keep Only Tweets that Fit Criteria Above
  rownames(tweets)<-1:nrow(tweets)  #Recount rows to see indiviual tweets using code below
  
  #Create Address Field
  tweets$pos<-regexpr(" [0-9]", tweets$text_new)
  tweets$text_add1<-str_sub(tweets$text_new, tweets$pos)
  tweets$text_add1<-ifelse(tweets$pos<=0, "", tweets$text_add1)

  #Keep Only Fields with Potential Addresses
  add<-subset(tweets, tweets$text_add1!="")
  add<-subset(add, !duplicated(add$text_add1))  #Remove Duplicate Address Lines
  rownames(add)<-1:nrow(add)  #Recount rows to see indiviual tweets using code below
  
  #Mark Evidence of Street Endings
  add$st_type<-ifelse(grepl("[Ff][Mm] [0-9]", add$text_new), "FM", ifelse(grepl("( [Dd][Rr] )|([Dd][Rr][Ii][Vv][Ee])", add$text_new), "Dr", 
                ifelse(grepl("( [Ll][Nn])|( [Ll][Aa][Nn])", add$text_new), "Ln", 
                ifelse(grepl("( [Rr][Dd])|( [Rr][Oo][Aa][Dd])", add$text_new), "Rd",
                ifelse(grepl("( [Cc][Ii][Rr])|([Cc][Rr] )", add$text_new), "Cir", 
                ifelse(grepl(" [Bb][Ll][Vv][Dd]", add$text_new), "Blvd",
                ifelse(grepl("( [Cc][Oo][Uu][Rr][Tt])|( [Cc][Tt])", add$text_new), "Court",
                ifelse(grepl(" [Tt][Ee][Rr][Rr][EeAa][Cc][Ee]", add$text_new), "Terrace",
                ifelse(grepl("( [Aa][Ll][Ll][Ee][Yy])|( [Aa][Ll][Yy])|( [Aa][Ll][Ll][Yy])", add$text_new), "Aly",
                ifelse(grepl("( [Ss][Qq][Uu][Aa][Rr])|( [Ss][Qq])", add$text_new), "Sq",
                ifelse(grepl("( [Pp][Ll][Aa][Zz][Aa])", add$text_new), "Plaza",
                ifelse(grepl("( [Hh][Ii][Gg][Hh][Ww][Aa][Yy])|( [Hh][Ww][Yy])", add$text_new), "Hwy",
                ifelse(grepl("( [Ss][Tt] )|( [Ss][Tt][.])|( [Ss][Tt][Rr])", add$text_new), "St", "")))))))))))))

  #Mark Evidence of City Name
  #add$City<-str_extract(add$text_new, pattern="(.[A-z,]*( [Tt][Xx])|( [Tt][Ee][Xx][Aa][Ss]))")
  #add$City<-gsub("([Tt][Xx])|([Tt][Ee][Xx][Aa][Ss]|[,])", "", add$City)
  #citylist<-toupper(add$City)
  #citylist<-subset(citylist, !duplicated(citylist))
  #Create City List to Capture City Names by looking at Citynames in File
  citylist<-c("houston", "beaumont", "dickerson", "bellaire", "spring", "rockport", "dickinson", "dickenson", "katy", 
              "alegro", "pasadena", "freeport", "richmond", "hou", "crosby", "hankamer", "shepard", "humble",
              "cypress", "alvord", "sugarland", "sugar land", "grange", "hankemer", "crosby")
  add$text_add1<-tolower(add$text_add1)
  add$City<-NA
  for(i in 1:length(citylist)){
    add$City<-ifelse(is.na(add$City), 
                  str_extract(add$text_add1, pattern = eval(parse(text=paste0('" ', citylist[i], ' "')))), add$City)
  }
  add$City<-gsub(" ", "", add$City)
  add$City<-ifelse(add$City=="hou", "houston", ifelse(add$City=="sugar land", "sugarland", 
                  ifelse(add$City=="dickerson", "dickinson", ifelse(add$City=="dickenson", "dickinson", add$City))))
  add$City<-capitalize(add$City)
  add$City<-ifelse(grepl("[Cc]ypress [Cc]reek", add$text_add1), "Houston", ifelse(grepl("[Cc]ypress [Ss]tation", add$text_add1), "Houston",
                   add$City))
  
  #Create State
  add$State<-str_extract(add$text_new, pattern ="([Tt][Xx])|([Tt][Ee][Xx][Aa][Ss])|([Hh][Tt][Xx])")
  add$State<-toupper(add$State)
  add$State<-ifelse(add$State=="TEXAS"|add$State=="TX"|add$State=="HTX", "TX", "")
  
  #Mark Evidence of Zip Code
  add$Zip<-str_extract(add$text_new, pattern =" [7][0-9][0-9][0-9][0-9]")
  
  #Grab From Street Ending to Start of Street #
  add$text_add2<-add$text_new
  add$text_add2<-gsub("[Ff][Mm] [0-9]", " FM ", add$text_add2)
  add$text_add2<-gsub("( [Dd][Rr] )|([Dd][Rr][Ii][Vv][Ee] )", " DR ", add$text_add2)
  add$text_add2<-gsub("( [Ll][Nn])|( [Ll][Aa][Nn])", " LN ", add$text_add2)
  add$text_add2<-gsub("( [Rr][Dd])|( [Rr][Oo][Aa][Dd])", " RD ", add$text_add2)
  add$text_add2<-gsub("( [Cc][Ii][Rr])|([Cc][Rr] )", " CIR ", add$text_add2)
  add$text_add2<-gsub(" [Bb][Ll][Vv][Dd]", " BLVD " , add$text_add2)
  add$text_add2<-gsub("( [Cc][Oo][Uu][Rr][Tt])|( [Cc][Tt])", " COURT " , add$text_add2)
  add$text_add2<-gsub(" [Tt][Ee][Rr][Rr][EeAa][Cc][Ee]", " TERRACE " , add$text_add2)
  add$text_add2<-gsub("( [Aa][Ll][Ll][Ee][Yy])|( [Aa][Ll][Yy])|( [Aa][Ll][Ll][Yy])", " ALY " , add$text_add2)
  add$text_add2<-gsub("( [Ss][Qq][Uu][Aa][Rr])|( [Ss][Qq])", " SQ " , add$text_add2)
  add$text_add2<-gsub("( [Pp][Ll][Aa][Zz][Aa])", " PLAZA " , add$text_add2)
  add$text_add2<-gsub("( [Hh][Ii][Gg][Hh][Ww][Aa][Yy])|( [Hh][Ww][Yy])", " HWY " , add$text_add2)
  add$text_add2<-gsub("( [Ss][Tt] )|( [Ss][Tt][.])|( [Ss][Tt][Rr][Ee])", " ST ", add$text_add2)
  add$text_add2<-gsub("([Tt][Xx])|([Tt][Ee][Xx][Aa][Ss])|([Hh][Tt][Xx])", " TX ", add$text_add2)
  
  add$text_add3<-add$text_add2
  add$text_add3<-gsub("-", " ", add$text_add3)
  add$text_add3<-tolower(add$text_add3)

  #First Grab Numbered Streets, then Everything Before a Zip Code, then Everything Before a Street Type, then city 
    #Clean In Between Steps
  #### Grab Numbered Streets ####
  add$Street<-NA
  add$Street<-str_extract(add$text_add2, pattern="([0-9] +[0-9]+[Tt][Hh])")  #th
  add$Street<-ifelse(is.na(add$Street), 
                     str_extract(add$text_add2, pattern="([0-9] +[0-9]+[Rr][Dd])"), add$Street)  #rd
  add$Street<-ifelse(is.na(add$Street), 
                     str_extract(add$text_add2, pattern="([0-9] +[0-9]+[Ss][Tt])"), add$Street)  #st
  add$Street<-ifelse(is.na(add$Street), 
                     str_extract(add$text_add2, pattern="([0-9] +[0-9]+[Nn][Dd])"), add$Street)  #nd
  #Remove Numbers before a Space
  add$Street<-gsub("[0-9] ", "", add$Street)
  
  #### Grab Everything Before Zip Code ####
  add$Street<-ifelse(is.na(add$Street), str_extract(add$text_add2, pattern="(.[A-z ]*( [7][0-9][0-9][0-9][0-9]))"), add$Street)
  add$Street<-toupper(add$Street)
  add$Street<-ifelse(grepl("([0-9]+[Tt][Hh])|([0-9]+[Rr][Dd])|([0-9]+[Ss][Tt])", add$Street), add$Street, 
                     gsub("([0-9])", "", add$Street)) #Remove Numbers
  add$Street<-gsub(" TX ", "", add$Street) #Remove State
  #Remove City Names
  citylist<-toupper(citylist)
  for(i in 1:length(citylist)){
    add$Street<-gsub(eval(parse(text=paste0('" ', citylist[i], ' "'))), " ", add$Street)
  }
  #Remove Street Types
  typelist<-subset(add$st_type, !duplicated(add$st_type))
  typelist<-unique(typelist[typelist != c("","FM")])
  typelist<-sort(typelist)
  typelist<-toupper(typelist)
  for(i in 1:length(typelist)){
    add$Street<-gsub(eval(parse(text=paste0('" ', typelist[i], '"'))), " ", add$Street)
  }
  #Remove Long Strings
  add$Street<-ifelse((sapply(gregexpr("[[:alpha:]]+", add$Street), function(x) sum(x > 0)))>4, NA, add$Street)
  #Remove Special Characters
  add$Street<-gsub("[<|>|.|+|?|!|,|:|)|(|'|-|\"|;|#]", "", add$Street)  #Eliminate Special Characters
  #Remove Words like 'TO' and 'IN'
  add$Street<-gsub("( TO )|( IN )", "", add$Street)
  #Trim Of White Space and Make Empty Cells = NA
  add$Street<-trim(add$Street)
  add$Street<-ifelse(add$Street=="", NA, add$Street)
  #Add Space in Beginning and End to find  address numbers at start of string
  add$Street<-ifelse(!is.na(add$Street), paste(' ', add$Street, sep = ""), add$Street)
  add$Street<-ifelse(!is.na(add$Street), paste(add$Street, ' ', sep = ""), add$Street)
  
  #### Grab Everything Before St Type ####
  for(i in 1:length(typelist)){
    add$Street<-ifelse(is.na(add$Street),
                       str_extract(add$text_add2, pattern=eval(parse(text=paste0('"(.[A-z ]*( ', typelist[i], ' ))"')))), add$Street)
  }
  #Remove City Names
  citylist<-toupper(citylist)
  for(i in 1:length(citylist)){
    add$Street<-gsub(eval(parse(text=paste0('" ', citylist[i], ' "'))), " ", add$Street)
  }
  #Remove Numbers
  add$Street<-ifelse(grepl("([0-9]+[Tt][Hh])|([0-9]+[Rr][Dd])|([0-9]+[Ss][Tt])", add$Street), add$Street, 
                     gsub("([0-9])", "", add$Street)) #Remove Numbers
  #Remove Street Types
  for(i in 1:length(typelist)){
    add$Street<-gsub(eval(parse(text=paste0('" ', typelist[i], '"'))), " ", add$Street)
  }
  #Remove Long Strings
  add$Street<-ifelse((sapply(gregexpr("[[:alpha:]]+", add$Street), function(x) sum(x > 0)))>4, NA, add$Street)
  #Remove Special Characters
  add$Street<-gsub("[<|>|.|+|?|!|,|:|)|(|'|-|\"|;|#]", "", add$Street)  #Eliminate Special Characters
  #Trim Of White Space and Make Empty Cells = NA
  add$Street<-trim(add$Street)
  add$Street<-ifelse(add$Street=="", NA, add$Street)
  #Capitalize
  add$Street<-toupper(add$Street)
  #Add Space in Beginning and End to find  address numbers at start of string
  add$Street<-ifelse(!is.na(add$Street), paste(' ', add$Street, sep = ""), add$Street)
  add$Street<-ifelse(!is.na(add$Street), paste(add$Street, ' ', sep = ""), add$Street)
  
  #### Grab Everything Before City Name ####
  for(i in 1:length(citylist)){
    add$Street<-ifelse(is.na(add$Street),
            str_extract(add$text_add2, pattern=eval(parse(text=paste0('"(.[A-z ]*( ', citylist[i], ' ))"')))), add$Street)
  }
  #Remove City Names
  citylist<-toupper(citylist)
  for(i in 1:length(citylist)){
    add$Street<-gsub(eval(parse(text=paste0('" ', citylist[i], ' "'))), " ", add$Street)
  }
  #Remove Numbers
  add$Street<-ifelse(grepl("([0-9]+[Tt][Hh])|([0-9]+[Rr][Dd])|([0-9]+[Ss][Tt])", add$Street), add$Street, 
                     gsub("([0-9])", "", add$Street)) #Remove Numbers
  #Remove Street Types
  for(i in 1:length(typelist)){
    add$Street<-gsub(eval(parse(text=paste0('" ', typelist[i], '"'))), " ", add$Street)
  }
  #Remove Long Strings
  add$Street<-ifelse((sapply(gregexpr("[[:alpha:]]+", add$Street), function(x) sum(x > 0)))>4, NA, add$Street)
  #Remove Special Characters
  add$Street<-gsub("[<|>|.|+|?|!|,|:|)|(|'|-|\"|;|#]", "", add$Street)  #Eliminate Special Characters
  #Capitalize
  add$Street<-toupper(add$Street)
  
  #Work With Farm Roads
  add$Street<-ifelse(add$st_type=="FM", 
              str_extract(add$text_add2, pattern=("( [F][M]).[0-9]*")), add$Street)
  #Trim Of White Space and Make Empty Cells = NA
  add$Street<-trim(add$Street)
  add$Street<-ifelse(add$Street=="", NA, add$Street)
  
  #Remove Rescue From Streets
  add$Street<-ifelse(grepl("[Rr][Ee][Ss][Cc][Uu][Ee]", add$Street), NA, add$Street)

  #### Create List of Street Names ####
  streetslist<-add$Street
  streetslist<-subset(streetslist, !duplicated(streetslist))
  streetslist<-gsub("-", "", streetslist)
  streetslist<-trim(streetslist)
  streetslist<-tolower(streetslist)
  streetslist<-unique(streetslist)
  remove<-c("e", "w", "s", "n", "-", "", "rand", "re", NA)
  streetslist<-streetslist[!streetslist %in% remove]
  streetslist<-sort(streetslist)
  
  #Use List to Make Final Check at Street Names in Text
  for(i in 1:length(streetslist)){
    add$Street<-ifelse(is.na(add$Street),
        str_extract(add$text_add4, pattern=eval(parse(text=paste0('"(( .[0-9])*( ', streetslist[i], '))"')))), add$Street)
  }
  #Remove City Names
  citylist<-toupper(citylist)
  for(i in 1:length(citylist)){
    add$Street<-gsub(eval(parse(text=paste0('" ', citylist[i], ' "'))), " ", add$Street)
  }
  #Remove Numbers
  add$Street<-ifelse(grepl("([0-9]+[Tt][Hh])|([0-9]+[Rr][Dd])|([0-9]+[Ss][Tt])", add$Street), add$Street, 
                     gsub("([0-9])", "", add$Street)) #Remove Numbers
  #Remove Street Types
  for(i in 1:length(typelist)){
    add$Street<-gsub(eval(parse(text=paste0('" ', typelist[i], '"'))), " ", add$Street)
  }
  #Remove Long Strings
  add$Street<-ifelse((sapply(gregexpr("[[:alpha:]]+", add$Street), function(x) sum(x > 0)))>4, NA, add$Street)
  #Remove Special Characters
  add$Street<-gsub("[<|>|.|+|?|!|,|:|)|(|'|-|\"|;|#]", "", add$Street)  #Eliminate Special Characters
  #Capitalize
  add$Street<-toupper(add$Street)
  add$Street<-trim(add$Street)
  
  ##### Make Address Clean for Geocoding ####
  #Rearange Street Directions
  #add$Street<-ifelse(grepl(" [^A-DF-Z]" ,add$Street), paste0("E ", add$Street), add$Street)
  #add$Street<-gsub(" [^A-DF-Z]", "", add$Street)
  #add$Street<-ifelse(grepl(" [^A-VX-Z]" ,add$Street), paste0("W ", add$Street), add$Street)
  #add$Street<-gsub(" [^A-VX-Z]", "", add$Street)
  #add$Street<-ifelse(grepl(" [^A-DF-Z]" ,add$Street), paste0("E ", add$Street), add$Street)
  #add$Street<-gsub(" [^A-DF-Z]", "", add$Street)
  #add$Street<-ifelse(grepl(" [^A-DF-Z]" ,add$Street), paste0("E ", add$Street), add$Street)
  #add$Street<-gsub(" [^A-DF-Z]", "", add$Street)

  #### Grab Section Before Street Name- Street Number ####
  #Pull Street Numbers
  add$text_add4<-add$text_add3  #Create To Remove Zip Code
  add$text_add4<-gsub("( [7][0-9][0-9][0-9][0-9])", "", add$text_add4)
  
  add$St_Num<-NA
  for(i in 1:length(streetslist)){
    add$St_Num<-ifelse(is.na(add$St_Num) & !is.na(add$Street),
      str_extract(add$text_add4, pattern=eval(parse(text=paste0('"(([0-9])*( ', streetslist[i], ' ))"')))), add$St_Num)
  }
  #Handle Farm Roads
  add$St_Num<-ifelse(add$st_type=="FM",
    str_extract(add$text_add4, pattern=("([0-9]).*( fm)")), add$St_Num)
  #Remove Numbers Attached to 'Th', 'RD' and 'ST'
  add$St_Num<-gsub("([0-9]+[Tt][Hh])|([0-9]+[Rr][Dd])|([0-9]+[Ss][Tt])", "", add$St_Num)
  #Remove Letters
  add$St_Num<-gsub("[A-z]", "", add$St_Num)
  #Remove Special Characters
  add$St_Num<-gsub("[<|>|.|+|?|!|,|:|)|(|'|-|\"|;|#|&]", "", add$St_Num)  #Eliminate Special Characters
  #Trim Whitespace
  add$St_Num<-trim(add$St_Num)
  
  #Rearange Column Order
  add<-add[c(1:10, 15:16, 18, 19, 17, 11:14)]

  #Add "Houston" Where missing city and other aspects of address exist
  add$City<-ifelse(!is.na(add$St_Num) & !is.na(add$Street) & is.na(add$City),
                   "Houston", add$City)
  #Add "Texas" Where missing city and other aspects of address exist
  add$State<-ifelse(!is.na(add$St_Num) & !is.na(add$Street) & is.na(add$State),
                   "TX", add$State)
  #Clean Blank Spaces in ST Num
  add$St_Num<-ifelse(add$St_Num=="", NA, add$St_Num)
  add$st_type<-ifelse(add$st_type=="", NA, add$st_type)
  
  #Create Final Address to Geocode
  add$Address<-NA
  add$Address<-ifelse(!is.na(add$St_Num) & is.na(add$st_type) & is.na(add$Zip),
                paste0(add$St_Num, " ", add$Street," ", add$City, ", ", add$State), 
              ifelse(is.na(add$Address) & !is.na(add$St_Num) & !is.na(add$st_type) & is.na(add$Zip),
                paste0(add$St_Num, " ", add$Street," ", add$st_type, ", ", add$City, ", ", add$State),
              ifelse(is.na(add$Address) & !is.na(add$St_Num) & is.na(add$st_type) & !is.na(add$Zip),
                paste0(add$St_Num, " ", add$Street, ", ", add$City, ", ", add$State, ", ", add$Zip),
              ifelse(is.na(add$Address) & !is.na(add$St_Num),
                paste0(add$St_Num, " ", add$Street," ", add$st_type, ", ", add$City, ", ", add$State, ", ", add$Zip),
              add$Address))))
  add$Address_geo<-NA
  add$Address_geo<-ifelse(!is.na(add$St_Num) & is.na(add$st_type) & is.na(add$Zip),
                  paste0(add$St_Num, " ", add$Street), 
                ifelse(is.na(add$Address_geo) & !is.na(add$St_Num) & !is.na(add$st_type) & is.na(add$Zip),
                  paste0(add$St_Num, " ", add$Street," ", add$st_type),
                ifelse(is.na(add$Address_geo) & !is.na(add$St_Num) & is.na(add$st_type) & !is.na(add$Zip),
                  paste0(add$St_Num, " ", add$Street),
                ifelse(is.na(add$Address_geo) & !is.na(add$St_Num),
                  paste0(add$St_Num, " ", add$Street," ", add$st_type),
                add$Address_geo))))  
  
  out<-subset(add, !is.na(add$Address))
  myvars<-c("created_at", "St_Num", "Street", "st_type", "City", "State", "Zip", "Address", "Address_geo")
  out<-out[myvars]
  out2<-subset(out, !duplicated(out$Address))
  
  completeout<-rbind(completeout, out)
  completeout2<-rbind(completeout2, out2)
  
  write.csv(out, paste0(wd, "/Data/Addresses/All_Address", Day[j], ".csv"))
  write.csv(out2, paste0(wd, "/Data/Addresses/All_Unique_Address", Day[j], ".csv"))
}
write.csv(completeout, paste0(wd, "/Data/Addresses/All_Address.csv"))
write.csv(completeout2, paste0(wd, "/Data/Addresses/All_Unique_Address.csv"))

completeout<-out[1,]
completeout2<-out2[1,]
