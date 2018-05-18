#Python 2.7.8 (default, Jun 30 2014, 16:08:48) [MSC v.1500 64 bit (AMD64)] on win32
#Type "copyright", "credits" or "license()" for more information.

import arcpy
import os
import sys
import subprocess

# overwrite output
arcpy.env.overwriteOutput=True
#Define Workspace
user="mjm17"
path="K:\Curation\HISD\Education\Tabular\Student\\"
rpath= r'K:/Curation/HISD/Education/Tabular/Student/'
script_path= 'C:/Program Files/R/R-3.3.3/bin/Rscript'

#Run R Script to Get Address File to be Geocoded
print "Running Second_Geocode.R"
script_secondgeo= rpath + "Second_Geocode.R"
process= subprocess.call([script_path, script_secondgeo], shell=True)

#Bring in Neccessary Files for Geocode from R Procedure
Addresses= path + "\Stu_Add_EOY_1617_r2.csv"    #Student Addresses
Orig_Parcel_Table = path + "\Shapefiles\Parcel_Flood_Damage.shp 'Primary Table'"   #Parcel Shapefile for Locator
Orig_Parcel = path + "\Shapefiles\Parcel_Flood_Damage.shp"   #Parcel Shapefile
add_locator= path + "\Locators\Stu_AddLoc_Parcel_rev"    #Where Address Locator will be Placed
address_fields= "Street new_stuadd; City Student_Ci; State <None>; ZIP Student_Zi" #Names from the Student File
Stu_Parcel_Points= path + "\Shapefiles\Results_92517.gdb\Stu_Parcel_Points_2"

#Geocode Addresses to Parcel Data
print "Working on Geocoding"
#arcpy.GeocodeAddresses_geocoding(Addresses, add_locator, address_fields, Stu_Parcel_Points)

#After Geocode, Attach Points to Parcel Flood Data
print "Working on Attaching Points to Parcels"
Stu_Parcel_Damage= path + "\Shapefiles\Results_92517.gdb\Stu_Parcel_Damage"

#Attach Student points to Parcel Damage
#arcpy.SpatialJoin_analysis(Orig_Parcel, Stu_Parcel_Points, Stu_Parcel_Damage, "JOIN_ONE_TO_ONE", "KEEP_ALL", "#", "INTERSECT")

#Select Only Geocoded Features
print "Working on Creating New Selection"
#arcpy.env.workspace= path + "\Shapefiles\Results_92517.gdb"
#arcpy.MakeFeatureLayer_management(Stu_Parcel_Damage, "temp")    #First Make Temp Layer to Select Features
#arcpy.SelectLayerByAttribute_management("temp", "", '"Status" = \'M\' OR "Status" = \'T\'') #Then Select Features
#arcpy.CopyFeatures_management("temp", "Stu_Parcel_Damage_2")    #Finally Save New Feature Class

#Output to DBF for Analysis in R
print "Converting to DBF"
dbf= path + "\Shapefiles\DBF\\"
#arcpy.TableToDBASE_conversion(["Stu_Parcel_Damage_2"], dbf)
#arcpy.TableToDBASE_conversion(["Stu_Parcel_Points_2"], dbf)

#Delete Unneeded Files
#arcpy.Delete_management(Stu_Parcel_Damage)
#arcpy.Delete_management("temp")

print "Finished"
