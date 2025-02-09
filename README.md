https://www.curseforge.com/wow/addons/craftlogger

CraftLogger is an AddOn that interfaces with World of Warcraft and the CraftSim AddOn. It collects crafting data and allows for export into a CSV file. The global commands that can be run are as follows:
* /run CLExport() \
Generates copyable CSV text from the database. Copy and paste this into a text file, save as .csv, then open with Excel or similar.
* /run CLRestoreSession() \
Restores the database to its state after the latest reload or login.
* /run CLUndo() \
After manipulating the database (except for restoresession), allows for one undo only.
* /run CLClear() \
Clears the database of all data.
* /run CLClearByDate(date1, date2) \
date2 is an optional argument. Dates are in the string form: "MM/DD/YY HH:mm:SS", where hours are in 24hr time. Clears all data after date1, or between date1 and date2.
* /run CLRemoveLast() \
Clears the most recent entry in the database. Can be repeated.
* /run CLClean() \
Removes extra data unneeded by the database. Likely unnecessary to use.
* /run CLDisable() \
Disables the Log function.
* /run CLEnable() \
Enables the Log function.
* /run CLRemoveRows(firstrow, rowtable) \
firstrow is the first row that value data (not column headers) appears in whatever table you are referencing. Rowtable is in the form {num, num, ..., num}, which are the rows of the table to remove. This removes these rows from the database and reindexes it, so please regenerate your table before reusing.
* /run CLFilter(valremovefunc, field1, field2) \
This is an advanced function for those who know Lua. Put a lua function as the first argument, which takes a value given by field1 and field2, and which will return true if the entry should be removed. Field1 is the name of a property of the CraftOutput class to evaluate, and field2 is an optional argument to nest further into the class. CraftLogger will remove all rows that evaluate to true with this criteria.
