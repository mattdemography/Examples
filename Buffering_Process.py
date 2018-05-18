#Import Libraries
import arcpy, arcinfo
from arcpy.sa import *
from arcpy import env
import arceditor
import os
import sys
import re, shutil

# overwrite output
arcpy.env.overwriteOutput=True

#Set Workspaces
path_hisd="K:\Projects\p011_HISD_Requests\Hurricane_Harvey_Maps\Shapefiles\\"
parcels="K:\Projects\p011_HISD_Requests\Hurricane_Harvey_Maps\Shapefiles\Parcels_2017_Rev.shp"
results_p="K:\Projects\p011_HISD_Requests\Hurricane_Harvey_Maps\Shapefiles\Buffer.gdb\\"
results_t="K:\Projects\FY2018-205_Twitter\Data\Spatial\Twitter.gdb\\"     #This Is The Folder (GDB) That Results Will Go In
buffer_size="150"   #Set the Buffer Size Here
buffer_field= buffer_size + " Meters"    #This field is used in the buffer_analysis to set the output buffer polygon
geocode="FEMA_Damage_Assessments_Combined_R.shp" #Set this to the points you are using for the buffering
date="042218"       #Geocoding Date
buffer_shapefile="Damage_Buffer_" + buffer_size
buffer_dissolve="Damage_Buffer_" + buffer_size + "_Dissolve"
parcels_w_DamageBuffer_temp=results_p + "parcels_w_DamageBuffer_temp"
parcels_w_DamageBuffer_temp2=results_p + "parcels_w_DamageBuffer_temp2"
parcels_w_DamageBuffer=results_p + "parcels_w_DamageBuffer"

print "Copy Parcel Shapefile"
#Copy Parcel File from Parcels_2017_Rev file. Then use attach buffer indicators to this newly created file
arcpy.env.workspace=results_p
arcpy.env.qualifiedFieldNames = False
keepFieldList = ("HCAD_NUM","LocNum", "unique", "Loc_new")
fieldInfo = ""
fieldList = arcpy.ListFields(parcels)
for field in fieldList:  
    if field.name in keepFieldList:  
        fieldInfo = fieldInfo + field.name + " " + field.name + " VISIBLE NONE;"
    else:  
        fieldInfo = fieldInfo + field.name + " " + field.name + " HIDDEN NONE;"
#arcpy.MakeFeatureLayer_management(parcels, "temp", field_info=fieldInfo[:-1])    #First Make Temp Layer to Select Features
#arcpy.CopyFeatures_management("temp", parcels_w_DamageBuffer_temp)    #Save New Feature Class

from datetime import datetime
start_time = datetime.now()
print "Working on Buffering Shapefile"
#Create a buffered shapefile
out_feature= results_p + buffer_shapefile 
#arcpy.Buffer_analysis(in_features=(path_hisd + geocode), out_feature_class=out_feature, buffer_distance_or_field=buffer_field, line_side="FULL", line_end_type="ROUND", dissolve_option="NONE", dissolve_field="", method="PLANAR")

print "Dissolve Buffered Shapefile"
#Dissolve The Buffer Shapefile to Save Space for Next Calculations
#arcpy.Dissolve_management(in_features=out_feature, out_feature_class=(results_p + buffer_dissolve), dissolve_field="", statistics_fields="", multi_part="MULTI_PART", unsplit_lines="DISSOLVE_LINES")

#Calculate Field Where In Variable Equals '1'. This is used to keep track of buffered polygons that intersect parcel map
new_field="In_" + buffer_size + "_PB"    #_PB=Parcel Buffer; _TB=Twitter Buffer
#arcpy.AddField_management((results_p + buffer_dissolve), new_field, "SHORT", "", "", "","", "", "")
#arcpy.CalculateField_management(in_table=(results_p + buffer_dissolve), field=new_field, expression="1", expression_type="VB", code_block="")

end_time = datetime.now()
print('Buffer Duration: {}'.format(end_time - start_time))

start_time = datetime.now()
print "Spatially Join Buffered Polygons to Copy of Parcel File"
#Spatial Join of Buffered Polygons to Parcels
#arcpy.SpatialJoin_analysis(target_features=parcels_w_DamageBuffer_temp2, join_features=buffer_dissolve, out_feature_class="temp", join_operation="JOIN_ONE_TO_ONE",
#                           join_type="KEEP_ALL", match_option="INTERSECT", search_radius="")
#arcpy.CopyFeatures_management("temp", parcels_w_DamageBuffer_temp2)    #Save New Feature Class
#arcpy.Delete_management("temp")

print "Clean New Spatial Join File - Constrain Variables"
arcpy.env.workspace=results_p
arcpy.env.qualifiedFieldNames = False
keepFieldList = ("HCAD_NUM","LocNum", "unique", "Loc_new", "In_75_PB", "In_150_PB")
fieldInfo = ""
fieldList = arcpy.ListFields(parcels_w_DamageBuffer)
for field in fieldList:  
    if field.name in keepFieldList:  
        fieldInfo = fieldInfo + field.name + " " + field.name + " VISIBLE NONE;"
    else:  
        fieldInfo = fieldInfo + field.name + " " + field.name + " HIDDEN NONE;"
#arcpy.MakeFeatureLayer_management(parcels_w_DamageBuffer_temp2, "temp", field_info=fieldInfo[:-1])    #First Make Temp Layer to Select Features
#arcpy.CopyFeatures_management("temp", parcels_w_DamageBuffer)    #Save New Feature Class
#arcpy.Delete_management("temp")

#arcpy.Delete_management(parcels_w_DamageBuffer_temp2)
#arcpy.Delete_management(parcels_w_DamageBuffer_temp)

end_time = datetime.now()
print('Spatial Join Duration: {}'.format(end_time - start_time))

###### CREATE BUFFER SHAPEFILES BY DAMAGE LEVEL ######

print "Copy Parcel Shapefile"
#Copy Parcel File from Parcels_2017_Rev file. Then use attach buffer indicators to this newly created file
parcels_w_DamageBuffer_dmgtype=results_p + "parcels_w_DamageBuffer_dmgtype"

start_time = datetime.now()
arcpy.env.workspace=results_p
arcpy.env.qualifiedFieldNames = False
keepFieldList = ("HCAD_NUM","LocNum", "unique", "Loc_new")
fieldInfo = ""
fieldList = arcpy.ListFields(parcels)
for field in fieldList:  
    if field.name in keepFieldList:  
        fieldInfo = fieldInfo + field.name + " " + field.name + " VISIBLE NONE;"
    else:  
        fieldInfo = fieldInfo + field.name + " " + field.name + " HIDDEN NONE;"
#arcpy.MakeFeatureLayer_management(parcels, "temp", field_info=fieldInfo[:-1])    #First Make Temp Layer to Select Features
#arcpy.CopyFeatures_management("temp", parcels_w_DamageBuffer_dmgtype)    #Save New Feature Class
#arcpy.Delete_management("temp")

end_time = datetime.now()
print('Copy Parcel Shapefile Duration: {}'.format(end_time - start_time))

#, "MIN", "MAJ", "DES"
#, "150"
print "Begin Loop"
dmg_type=["AFF", "MIN", "MAJ", "DES"]
buffer_size=["75", "150"]
for dmg in dmg_type:
    for buff_size in buffer_size:
        buffer_field= buff_size + " Meters"    #This field is used in the buffer_analysis to set the output buffer polygon
        
        #Create Placeholders for Files to Be Created
        dmg_type_points=results_p + dmg + "_points" + "_" + buff_size
        dmg_type_buffer=results_p + dmg + "_buffer" + "_" + buff_size
        dmg_type_dissolve=results_p + dmg + "_dissolve" + "_" + buff_size
        
        arcpy.env.workspace=results_p
        #arcpy.MakeFeatureLayer_management((path_hisd + geocode), "temp")    #First Make Temp Layer to Select Features
        if dmg=="AFF":
        #    arcpy.SelectLayerByAttribute_management("temp", "", '"DMG_LEVEL" = \'AFF\'') #Then Select Features
        #    arcpy.CopyFeatures_management("temp", dmg_type_points)    #Finally Save New Feature Class With Only Matched or Tied Geocoded Parcels
            print "Affected Points"
        elif dmg=="MIN":
        #    arcpy.SelectLayerByAttribute_management("temp", "", '"DMG_LEVEL" = \'MIN\'')
        #    arcpy.CopyFeatures_management("temp", dmg_type_points)
            print "Minor Damage Points"
        elif dmg=="MAJ":
        #    arcpy.SelectLayerByAttribute_management("temp", "", '"DMG_LEVEL" = \'MAJ\'')
        #    arcpy.CopyFeatures_management("temp", dmg_type_points)
            print "Major Damage Points"
        elif dmg=="DES":
        #    arcpy.SelectLayerByAttribute_management("temp", "", '"DMG_LEVEL" = \'DES\'')
        #    arcpy.CopyFeatures_management("temp", dmg_type_points)
            print "Destroyed Points"
        else:
            print "Error in Making dmg_type_points"

        print "Buffer " + dmg 
        #arcpy.Buffer_analysis(in_features=dmg_type_points, out_feature_class=dmg_type_buffer, buffer_distance_or_field=buffer_field, line_side="FULL", line_end_type="ROUND", dissolve_option="NONE", dissolve_field="", method="PLANAR")

        print "Dissolve Buffered Shapefile"
        #Dissolve The Buffer Shapefile to Save Space for Next Calculations
        #arcpy.Dissolve_management(in_features=dmg_type_buffer, out_feature_class=dmg_type_dissolve, dissolve_field="", statistics_fields="", multi_part="MULTI_PART", unsplit_lines="DISSOLVE_LINES")

        #arcpy.Delete_management(dmg_type_points)
        #arcpy.Delete_management(dmg_type_buffer)

        #Calculate Field Where In Variable Equals '1'. This is used to keep track of buffered polygons that intersect parcel map
        new_field="In_" + dmg + "_" + buff_size + "_PB"    #_PB=Parcel Buffer; _TB=Twitter Buffer
        #arcpy.AddField_management(dmg_type_dissolve, new_field, "SHORT", "", "", "","", "", "")
        #arcpy.CalculateField_management(in_table=dmg_type_dissolve, field=new_field, expression="1", expression_type="VB", code_block="")

        #Spatial Join of Buffered Polygons to Parcels
        print "Spatial Join " + dmg + " " + buff_size
        start_time = datetime.now()
        #arcpy.SpatialJoin_analysis(target_features=parcels_w_DamageBuffer_dmgtype, join_features=dmg_type_dissolve, out_feature_class="temp", join_operation="JOIN_ONE_TO_ONE",
        #                       join_type="KEEP_ALL", match_option="INTERSECT", search_radius="")
        #arcpy.CopyFeatures_management("temp", parcels_w_DamageBuffer_dmgtype)    #Save New Feature Class
        #arcpy.Delete_management("temp")
        end_time = datetime.now()
        print('Spatial Join Duration: {}'.format(end_time - start_time))

#Calculate Field Where In Variable Equals '1'. This is used to keep track of buffered polygons that intersect parcel map
print "Begin Creating New Variable to Determine Buffered Damage Level"
exp_des="\"DES\""
exp_maj="\"MAJ\""
exp_min="\"MIN\""
exp_aff="\"AFF\""

new_field="DmgType_75_PB"    #_PB=Parcel Buffer; _TB=Twitter Buffer
field_length=10
arcpy.MakeFeatureLayer_management(parcels_w_DamageBuffer_dmgtype, "temp")    #First Make Temp Layer to Select Features
arcpy.AddField_management("temp", new_field, "TEXT", field_length=field_length)
arcpy.SelectLayerByAttribute_management("temp", "", '"In_DES_75_PB" = 1')
arcpy.CalculateField_management("temp", new_field, exp_des, "PYTHON_9.3")
arcpy.SelectLayerByAttribute_management("temp", "", '"In_MAJ_75_PB" = 1 AND "DmgType_75_PB" IS NULL')
arcpy.CalculateField_management("temp", new_field, exp_maj, "PYTHON_9.3")
arcpy.SelectLayerByAttribute_management("temp", "", '"In_MIN_75_PB" = 1 AND "DmgType_75_PB" IS NULL')
arcpy.CalculateField_management("temp", new_field, exp_min, "PYTHON_9.3")
arcpy.SelectLayerByAttribute_management("temp", "", '"In_AFF_75_PB" = 1 AND "DmgType_75_PB" IS NULL')
arcpy.CalculateField_management("temp", new_field, exp_aff, "PYTHON_9.3")

new_field="DmgType_150_PB"    #_PB=Parcel Buffer; _TB=Twitter Buffer
arcpy.AddField_management("temp", new_field, "TEXT", "", "", "","", "", "")
arcpy.SelectLayerByAttribute_management("temp", "", '"In_DES_150_PB" = 1')
arcpy.CalculateField_management("temp", new_field, exp_des, "PYTHON_9.3")
arcpy.SelectLayerByAttribute_management("temp", "", '"In_MAJ_150_PB" = 1 AND "DmgType_150_PB" IS NULL')
arcpy.CalculateField_management("temp", new_field, exp_maj, "PYTHON_9.3")
arcpy.SelectLayerByAttribute_management("temp", "", '"In_MIN_150_PB" = 1 AND "DmgType_150_PB" IS NULL')
arcpy.CalculateField_management("temp", new_field, exp_min, "PYTHON_9.3")
arcpy.SelectLayerByAttribute_management("temp", "", '"In_AFF_150_PB" = 1 AND "DmgType_150_PB" IS NULL')
arcpy.CalculateField_management("temp", new_field, exp_aff, "PYTHON_9.3")

print "Clean New Spatial Join File - Constrain Variables"
arcpy.env.qualifiedFieldNames = False
keepFieldList = ("HCAD_NUM","LocNum", "unique", "Loc_new", "In_AFF_75_PB", "In_MIN_75_PB", "In_MAJ_75_PB", "In_DES_75_PB",
                 "In_AFF_150_PB", "In_MIN_150_PB", "In_MAJ_150_PB", "In_DES_150_PB",
                 "DmgType_75_PB", "DmgType_150_PB")
fieldInfo = ""
fieldList = arcpy.ListFields(parcels_w_DamageBuffer_dmgtype)
for field in fieldList:  
    if field.name in keepFieldList:  
        fieldInfo = fieldInfo + field.name + " " + field.name + " VISIBLE NONE;"
    else:  
        fieldInfo = fieldInfo + field.name + " " + field.name + " HIDDEN NONE;"
parcels_w_DamageBuffer_dmgtype2=results_p + "parcels_w_DamageBuffer_dmgtype_75_150"
arcpy.MakeFeatureLayer_management(parcels_w_DamageBuffer_dmgtype, "temp", field_info=fieldInfo[:-1])    #First Make Temp Layer to Select Features
arcpy.CopyFeatures_management("temp", parcels_w_DamageBuffer_dmgtype2)    #Save New Feature Class
#arcpy.Delete_management("temp")
