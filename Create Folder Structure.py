#Python 2.7.8 (default, Jun 30 2014, 16:08:48) [MSC v.1500 64 bit (AMD64)] on win32
#Type "copyright", "credits" or "license()" for more information.

import os
import sys

#Elementary Schools - 'attend_elem_1516'
# "Alcott", "Askew", "Barrick", "Benbrook", "Berry", "Blackshear", "Bonham", "Bonner", "Briargrove", "Brookline",
# "Browning", "Burbank", "Burrus", "Bush", "Carrillo", "Condit", "Coop", "Cornelius", "Crespo", "Davila", "DeChaumes",
# "De Zavala", "Dogan", "Durham", "Durkee", "Eliot", "Elrod", "Emerson", "Field", "Foerster", "Foster", "Franklin",
# "Gallegos", "Garcia", "Garden Oaks", "Garden Villas", "Golfcrest", "Gregg", "Harris JR", "Harris RP", "Hartsfield",
# "Harvard", "Helms", "Henderson JP", "Henderson NQ", "Herrera", "Horn", "McGowen", "Isaacs", "Janowski", "Jefferson",
# "Kashmere Gardens", "Kelso", "Kennedy", "Lantrip", "Lewis/Belfort Academy", "Lockhart", "Longfellow", "Looscan",
# "Love", "Lyons", "MacGregor", "Mading", "Martinze C", "Martinez R", "McNamara", "Memorial", "Milne", "Northline",
# "Oak Forest", "Oates", "Paige", "Park Place", "Patterson", "Petersen", "Piney Point", "Pleasantville", "Port Houston",
# "Pugh", "River Oaks", "Roosevelt", "Ross", "Rucker", "Rusk", "Sanchez", "Cook", "Scarborough", "Scroggins", "Ashford",
# "Sinclair", "Smith", "Southmayd", "Stevens", "Thompson", "Tijerina", "Tinsley", "Travis", "Twain", "Valley West",
# "Wainwright", "Walnut Bend", "West University", "Whidby", "Neff", "Whittier", "Windsor Village", "Young", "Robinson",
# "Seguin", "Ketelsen", "Cage", "Highland Heights", "Osborne", "Wesley", "Daily", "Moreno JE", "St. George", "Pilgrim",
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

root_path=r'K:\Curation\HISD\Education\Tabular\Student\Schools\Elementary'
folders= ["Alcott", "Askew", "Barrick"]
subfolders=["Shapefiles", "Misc"]

for folder in folders:
    os.mkdir(os.path.join(root_path,folder))
    for subfolder in subfolders:  
        root_path_new=root_path + "\\" + folder
        print root_path_new
        os.mkdir(os.path.join(root_path_new, subfolder))
