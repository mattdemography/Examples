import arcpy, arcinfo
from arcpy.sa import *
from arcpy import env
import arceditor
import os
import sys

import re, shutil

# overwrite output
arcpy.env.overwriteOutput=True

#CHANGE THIS TO DENSITY PARAMETERS
Cell_Size="10"
Search_Radius="50"
Parms="KD" + Cell_Size + "_" + Search_Radius

path="K:\Projects\p011_HISD_Requests\Hurricane_Harvey_Maps\\"
results="Shapefiles\Kernel_Density_Results.gdb"
fema_points=path + "Shapefiles\FEMA_DAC_R_Project.shp"
former_damage=path + "Shapefiles\Parcel_Damage_Assessments.shp"
parcel=path + "Shapefiles\Parcel_2017_R.shp"

raster= path + results + "\\" + Parms
points= path + results + "\\" + Parms + "_P"
density=path + results + "\\" + Parms + "_P_Selection"
parcel_density_temp=path + results + "\Parcel_" + Parms + "_temp"
parcel_density_temp2=path + results + "\Parcel_" + Parms + "_temp2"
parcel_density_gdb=path + results + "\Parcel_" + Parms
parcel_density=path + "Shapefiles\Parcel_" + Parms + ".shp"

expression_newest1="!Parcel_Damage_Assessments_IN_DEPTH!"
expression_newest2="!Parcel_" + Parms + "_temp_grid_code!"
expression_newest3="!Parcel_" + Parms + "_temp_Parcel_ID!"

print "Making Kernel Density Plot"
#arcpy.CheckOutExtension("spatial")
#kd=KernelDensity(fema_points, 'IN_DEPTH', cell_size=Cell_Size, search_radius=Search_Radius, area_unit_scale_factor='SQUARE_METERS', out_cell_values='EXPECTED_COUNTS', method='GEODESIC')
print "Saving Raster"
#kd.save(raster)
#arcpy.CheckInExtension("spatial")

print "Working on Converting Raster to Point"
#Use Raster To Point then Select By 
arcpy.RasterToPoint_conversion(raster, points, "")

#Select Only Density Dots Greater Than 0 (i.e. Points with estimated flooding above 0 in)
print "Working on Creating New Selection from Raster Point Data"
arcpy.env.workspace= path + results
arcpy.MakeFeatureLayer_management(raster, "temp")    #First Make Temp Layer to Select Features
arcpy.SelectLayerByAttribute_management("temp", "", '"grid_code" > 0') #Then Select Features
arcpy.CopyFeatures_management("temp", density)    #Finally Save New Feature Class With Only Matched or Tied Geocoded Parcels

#Add all fields from inputs
fieldmappings = arcpy.FieldMappings()
fieldmappings.addTable(density)
fieldmappings.addTable(parcel)
keepers = ["pointid", "grid_code", "Parcel_ID"] # Name fields to Keep

#Remove all output fields you don't want.
for field in fieldmappings.fields:
    if field.name not in keepers:
        fieldmappings.removeFieldMap(fieldmappings.findFieldMapIndex(field.name))

print "Spatial Join Parcels to Kernel Density Points"
#Attach Parcel IDs to Kernel Density points
arcpy.SpatialJoin_analysis(parcel, density, parcel_density_temp, "JOIN_ONE_TO_MANY", "KEEP_ALL", fieldmappings, "INTERSECT")

print "Adding Former Flood Estimates"
#Join Former Flood Estimates to Kernel Density Estimates
arcpy.env.workspace= path + results
arcpy.MakeFeatureLayer_management(parcel_density_temp, "temp")    #First Make Temp Layer to Select Features
arcpy.AddJoin_management("temp", "Parcel_ID", former_damage, "Parcel_ID")
arcpy.CopyFeatures_management("temp", parcel_density_temp2)

print "Calculating New Flood Estimates"
#Calculate new flood estimates which are a combination of kernel density and former estimates
arcpy.AddField_management(parcel_density_temp2, "new_est", "FLOAT", "", "", "", "", "", "")
arcpy.AddField_management(parcel_density_temp2, "Parcel_ID", "FLOAT", "", "", "", "", "", "")
arcpy.AddField_management(parcel_density_temp2, "grid_code", "FLOAT", "", "", "", "", "", "")
arcpy.AddField_management(parcel_density_temp2, "IN_DEPTH", "FLOAT", "", "", "", "", "", "")
arcpy.MakeFeatureLayer_management(parcel_density_temp2, "temp")    #First Make Temp Layer to Select Features
arcpy.CalculateField_management("temp", "Parcel_ID", expression_newest3, "PYTHON_9.3")    #Calculate Parcel_ID - To Keep At End
arcpy.CalculateField_management("temp", "grid_code", expression_newest2, "PYTHON_9.3")    #Calculate grid_code - To Keep At End
arcpy.CalculateField_management("temp", "IN_DEPTH", expression_newest1, "PYTHON_9.3")    #Calculate IN_DEPTH - To Keep At End
arcpy.SelectLayerByAttribute_management("temp", "", '"Parcel_Damage_Assessments_IN_DEPTH" > 0')
arcpy.CalculateField_management("temp", "new_est", expression_newest1, "PYTHON_9.3")    #Calculate New Est Using Inch Depth First
arcpy.SelectLayerByAttribute_management("temp", "CLEAR_SELECTION")

arcpy.SelectLayerByAttribute_management("temp", "", '"Parcel_Damage_Assessments_IN_DEPTH" IS NULL')
arcpy.CalculateField_management("temp", "new_est", expression_newest2, "PYTHON_9.3")    #Calculate New Est Using Estimated Inch Depth (grid_code) Next
arcpy.SelectLayerByAttribute_management("temp", "CLEAR_SELECTION")

print "Deleting Fields"
fields = arcpy.ListFields("temp") 
keepFields = ["FID", "OBJECTID", "Shape", "Shape_Area", "Shape_Length", "Parcel_ID", "grid_code", "IN_DEPTH", "new_est"]  #Fields to Keep
dropFields = [x.name for x in fields if x.name not in keepFields]
arcpy.DeleteField_management("temp", dropFields)

print "Make Copy of Shapefile"
arcpy.SelectLayerByAttribute_management("temp", "", '"new_est" > 0')
arcpy.CopyFeatures_management("temp", parcel_density_gdb)

print "Dissolve Based on Parcel_ID"
arcpy.Dissolve_management(parcel_density_gdb, parcel_density, dissolve_field='Parcel_ID', statistics_fields=[['new_est', 'MAX']])

arcpy.Delete_management(parcel_density_temp)
arcpy.Delete_management(parcel_density_temp2)
arcpy.Delete_management(parcel_density_gdb)
