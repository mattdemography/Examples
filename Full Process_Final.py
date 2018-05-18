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
path="K:\Projects\p011_HISD_Requests\Hurricane_Harvey_Maps\\"
rpath= r'K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/'
script_path= 'C:/Program Files/R/R-3.3.3/bin/Rscript'
results= "\Shapefiles\Results_10317.gdb"
dbf= path + "\Shapefiles\DBF\\"

#Run R Script to Get Address File to be Geocoded
print "Running Apartment_Indicator.R"
script_apt_indicator= rpath + "Apartment_Indicator.R"
#process= subprocess.call([script_path, script_apt_indicator], shell=True)

#Bring in Neccessary Files for Geocode from R Procedure
Addresses= path + "\Stu_Add_EOY_1617_r.csv"    #Student Addresses
Orig_Parcel_Table = path + "\Shapefiles\Parcels_2017_Rev.shp 'Primary Table'"   #Parcel Shapefile for Locator
Orig_Parcel = path + "\Shapefiles\Parcels_2017_Rev.shp"   #Parcel Shapefile
Parcel_Damage= path + "\Shapefiles\Parcel_Damage_Assessments.shp"   #Parcel Shapefile Only for Parcels with Damage
add_locator= path + "\Locators\Stu_AddLoc_Parcel_rev"    #Where Address Locator will be Placed
address_fields= "Street Student_Address; City Student_City; State <None>; ZIP Student_Zip_Code" #Names from the Student File
Stu_Points_1= path + results + "\Stu_Points_1"

#Create Field Map
field_map="""
"'Feature ID' FID VISIBLE NONE; '*House Number' LocNum VISIBLE NONE;
'Side' <None> VISIBLE NONE;'Prefix Direction' <None> VISIBLE NONE;
'Prefix Type' <None> VISIBLE NONE;'*Street Name' Loc_new VISIBLE NONE;
'Suffix Type' <None> VISIBLE NONE;'Suffix Direction' <None> VISIBLE NONE;
'City or Place' CITY VISIBLE NONE;'ZIP Code' ZIP VISIBLE NONE;
'State' <None> VISIBLE NONE;'Street ID' <None> VISIBLE NONE;
'Display X' <None> VISIBLE NONE;'Display Y' <None> VISIBLE NONE;
'Min X value for extent' <None> VISIBLE NONE;'Max X value for extent' <None> VISIBLE NONE;
'Min Y value for extent' <None> VISIBLE NONE;'Max Y value for extent' <None> VISIBLE NONE;
'Additional Field' <None> VISIBLE NONE;'Altname JoinID' <None> VISIBLE NONE"""

print "Working on Locator"
#arcpy.CreateAddressLocator_geocoding(in_address_locator_style="US Address - Single House", in_reference_data=Orig_Parcel_Table, in_field_map=field_map, out_address_locator=add_locator)

#Geocode Addresses to Parcel Data
print "Working on Geocoding"
#arcpy.GeocodeAddresses_geocoding(Addresses, add_locator, address_fields, Stu_Points_1)

#Output to DBF for Analysis in R
print "Converting to DBF"
#arcpy.TableToDBASE_conversion([Stu_Points_1], dbf)

print "Finished Geocode 1"

#Run R Script to Get Address File to be Geocoded
print "Running Second_Geocode.R"
script_secondgeo= rpath + "Second_Geocode.R"
#process= subprocess.call([script_path, script_secondgeo], shell=True)

#Bring in Neccessary Files for Geocode from R Procedure
Addresses= path + "\Stu_Add_EOY_1617_r2.csv"    #Student Addresses
address_fields= "Street new_stuadd; City Student_Ci; State <None>; ZIP Student_Zi" #Names from the Student File
Stu_Points_2= path + results + "\Stu_Points_2"

#Geocode Addresses to Parcel Data
print "Working on Geocoding"
#arcpy.GeocodeAddresses_geocoding(Addresses, add_locator, address_fields, Stu_Points_2)

#Output to DBF for Analysis in R
print "Converting to DBF"
#arcpy.TableToDBASE_conversion([Stu_Points_2], dbf)

print "Finished Geocode 2"

print "Merging Points"
Stu_Points_Complete_gdb= path + results + "\Stu_Points_Complete_temp"
Stu_Points_Complete_temp= path + "Shapefiles\Stu_Points_Complete_temp.shp"
Stu_Points_Complete= path + "Shapefiles\Stu_Points_Complete.shp"

#arcpy.Merge_management([Stu_Points_1, Stu_Points_2], Stu_Points_Complete_gdb) #Points (To Add Apartment Buildings) Place in GDB
#arcpy.Merge_management([Stu_Points_1, Stu_Points_2], Stu_Points_Complete_temp) #Points (To Add Apartment Buildings)

#Run R Script to Output Geocoded Results by School in CSV form.
print "Running Final_Geocode.R"
script_finalgeo= rpath + "Final_Geocode.R"
#process= subprocess.call([script_path, script_finalgeo], shell=True)

print "Final_Geocode_by_School.csv and Stu_Points_Complete.shp Produced"

#Now Merge the Geocode Results to Parcels
print "Working on Attaching Points to Parcels"
Stu_Parcels= path + "Shapefiles\Stu_Parcels_Complete.shp"             #Join Points to Parcels
Stu_Parcels_temp= path + results + "\Stu_Parcels_temp"                #Temp File Produced
#arcpy.SpatialJoin_analysis(Orig_Parcel, Stu_Points_Complete, Stu_Parcels_temp, "JOIN_ONE_TO_ONE", "KEEP_ALL", "#", "INTERSECT")

#Select Only Geocoded Features
print "Working on Creating New Selection"
#arcpy.env.workspace= path + results
#arcpy.MakeFeatureLayer_management(Stu_Parcels_temp, "temp")    #First Make Temp Layer to Select Features
#arcpy.SelectLayerByAttribute_management("temp", "", '"Status" = \'M\' OR "Status" = \'T\'') #Then Select Features
#arcpy.CopyFeatures_management("temp", Stu_Parcels)    #Finally Save New Feature Class With Only Matched or Tied Geocoded Parcels

Stu_Points_Damage=  path + results + "\Stu_Points_Damage"    #Join Parcel Damage Information to Student Geocoded Points
#arcpy.SpatialJoin_analysis(Stu_Points_Complete, Parcel_Damage, Stu_Points_Damage, "JOIN_ONE_TO_ONE", "KEEP_ALL", "#", "INTERSECT")

print "Join HCAD_NUM to Stu_Points_Complete"
Stu_Points_Parcels= path + "Shapefiles\Stu_Points_Parcels.shp"  #Join Parcel Information HCAD_NUM to Points for Choosing Schools in Match_Zone_Enroll.R process
Stu_Points_Parcels_temp= path + results + "\Stu_Points_Parcels_temp"

#arcpy.SpatialJoin_analysis(Stu_Points_Complete, Orig_Parcel, Stu_Points_Parcels_temp, "JOIN_ONE_TO_ONE", "KEEP_ALL", "#", "INTERSECT")
#arcpy.env.workspace= path + results
#arcpy.MakeFeatureLayer_management(Stu_Points_Parcels_temp, "temp3")    #First Make Temp Layer to Select Features
#arcpy.SelectLayerByAttribute_management("temp3", "", '"Status" = \'M\' OR "Status" = \'T\'') #Then Select Features
#arcpy.CopyFeatures_management("temp3", Stu_Points_Parcels)    #Finally Save New Feature Class With Only Matched or Tied Geocoded Parcels

print "Converting to DBF"
#arcpy.TableToDBASE_conversion([Stu_Parcels], dbf) #Output to DBF for Analysis in R
#arcpy.TableToDBASE_conversion([Stu_Points_Damage], dbf) #Output to DBF for Analysis in R

print "Create Apartment Point File" 
#Create Point Shape File That is Only Apartment Parcels - Will be used to symbolize apartment buildings
apts= path + results + "\Apts"
#arcpy.env.workspace= path + results
#arcpy.MakeFeatureLayer_management(Stu_Points_Complete, "temp2")    #First Make Temp Layer to Select Features
#arcpy.SelectLayerByAttribute_management("temp2", "", '"apt_build" = \'1\'') #Then Select Features
#arcpy.CopyFeatures_management("temp2", "apts")    #Finally Save New Feature Class    

#Delete Unneeded Files
#arcpy.Delete_management(Stu_Parcels_temp)
#arcpy.Delete_management(Stu_Points_Complete_temp)
#arcpy.Delete_management("temp")
#arcpy.Delete_management("temp2")

######## CREATE FOLDERS FOR EVERY SCHOOL AND COMPLETE PREPARING DATA FOR MAPS ########

#Elementary Schools - 'attend_elem_1516'
# "Alcott", "Askew", "Barrick", "Benbrook", "Berry", "Blackshear", "Bonham", "Bonner", "Briargrove", "Brookline",
# "Browning", "Burbank", "Burrus", "Bush", "Carrillo", "Condit", "Coop", "Cornelius", "Crespo", "Davila", "DeChaumes",
# "De Zavala", "Dogan", "Durham", "Durkee", "Eliot", "Elrod", "Emerson", "Field", "Foerster", "Foster", "Franklin",
# "Gallegos", "Garcia", "Garden Oaks", "Garden Villas", "Golfcrest", "Gregg", "J. R. Harris", "R. P. Harris", "Hartsfield",
# "Harvard", "Helms", "J.P. Henderson", "Henderson NQ", "Herrera", "Horn", "McGowen", "Isaacs", "Janowski", "Jefferson",
# "Kashmere Gardens", "Kelso", "Kennedy", "Lantrip", "Lewis", "Lockhart", "Longfellow", "Looscan",
# "Love", "Lyons", "MacGregor", "Mading", "C. Martinez", "R. Martinez", "McNamara", "Memorial", "Milne", "Northline",
# "Oak Forest", "Oates", "Paige", "Park Place", "Patterson", "Petersen", "Piney Point", "Pleasantville", "Port Houston",
# "Pugh", "River Oaks", "Roosevelt", "Ross", "Rucker", "Rusk", "Sanchez", "Cook", "Scarborough", "Scroggins", "Ashford",
# "Sinclair", "Smith", "Southmayd", "Stevens", "Thompson", "Tijerina", "Tinsley", "Travis", "Twain", "Valley West",
# "Wainwright", "Walnut Bend", "West University", "Whidby", "Neff", "Whittier", "Windsor Village", "Young", "Robinson",
# "Seguin", "Ketelsen", "Cage", "Highland Heights", "Osborne", "Wesley", "Daily", "Moreno", "St. George", "Pilgrim",
# "Bastian", "Bruce", "Codwell", "Reynolds", "Atherton", "Peck", "Sherman", "Crockett", "Frost", "Fondren", "Hines-Caldwell",
# "Grissom", "Hobby", "Montgomery", "Almeda", "Law", "Mitchell", "DeAnda", "Bell", "Gross", "Anderson", "Parker", "Red",
# "Shearn", "Kolter", "Lovett", "Herod", "Sutton", "Benavidez", "Rodriguez", "Cunningham", "Poe", "Roberts", "Braeburn",
# "Reagan", "White", "Gregory-Lincoln", "Woodson", "Wharton", "Wilson", "Shadydale", "Marshall", "Elmore", "Hilliard"

#Middle Schools - 'attend_Middle_Sch_1516'
# "Attucks", "Black", "Burbank", "Clifton", "Cullen", "Deady", "Dowling", "Edison", "Fleming", "Fondren", "Fonville",
# "Forest Brook", "Grady", "Gregory-Lincoln", "Hamilton", "Hartman", "Henry", "Hogg", "Holland", "Jackson", "Johnston",
# "Key", "Lanier", "Long", "Marshall", "McReynolds", "Ortiz", "Pershing", "Revere", "Stevenson", "Sugar Grove", "Thomas",
# "Welch", "West Briar", "Williams", "Woodson", "Reagan"

#High Schools - 'attend_high_1516'
# "Austin", "Bellaire", "Chavez", "Davis", "Furr", "Houston", "Kashmere", "Lamar", "Lee", "Madison", "Milby", "North Forest",
# "Reagan", "Scarborough", "Sharpstown", "Sterling", "Waltrip", "Washington", "Westbury", "Westside", "Wheatley", "Worthing", "Yates"

print "******** Create Folders for Schools ********"
root_path_e=r'K:\Projects\p011_HISD_Requests\Hurricane_Harvey_Maps\Schools\Elementary'
root_path_m=r'K:\Projects\p011_HISD_Requests\Hurricane_Harvey_Maps\Schools\Middle_School'
root_path_h=r'K:\Projects\p011_HISD_Requests\Hurricane_Harvey_Maps\Schools\High_School'

#Finished: "Alcott", "Askew", "Barrick", "Benbrook", "Berry", "Blackshear", "Bonham", "Bonner", "Briargrove", "Brookline",
# "Browning", "Burbank", "Burrus", "Bush", "Carrillo", "Condit", "Coop", "Cornelius", "Crespo", "Davila", "DeChaumes",
# "De Zavala", "Dogan", "Durham", "Durkee", "Eliot", "Elrod", "Emerson", "Field", "Foerster", "Foster", "Franklin",
# "Gallegos", "Garcia", "Garden Oaks", "Garden Villas", "Golfcrest", "Gregg", "Hartsfield",
# "Harvard", "Helms", "Henderson NQ", "Herrera", "Horn", "McGowen", "Isaacs", "Janowski", "Jefferson",
# "Kashmere Gardens", "Kelso", "Kennedy", "Lantrip", "Lewis", "Lockhart", "Longfellow", "Looscan",
# "Love", "Lyons", "MacGregor", "Mading",  "McNamara", "Memorial", "Milne", "Northline",
# "Oak Forest", "Oates", "Paige", "Park Place", "Patterson", "Petersen", "Piney Point", "Pleasantville", "Port Houston",
# "Pugh", "River Oaks", "Roosevelt", "Ross", "Rucker", "Rusk", "Sanchez", "Cook", "Scarborough", "Scroggins", "Ashford",
# "Sinclair", "Smith", "Southmayd", "Stevens", "Thompson", "Tijerina", "Tinsley", "Travis", "Twain", "Valley West",
# "Wainwright", "Walnut Bend", "West University", "Whidby", "Neff", "Whittier", "Windsor Village", "Young", "Robinson",
# "Seguin", "Ketelsen", "Cage", "Highland Heights", "Osborne", "Wesley", "Daily", "Moreno", "Pilgrim",
# "Bastian", "Bruce", "Codwell", "Reynolds", "Atherton", "Peck", "Sherman", "Crockett", "Frost", "Fondren",
# "Grissom", "Hobby", "Montgomery", "Almeda", "Law", "Mitchell", "DeAnda", "Bell", "Gross", "Anderson", "Parker", "Red",
# "Shearn", "Kolter", "Lovett", "Herod", "Sutton", "Benavidez", "Rodriguez", "Cunningham", "Poe", "Roberts", "Braeburn",
# "Reagan", "White", "Woodson", "Wharton", "Wilson", "Shadydale", "Marshall", "Elmore", "Hilliard"

#Needs Work "J R Harris", "R P Harris", "J P Henderson", "C Martinez", "R Martinez", "St George", "Hines_Caldwell", "Gregory_Lincoln",


#Finished "Attucks", "Black", "Burbank", "Clifton", "Cullen", "Deady", "Dowling", "Edison", "Fleming", "Fondren", "Fonville",
# "Forest Brook", "Grady", "Hamilton", "Hartman", "Henry", "Hogg", "Holland", "Jackson", "Johnston",
# "Key", "Lanier", "Long", "Marshall", "McReynolds", "Ortiz", "Pershing", "Revere", "Stevenson", "Sugar Grove", "Thomas",
# "Welch", "West Briar", "Williams", "Woodson", "Reagan"

#Needs Work  "Gregory-Lincoln",

schools_m=[ ]

#FINISHED "Austin", "Bellaire", "Chavez", "Davis", "Furr", "Houston", "Kashmere", "Lamar", "Lee", "Madison", "Milby", "North Forest",
#"Reagan", "Scarborough", "Sharpstown", "Sterling", "Waltrip", "Washington", "Westbury", "Westside", "Wheatley", "Worthing", "Yates"

schools_h=[]

subfolders=["Shapefiles", "Output"]

for folder in schools_e:
    #os.mkdir(os.path.join(root_path_e,folder))
    for subfolder in subfolders:  
        root_path_new=root_path_e + "\\" + folder
    #    os.mkdir(os.path.join(root_path_new, subfolder))

for folder in schools_m:
    #os.mkdir(os.path.join(root_path_m,folder))
    for subfolder in subfolders:  
        root_path_new=root_path_m + "\\" + folder
    #    os.mkdir(os.path.join(root_path_new, subfolder))

for folder in schools_h:
    #os.mkdir(os.path.join(root_path_h,folder))
    for subfolder in subfolders:  
        root_path_new=root_path_h + "\\" + folder
    #    os.mkdir(os.path.join(root_path_new, subfolder))

######## BEGIN MAPPING ############

print "******** Begin Creating Maps ********"

#Define Workspace for Neccessary Files
elm_attend=path + "Shapefiles\\attend_elem_1617.shp"
mid_attend=path + "Shapefiles\\attend_middle_1617.shp"
high_attend=path + "Shapefiles\\attend_high_1617.shp"

####Attach School Attendence Boundaries to Points Then Merge in R to Parcels####
print "Attach School Boundary Information to Parcels"
points_elm= path + "Shapefiles\points_elm.shp"
points_mid= path + "Shapefiles\points_mid.shp"
points_high= path + "Shapefiles\points_high.shp"

#arcpy.SpatialJoin_analysis(Stu_Points_Complete, elm_attend, points_elm, "JOIN_ONE_TO_ONE", "KEEP_ALL", "#", "INTERSECT")
#arcpy.SpatialJoin_analysis(Stu_Points_Complete, mid_attend, points_mid, "JOIN_ONE_TO_ONE", "KEEP_ALL", "#", "INTERSECT")
#arcpy.SpatialJoin_analysis(Stu_Points_Complete, high_attend, points_high, "JOIN_ONE_TO_ONE", "KEEP_ALL", "#", "INTERSECT")

#Run R Code to Match Student's Attendance School to Zoned  School then use maskedid to attach to Student Parcel Information
print "Run Match_Zone_Enrol.R"
script_finalgeo= rpath + "Match_Zone_Enroll.R"
#process= subprocess.call([script_path, script_finalgeo], shell=True)

print "Begin Map Creation Loop - Elementary"
for name in schools_e:
    #Shapefiles
    #Shapefiles Already in MXD - "Apartments, Parcel_Damage_Assessments, Facilities_1617, Parcels_2017_Rev
    temp_bound= root_path_e + "\\" + name + "\Shapefiles\temp_bound.lyr"
    school_boundary=root_path_e + "\\" + name + "\Shapefiles\\" + name + "_Boundary.shp"
    school= path + "Shapefiles\\facilities_1617.shp"
    stu_parcels_type= path + "Shapefiles\\Stu_Parcel_elm.shp"

    #Templates
    parcel_flood_temp= path + "Templates\Parcel_Flood_Damage_Template.lyr"
    boundary_fill_temp= path + "Templates\School_Boundary_Fill_Template.lyr"
    boundary_outline_temp= path + "Templates\School_Boundary_Outline_Template.lyr"
    stu_parcels_type_temp= path + "Templates\Stu_Parcels_Template.lyr"

    # MXD Template #                        
    mxd = arcpy.mapping.MapDocument(path + "Creating_Maps.mxd")
    data_frame = arcpy.mapping.ListDataFrames(mxd)[0]
    #Switch to data view  
    mxd.activeView = data_frame.name

#First Create New Shapefile for each school by selection
    query = "\"Facility\"= '"+ str(name) + "'"
    arcpy.MakeFeatureLayer_management(elm_attend, temp_bound)    #First Make Temp Layer to Select Features
    arcpy.SelectLayerByAttribute_management(temp_bound, "", query) #Then Select Features
    arcpy.CopyFeatures_management(temp_bound, school_boundary)    #Finally Save New Feature Class

#Then Bring in Shapefiles - First Create Temporary Layer and then Add it to Map Using 'AddLayer'
    #Load School Boundary Twice - One for Outline Other for Background
    Layer_SB_fill=arcpy.mapping.Layer(school_boundary) 
    arcpy.ApplySymbologyFromLayer_management(Layer_SB_fill, boundary_fill_temp) #Apply Template Symbology for School Boundary
    #Zoom To Extent of Newly Added Data
    ext=Layer_SB_fill.getExtent()
    data_frame.extent=ext
    #Add School Boundary - Fill
    arcpy.mapping.AddLayer(data_frame, Layer_SB_fill, "BOTTOM")

    #Add School Type Map
    Layer_Stu_Parcels_Type=arcpy.mapping.Layer(stu_parcels_type)
    arcpy.ApplySymbologyFromLayer_management(Layer_Stu_Parcels_Type, stu_parcels_type_temp)   #Apply Template for Parcels
    arcpy.mapping.AddLayer(data_frame, Layer_Stu_Parcels_Type, "TOP")     #Add Parcel layer After Preparing
    
    #Finally Add Second School Boundary for Outline
    Layer_SB_outline=arcpy.mapping.Layer(school_boundary) 
    arcpy.ApplySymbologyFromLayer_management(Layer_SB_outline, boundary_outline_temp) #Apply Template Symbology for School Boundary
    arcpy.mapping.AddLayer(data_frame, Layer_SB_outline, "TOP")

    #Add Title to Map
    for elm2 in arcpy.mapping.ListLayoutElements(mxd, "TEXT_ELEMENT"):
            if elm2.text == "Title": # whatever your text element is named here
                elm2.text = "Damaged Homes in " + name + " Attendance Zone"
                break

#Create PDF
    print "Writing PDF for: " + name
    arcpy.mapping.ExportToPDF(mxd, root_path_e + "\\" + name + "\Output\\" + name + "_Flood_Map_secure.pdf",resolution="300",image_quality="BEST",layers_attributes="LAYERS_ONLY") #Place in Individual School Folder
    pdfPath=root_path_e + "\\" + name + "\Output\\" + name + "_Flood_Map_secure.pdf"
    #pw="herc_" + str(name)
    pw="herchisd"
    pdfDoc = arcpy.mapping.PDFDocumentOpen(pdfPath)
    pdfDoc.updateDocSecurity(pw, pw, "RC4", "OPEN")
    pdfDoc.saveAndClose()
    del pdfDoc
    
    arcpy.mapping.ExportToPDF(mxd, path + "Output\Elementary_Schools\\" + name + "_Flood_Map_secure.pdf",resolution="300",image_quality="BEST",layers_attributes="LAYERS_ONLY") #Place in Output Folder
    pdfPath=path + "Output\Elementary_Schools\\" + name + "_Flood_Map_secure.pdf"
    #pw="herc_" + str(name)
    pw="herchisd"
    pdfDoc = arcpy.mapping.PDFDocumentOpen(pdfPath)
    pdfDoc.updateDocSecurity(pw, pw, "RC4", "OPEN")
    pdfDoc.saveAndClose()
    del pdfDoc

#Save MXD File For Each School
    mxd.saveACopy(root_path_e + "\\" + name + "\Output\\" + name + "_Flood_Map.mxd")
       
    print "Finished " + name

print "Finished All Elementary Schools"


print "Begin Map Creation Loop - Middle"
for name in schools_m:
    #Shapefiles
    #Shapefiles Already in MXD - "Apartments, Parcel_Damage_Assessments, Facilities_1617, Parcels_2017_Rev
    temp_bound= root_path_m + "\\" + name + "\Shapefiles\temp_bound.lyr"
    school_boundary=root_path_m + "\\" + name + "\Shapefiles\\" + name + "_Boundary.shp"
    school= path + "Shapefiles\\facilities_1617.shp"
    stu_parcels_type= path + "Shapefiles\\Stu_Parcel_mid.shp"

    #Templates
    parcel_flood_temp= path + "Templates\Parcel_Flood_Damage_Template.lyr"
    boundary_fill_temp= path + "Templates\School_Boundary_Fill_Template.lyr"
    boundary_outline_temp= path + "Templates\School_Boundary_Outline_Template.lyr"
    stu_parcels_type_temp= path + "Templates\Stu_Parcels_Template_mid.lyr"

    # MXD Template #                        
    mxd = arcpy.mapping.MapDocument(path + "Creating_Maps_middle.mxd")
    data_frame = arcpy.mapping.ListDataFrames(mxd)[0]
    #Switch to data view  
    mxd.activeView = data_frame.name

#First Create New Shapefile for each school by selection
    query = "\"Facility\"= '"+ str(name) + "'"
    arcpy.MakeFeatureLayer_management(mid_attend, temp_bound)    #First Make Temp Layer to Select Features
    arcpy.SelectLayerByAttribute_management(temp_bound, "", query) #Then Select Features
    arcpy.CopyFeatures_management(temp_bound, school_boundary)    #Finally Save New Feature Class

#Then Bring in Shapefiles - First Create Temporary Layer and then Add it to Map Using 'AddLayer'
    #Load School Boundary Twice - One for Outline Other for Background
    Layer_SB_fill=arcpy.mapping.Layer(school_boundary) 
    arcpy.ApplySymbologyFromLayer_management(Layer_SB_fill, boundary_fill_temp) #Apply Template Symbology for School Boundary
    #Zoom To Extent of Newly Added Data
    ext=Layer_SB_fill.getExtent()
    data_frame.extent=ext
    #Add School Boundary - Fill
    arcpy.mapping.AddLayer(data_frame, Layer_SB_fill, "BOTTOM")

    #Add School Type Map
    Layer_Stu_Parcels_Type=arcpy.mapping.Layer(stu_parcels_type)
    arcpy.ApplySymbologyFromLayer_management(Layer_Stu_Parcels_Type, stu_parcels_type_temp)   #Apply Template for Parcels
    arcpy.mapping.AddLayer(data_frame, Layer_Stu_Parcels_Type, "TOP")     #Add Parcel layer After Preparing
    
    #Finally Add Second School Boundary for Outline
    Layer_SB_outline=arcpy.mapping.Layer(school_boundary) 
    arcpy.ApplySymbologyFromLayer_management(Layer_SB_outline, boundary_outline_temp) #Apply Template Symbology for School Boundary
    arcpy.mapping.AddLayer(data_frame, Layer_SB_outline, "TOP")

    #Add Title to Map
    for elm2 in arcpy.mapping.ListLayoutElements(mxd, "TEXT_ELEMENT"):
            if elm2.text == "Title": # whatever your text element is named here
                elm2.text = "Damaged Homes in " + name + " Attendance Zone"
                break

#Create PDF
    print "Writing PDF for: " + name
    arcpy.mapping.ExportToPDF(mxd, root_path_m + "\\" + name + "\Output\\" + name + "_Flood_Map_secure.pdf",resolution="300",image_quality="BEST",layers_attributes="LAYERS_ONLY") #Place in Individual School Folder
    pdfPath=root_path_m + "\\" + name + "\Output\\" + name + "_Flood_Map_secure.pdf"
    #pw="herc_" + str(name)
    pw="herchisd"
    pdfDoc = arcpy.mapping.PDFDocumentOpen(pdfPath)
    pdfDoc.updateDocSecurity(pw, pw, "RC4", "OPEN")
    pdfDoc.saveAndClose()
    del pdfDoc
    
    arcpy.mapping.ExportToPDF(mxd, path + "Output\Middle_Schools\\" + name + "_Flood_Map_secure.pdf",resolution="300",image_quality="BEST",layers_attributes="LAYERS_ONLY") #Place in Output Folder
    pdfPath=path + "Output\Middle_Schools\\" + name + "_Flood_Map_secure.pdf"
    #pw="herc_" + str(name)
    pw="herchisd"
    pdfDoc = arcpy.mapping.PDFDocumentOpen(pdfPath)
    pdfDoc.updateDocSecurity(pw, pw, "RC4", "OPEN")
    pdfDoc.saveAndClose()
    del pdfDoc

#Save MXD File For Each School
    mxd.saveACopy(root_path_m + "\\" + name + "\Output\\" + name + "_Flood_Map.mxd")
       
    print "Finished " + name

print "Finished All Middle Schools"


print "Begin Map Creation Loop - High School"
for name in schools_h:
    #Shapefiles
    #Shapefiles Already in MXD - "Apartments, Parcel_Damage_Assessments, Facilities_1617, Parcels_2017_Rev
    temp_bound= root_path_h + "\\" + name + "\Shapefiles\temp_bound.lyr"
    school_boundary=root_path_h + "\\" + name + "\Shapefiles\\" + name + "_Boundary.shp"
    school= path + "Shapefiles\\facilities_1617.shp"
    stu_parcels_type= path + "Shapefiles\\Stu_Parcel_high.shp"

    #Templates
    parcel_flood_temp= path + "Templates\Parcel_Flood_Damage_Template.lyr"
    boundary_fill_temp= path + "Templates\School_Boundary_Fill_Template.lyr"
    boundary_outline_temp= path + "Templates\School_Boundary_Outline_Template.lyr"
    stu_parcels_type_temp= path + "Templates\Stu_Parcels_Template_mid.lyr"

    # MXD Template #                        
    mxd = arcpy.mapping.MapDocument(path + "Creating_Maps_middle.mxd")
    data_frame = arcpy.mapping.ListDataFrames(mxd)[0]
    #Switch to data view  
    mxd.activeView = data_frame.name

#First Create New Shapefile for each school by selection
    query = "\"Facility\"= '"+ str(name) + "'"
    arcpy.MakeFeatureLayer_management(high_attend, temp_bound)    #First Make Temp Layer to Select Features
    arcpy.SelectLayerByAttribute_management(temp_bound, "", query) #Then Select Features
    arcpy.CopyFeatures_management(temp_bound, school_boundary)    #Finally Save New Feature Class

#Then Bring in Shapefiles - First Create Temporary Layer and then Add it to Map Using 'AddLayer'
    #Load School Boundary Twice - One for Outline Other for Background
    Layer_SB_fill=arcpy.mapping.Layer(school_boundary) 
    arcpy.ApplySymbologyFromLayer_management(Layer_SB_fill, boundary_fill_temp) #Apply Template Symbology for School Boundary
    #Zoom To Extent of Newly Added Data
    ext=Layer_SB_fill.getExtent()
    data_frame.extent=ext
    #Add School Boundary - Fill
    arcpy.mapping.AddLayer(data_frame, Layer_SB_fill, "BOTTOM")

    #Add School Type Map
    Layer_Stu_Parcels_Type=arcpy.mapping.Layer(stu_parcels_type)
    arcpy.ApplySymbologyFromLayer_management(Layer_Stu_Parcels_Type, stu_parcels_type_temp)   #Apply Template for Parcels
    arcpy.mapping.AddLayer(data_frame, Layer_Stu_Parcels_Type, "TOP")     #Add Parcel layer After Preparing
    
    #Finally Add Second School Boundary for Outline
    Layer_SB_outline=arcpy.mapping.Layer(school_boundary) 
    arcpy.ApplySymbologyFromLayer_management(Layer_SB_outline, boundary_outline_temp) #Apply Template Symbology for School Boundary
    arcpy.mapping.AddLayer(data_frame, Layer_SB_outline, "TOP")

    #Add Title to Map
    for elm2 in arcpy.mapping.ListLayoutElements(mxd, "TEXT_ELEMENT"):
            if elm2.text == "Title": # whatever your text element is named here
                elm2.text = "Damaged Homes in " + name + " Attendance Zone"
                break

#Create PDF
    print "Writing PDF for: " + name
    arcpy.mapping.ExportToPDF(mxd, root_path_h + "\\" + name + "\Output\\" + name + "_Flood_Map_secure.pdf",resolution="300",image_quality="BEST",layers_attributes="LAYERS_ONLY") #Place in Individual School Folder
    pdfPath=root_path_h + "\\" + name + "\Output\\" + name + "_Flood_Map_secure.pdf"
    #pw="herc_" + str(name)
    pw="herchisd"
    pdfDoc = arcpy.mapping.PDFDocumentOpen(pdfPath)
    pdfDoc.updateDocSecurity(pw, pw, "RC4", "OPEN")
    pdfDoc.saveAndClose()
    del pdfDoc
    
    arcpy.mapping.ExportToPDF(mxd, path + "Output\High_Schools\\" + name + "_Flood_Map_secure.pdf",resolution="300",image_quality="BEST",layers_attributes="LAYERS_ONLY") #Place in Output Folder
    pdfPath=path + "Output\High_Schools\\" + name + "_Flood_Map_secure.pdf"
    #pw="herc_" + str(name)
    pw="herchisd"
    pdfDoc = arcpy.mapping.PDFDocumentOpen(pdfPath)
    pdfDoc.updateDocSecurity(pw, pw, "RC4", "OPEN")
    pdfDoc.saveAndClose()
    del pdfDoc

#Save MXD File For Each School
    mxd.saveACopy(root_path_h + "\\" + name + "\Output\\" + name + "_Flood_Map.mxd")
       
    print "Finished " + name

print "Finished All High Schools"

