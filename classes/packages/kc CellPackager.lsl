/*
Cell Save: Packager

	
*/

#define USE_SHARED ["config", "mis"]
#include "../../_core.lsl"

#define CellPackager$NotecardName "IGNORE ME"
#define CellPackager$NotecardNameLength 8

integer BFL;
#define BFL_PROCESSING 0x1
#define BFL_FOLDER 0x2
#define BFL_RUNNING 0x4
#define BFL_DONE 0x8

// Config
#define int_MaxCycles 100000

// Main
string str_CellName;
integer int_NumObjects;
string str_FolderName;

// Stats and processing
integer int_StartTime;
integer int_ObjNum;
integer int_Processing;
kcCBSimple$vars;

// Scratch
string str_ObjectName;

KCbucket$varsDB( namecache );
KCbucket$varsDB( idcache );

KCbucket$varsRead( namecache );
KCbucket$varsRead( idcache );

//Cell_package_(ext_test)_2015-10-22T06:15:15.712069Z
#define _getTempFolderName() ("Cell_package_(" + str_CellName + ")_" + llGetSubString(llGetTimestamp(), 0, 15))

#define _setProgress( str_Text ) llSetText( str_Text, ZERO_VECTOR, 1 )

default 
{
	state_entry() {
		mem_usage();
		_setProgress("");
		DB2$ini();		
		KCbucket$initDB( namecache, "ND", FALSE );
		KCbucket$initDB( idcache, "ID", FALSE );
	}
	
	#include "xobj_core/_LM.lsl" 
	if(method$isCallback) {return;}
	
	if(method$byOwner) {
		if(METHOD == KCCellPackagerMethod$giveFolder) {
			debugUncommon("KCCellPackagerMethod$giveFolder");
			if(!(BFL&BFL_PROCESSING)) {
				
				// Cell info
				str_CellName = KCCell$getCellName();
				int_NumObjects = KCCell$getNumObjs();
				
				// Only run if there is something to do
				if (str_CellName != "" && int_NumObjects > 0) {
					
					debugUncommon("=Starting packaging for CellName: " + str_CellName + ", objs: " + (string)int_NumObjects);
					
					BFL = BFL_PROCESSING;
					
					llScriptProfiler(PROFILE_SCRIPT_MEMORY);
					int_StartTime = llGetUnixTime();
					
					str_FolderName = _getTempFolderName();
					
					llGiveInventoryList( llGetOwner(), str_FolderName, [CellPackager$NotecardName] );
					
					_setProgress( "Waiting for folder" );
					
					CB_DATA = [TRUE];
				}
				else {
					CB_DATA = [FALSE, "NOWORK"];
				}
			}
			else {
				CB_DATA = [FALSE, "BUSY"];
			}
		}
		else if(METHOD == KCCellPackagerMethod$start) {
			debugUncommon("KCCellPackagerMethod$start");
			if((BFL&BFL_PROCESSING) && !(BFL&BFL_FOLDER)) {
				BFL = BFL|BFL_FOLDER;
				
				string str_Cmd = "kpackagerstart " + (string)llGetKey() + " " + str_FolderName;
				
				llOwnerSay("Say the following line in local chat then press OK:\n" + str_Cmd);
				
				CB_DATA = [TRUE, str_Cmd];
			}
			else {
				CB_DATA = [FALSE, "WRONG STATE"];
			}
		}
		else if(METHOD == KCCellPackagerMethod$run) {
			debugUncommon("KCCellPackagerMethod$run");
			if((BFL&BFL_PROCESSING) && (BFL&BFL_FOLDER) && !(BFL&BFL_RUNNING)) {
				BFL = BFL|BFL_RUNNING;
				
				debugUncommon("Clearing out previous objects.");
				string str_ObjName;
				integer int_ObjType;
				integer int_Objs = llGetInventoryNumber(INVENTORY_ALL);
				while (int_Objs)
				{
					--int_Objs;
					str_ObjName = llGetInventoryName(INVENTORY_ALL, int_Objs);
					int_ObjType = llGetInventoryType(str_ObjName);
					// Remove all objects
					if (INVENTORY_OBJECT == int_ObjType) {
						debugUncommon("Removing object: " + str_ObjName);
						llRemoveInventory(str_ObjName);
					}
					else if (INVENTORY_NOTECARD == int_ObjType) {
						if ((str_ObjName != CellPackager$NotecardName) && (llGetSubString(str_ObjName, 0, CellPackager$NotecardNameLength) == CellPackager$NotecardName)) {
							debugUncommon("Removing notecard: " + str_ObjName);
							llRemoveInventory(str_ObjName);
						}
					}
				}
				
				integer int_Processing;
				string str_UUID;
				string str_Cmd;
				
				KCbucket$readSeek( idcache, 0 );
				KCbucket$readAll( idcache, str_UUID, int_Processing, ,
					debugUncommon("Adding to list: " + str_UUID);
					int_Objs++;
					if (str_Cmd == "") {
						str_Cmd = "kpackageradd " + str_UUID;
					}
					else {
						str_Cmd += "," + str_UUID;
						if (int_Objs >= 25) {
							// llOwnerSay("cmd: " + str_Cmd);
							llOwnerSay(str_Cmd);
							str_Cmd = "";
							int_Objs = 0;
							llSleep(2);
						}
					}
				);
				
				if (str_Cmd != "") {
					// llOwnerSay("cmd: " + str_Cmd);
					llOwnerSay(str_Cmd);
					str_Cmd = "";
					llSleep(2);
				}
				
				
				debugUncommon("Finished.");
				llOwnerSay("kpackagerend");
				llSleep(2);
				
				CB_DATA = [TRUE];
			}
			else {
				CB_DATA = [FALSE, "WRONG STATE"];
			}
		}
		
		else if(METHOD == KCCellPackagerMethod$end) {
			debugUncommon("KCCellPackagerMethod$end");
			if((BFL&BFL_PROCESSING) && (BFL&BFL_FOLDER) && (BFL&BFL_RUNNING) && !(BFL&BFL_DONE)) {
				BFL = BFL|BFL_DONE;
				
				llOwnerSay("Checking objects.");
				
				integer int_Processing;
				string str_ObjName;
				integer int_Objs;
				integer int_Found;
				integer int_MissingObjs = FALSE;
				KCbucket$readSeek( namecache, 0 );
				KCbucket$readAll( namecache, str_ObjName, int_Processing, ,
					int_Found = FALSE;
					int_Objs = llGetInventoryNumber(INVENTORY_ALL);
					while (int_Objs)
					{
						--int_Objs;
						if (llGetInventoryName(INVENTORY_OBJECT, int_Objs) == str_ObjName) {
							debugUncommon("Found object: " + str_ObjName);
							int_Found = TRUE;
							int_Objs = 0;
						}
					}
					if (!int_Found) {
						int_MissingObjs = TRUE;
						llOwnerSay("WARNING: Object missing from package: " + str_ObjName);
					}
					
				);
				
				if (int_MissingObjs) {
					llOwnerSay("WARNING: There are object missing from this package. This will cause problems.");
					CB_DATA = [FALSE, "MISSING OBJECTS"];
				}
				else {
					llOwnerSay("Finished. All objects packaged.");
					CB_DATA = [TRUE, "All objects added to package."];
				}
				
				// Clear state
				BFL = 0;
			}
			else {
				CB_DATA = [FALSE, "WRONG STATE"];
			}
		}
		
	}
	
	#define LM_BOTTOM  
	#include "xobj_core/_LM.lsl"  
}
