#Python 2.7.8 (default, Jun 30 2014, 16:08:48) [MSC v.1500 64 bit (AMD64)] on win32
#Type "copyright", "credits" or "license()" for more information.

import arcpy
import os
import sys
import subprocess
import csv

# overwrite output
arcpy.env.overwriteOutput=True
#Define Workspace
path="K:\Projects\p011_HISD_Requests\Hurricane_Harvey_Maps\\"
rpath= r'K:/Projects/p011_HISD_Requests/Hurricane_Harvey_Maps/Shapefiles/Checking_Geocode_Loop/'
script_path= 'C:/Program Files/R/R-3.3.3/bin/Rscript'
results= "Shapefiles\Checking_Geocode_Loop\\Results_60518.gdb"
dbf= path + "Shapefiles\Checking_Geocode_Loop\DBF\\"

#Run R Script to Get Address File to be Geocoded
print "Running Apartment_Indicator.R"
script_apt_indicator= rpath + "Apartment_Indicator.R"
process= subprocess.call([script_path, script_apt_indicator], shell=True)

#Bring in Neccessary Files for Geocode from R Procedure
Addresses= path + "\Stu_Add_EOY_1617_r.csv"    #Student Addresses
Orig_Parcel_Table = path + "\Shapefiles\Parcels_2017_Rev.shp 'Primary Table'"   #Parcel Shapefile for Locator
Orig_Parcel = path + "\Shapefiles\Parcels_2017_Rev.shp"   #Parcel Shapefile
add_locator= path + "\Locators\Stu_AddLoc_Parcel_rev"    #Where Address Locator will be Placed
address_fields= "Street Student_Address; City Student_City; State <None>; ZIP Student_Zip_Code" #Names from the Student File
Stu_Points_int= path + results + "\Stu_Points_1"
print Stu_Points_int

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
arcpy.GeocodeAddresses_geocoding(Addresses, add_locator, address_fields, Stu_Points_int)

#Output to DBF for Analysis in R
print "Converting to DBF"
arcpy.TableToDBASE_conversion([Stu_Points_int], dbf)

#Run R Script to Get Unmatched Count
print "Running Initial_Geocode.R"
script_secondgeo= rpath + "Initial_Geocode.R"
process= subprocess.call([script_path, script_secondgeo], shell=True)

print "Finished Geocode 1"

#Start Your count and count_f values as not equal. The script will update when necessary. The count originates
#from the initial geocode. Start iteration at 2 since the initial geocode is considered iteration 1.
iteration=2
count = 2
count_f = 1
while (count != count_f):
   iteration_string=str (iteration)
   iteration_prev_string=str(iteration - 1)

   with open(path + 'Shapefiles\Checking_Geocode_Loop\Iteration_Files\Unmatched_' + iteration_prev_string + '.csv', 'rb') as first:
      reader = csv.reader(first)
      for row in reader:
        count=row[1]

   print 'Iteration',iteration, 'of Geocoding Loop'
   print 'Begin Iteration with' , count, 'Unmatched'
   with open(path + 'Shapefiles\Checking_Geocode_Loop\Iteration_Files\Iteration_num.csv', 'w') as csvfile:
    fieldnames = ['count']
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerow({'count': iteration})

   #Geocode Addresses from Previous Iteration Step to Parcel Data
   print "Working on Geocoding", iteration
   #Bring in Neccessary Files for Geocode from R Procedure
   Addresses_iter= path + "Shapefiles\Checking_Geocode_Loop\Iteration_Files\\Address_Iteration_" + iteration_prev_string + ".csv"    #Student Addresses
   address_fields_iter= "Street new_stuadd; City Student_Ci; State <None>; ZIP Student_Zi" #Names from the Student File
   Stu_Points_iter= path + results + "\Stu_Points_" + iteration_string
   arcpy.GeocodeAddresses_geocoding(Addresses_iter, add_locator, address_fields_iter, Stu_Points_iter)

   #Output to DBF for Analysis in R
   arcpy.TableToDBASE_conversion([Stu_Points_iter], dbf)

   #Create New File to Be Geocoded and Record Improvement
   script_geo_iter= rpath + "Geocode_Iterations.R"
   process= subprocess.call([script_path, script_geo_iter], shell=True)

   print "Finished Geocode Iteration:", iteration
   Stu_Points_iter_prev= path + results + "\Stu_Points_" + iteration_prev_string

   with open(path + 'Shapefiles\Checking_Geocode_Loop\Iteration_Files\Unmatched_' + iteration_string + '.csv', 'rb') as first:
      reader = csv.reader(first)
      for row in reader:
        count_f=row[1]

   print 'Finished Iteration with', count_f, 'Unmatched'
   print " "
   
   iteration = iteration + 1
