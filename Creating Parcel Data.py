#Python 2.7.8 (default, Jun 30 2014, 16:08:48) [MSC v.1500 64 bit (AMD64)] on win32
#Type "copyright", "credits" or "license()" for more information.

import arcpy
import os
import sys

# overwrite output
arcpy.env.overwriteOutput=True
#Define Workspace
user="mjm17"

fema="K:\Curation\HISD\Education\Tabular\Student\Shapefiles\FEMA_Damage_Assessments_Combined_R.shp"
parcel="K:\Curation\HISD\Education\Tabular\Student\Shapefiles\Parcels_2017_Rev.shp"
output="K:\Curation\HISD\Education\Tabular\Student\Shapefiles\Output.gdb\Parcel_Flood_Damage_R"

#stu_points="K:\Curation\HISD\Education\Tabular\Student\Shapefiles\Geocode_stu2016_Parcel.shp"
#parcel="K:\Curation\HISD\Education\Tabular\Student\Shapefiles\Parcel Flood Damage.shp"
#stu_parcel_damage_temp="K:\Curation\HISD\Education\Tabular\Student\Shapefiles\Output.gdb\stu_parcel_damage_temp" #Create in Geodatabase due to size limit
#stu_parcel_damage="K:\Curation\HISD\Education\Tabular\Student\Shapefiles\Output.gdb\stu_parcel_damage"

#Attach FEMA point data to parcels
arcpy.SpatialJoin_analysis(parcel, fema, output, "JOIN_ONE_TO_ONE", "KEEP_ALL", "#", "INTERSECT")

#Select All Attributes that are not null on unique_1 to create new shapefile outside of GDB

#Attach Student points to Parcel Damage
#arcpy.SpatialJoin_analysis(parcel, stu_points, stu_points_damage, "JOIN_ONE_TO_ONE", "KEEP_ALL", "#", "INTERSECT")

print "Finished"
