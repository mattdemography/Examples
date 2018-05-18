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

#Run R Script to Get Address File to be Geocoded
print "Running Apartment_Indicator.R"
#command= 'Rscript'
#script_apt_indicator= path + "Apartment_Indicator.R"
#cmd=[command, script_apt_indicator]
#subprocess.call (["/usr/bin/Rscript", "--Another Canoe", script_apt_indicator])
#subprocess.call(script_apt_indicator)
#subprocess.check_output(cmd, universal_newlines=True)

#Bring in Neccessary Files for Geocode from R Procedure
Addresses= path + "\Stu_Add_EOY_1617_r.csv"    #Student Addresses
Orig_Parcel_Table = path + "\Shapefiles\Parcel_Flood_Damage.shp 'Primary Table'"   #Parcel Shapefile for Locator
Orig_Parcel = path + "\Shapefiles\Parcel_Flood_Damage.shp"   #Parcel Shapefile
add_locator= path + "\Locators\Stu_AddLoc_Parcel_rev"    #Where Address Locator will be Placed
address_fields= "Street Student_Address; City Student_City; State <None>; ZIP Student_Zip_Code" #Names from the Student File
Stu_Parcel_Points= path + "\Shapefiles\Results_92517.gdb\Stu_Parcel_Points_1"

#Create Field Map
field_map="""
"'Feature ID' FID VISIBLE NONE; '*House Number' LocNum VISIBLE NONE;
'Side' <None> VISIBLE NONE;'Prefix Direction' <None> VISIBLE NONE;
'Prefix Type' <None> VISIBLE NONE;'*Street Name' LocName_ne VISIBLE NONE;
'Suffix Type' <None> VISIBLE NONE;'Suffix Direction' <None> VISIBLE NONE;
'City or Place' CITY VISIBLE NONE;'ZIP Code' ZIP VISIBLE NONE;
'State' <None> VISIBLE NONE;'Street ID' <None> VISIBLE NONE;
'Display X' <None> VISIBLE NONE;'Display Y' <None> VISIBLE NONE;
'Min X value for extent' <None> VISIBLE NONE;'Max X value for extent' <None> VISIBLE NONE;
'Min Y value for extent' <None> VISIBLE NONE;'Max Y value for extent' <None> VISIBLE NONE;
'Additional Field' <None> VISIBLE NONE;'Altname JoinID' <None> VISIBLE NONE"""

print "Working on Locator"
arcpy.CreateAddressLocator_geocoding(in_address_locator_style="US Address - Single House", in_reference_data=Orig_Parcel_Table, in_field_map=field_map, out_address_locator=add_locator)

#Geocode Addresses to Parcel Data
print "Working on Geocoding"
arcpy.GeocodeAddresses_geocoding(Addresses, add_locator, address_fields, Stu_Parcel_Points)

#After Geocode, Attach Points to Parcel Flood Data
print "Working on Attaching Points to Parcels"
Stu_Parcel_Damage= path + "\Shapefiles\Results_92517.gdb\Stu_Parcel_Damage"

#Attach Student points to Parcel Damage
arcpy.SpatialJoin_analysis(Orig_Parcel, Stu_Parcel_Points, Stu_Parcel_Damage, "JOIN_ONE_TO_ONE", "KEEP_ALL", "#", "INTERSECT")

#Select Only Geocoded Features
print "Working on Creating New Selection"
arcpy.env.workspace= path + "\Shapefiles\Results_92517.gdb"
arcpy.MakeFeatureLayer_management(Stu_Parcel_Damage, "temp")    #First Make Temp Layer to Select Features
arcpy.SelectLayerByAttribute_management("temp", "", '"Status" = \'M\' OR "Status" = \'T\'') #Then Select Features
arcpy.CopyFeatures_management("temp", "Stu_Parcel_Damage_1")    #Finally Save New Feature Class

#Output to DBF for Analysis in R
print "Converting to DBF"
dbf= path + "\Shapefiles\DBF\\"
arcpy.TableToDBASE_conversion(["Stu_Parcel_Damage_1"], dbf)
arcpy.TableToDBASE_conversion(["Stu_Parcel_Points_1"], dbf)

#Delete Unneeded Files
arcpy.Delete_management(Stu_Parcel_Damage)
arcpy.Delete_management("temp")

print "Finished"
