library(jsonlite)
wd<-"K:/Projects/FY2018-205_Twitter"

Day<-c("08_25", "08_26", "08_27", "08_28", "08_29", "08_30", "08_31", "09_01", "09_02", 
       "09_03", "09_04", "09_05", "09_06", "09_07", "09_08")
Time_h<-c("00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16",
          "17", "18", "19", "20", "21", "22", "23")
Time_m<-c("00", "10", "20", "30", "40", "50")
twitter_main<-twitter[0,(c(1:2))]
myvars<-c("created_at", "id", "text", "source", "in_reply_to_status_id", "in_reply_to_user_id", "in_reply_to_screen_name",
          "user"  "geo","coordinates"               "place"                     "contributors"             
           [17] "retweeted_status"          "is_quote_status"           "quote_count"               "reply_count"              
           [21] "retweet_count"             "favorite_count"            "entities"                  "favorited"                
           [25] "retweeted"                 "filter_level"              "lang"                      "timestamp_ms"             
           [29] "matching_rules"            "display_text_range"        "quoted_status_id"          "quoted_status_id_str"     
           [33] "quoted_status"             "possibly_sensitive"        "info"    )
myvars<-c("id", "user")

for(i in 1:1){
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
  write.csv(twitter_main, paste0(wd, "/Data/", "tweets_", Day[i], ".csv"))
  twitter_main<-twitter[0,(c(1:35))]
}









### First Attepmt -- Failure ###

twitter <- read_json("K:/Projects/FY2018-205_TWitter/data.json", simplifyVector = FALSE,
                     simplifyDataFrame = simplifyVector)

twitter <- fromJSON("data.json", simplifyVector = TRUE, simplifyDataFrame = simplifyVector,
                    simplifyMatrix = simplifyVector, flatten = FALSE)

data <- fromJSON("data.json")

### Second Attempt ###
library(jsonlite)
library(dplyr)
library(tibble)
library(stringr)

twitter <- fromJSON("data.json")
  #   This does not work because the JSOn file is in Newline delimited JSON.
  # i.e., there are multiple JSON values inside the file and each JSON value
  # is considered an independent object. 