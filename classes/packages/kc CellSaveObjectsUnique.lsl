/*
Cell Save: Indexer

	Basic theory of operation of this is to take the following stored info from the cache:
	[obj_name+obj_UUID+obj_pos+obj_rot;obj_extra_data;obj2_name+obj2_UUID+obj2_pos+obj2_rot;obj2_extra_data;...]
	And, without memory limitations, split the info in to these:
	[obj_name_index+obj_pos+obj_rot;obj_extra_data;obj_name_index+obj2_pos+obj2_rot;obj2_extra_data;...]
	[obj_name;obj2_name;...]
	[obj_UUID;obj2_UUID;...]
	Where the last 2 contain no duplicates and the first has objects of the same name are stored constructively.
	
	TODO: Possibly dump the obj_name_index and store the name in the main serialized stream as a section header.
	eg. [obj_name;pos+rot;extra_data;pos+rot;extra_data;obj2_name;pos+rot;extra_data;...]
	
	This is a long amount of script time here, but the size of the saved cell should not be limit here
	Time to process will be somewhat geometric...
*/

#define USE_SHARED ["config", "mis"]
#include "../../_core.lsl"


integer BFL;
#define BFL_INDEXING 0x1
#define BFL_DONE 0x2

// Config
#define int_MaxCycles 100000

// Main
string str_CellName;
integer int_InputDataLength;
integer int_NumObjects;

// Stats and processing
integer int_Cycles;
integer int_StartTime;
integer int_ObjNum;
integer int_UniqueObjNum;
integer int_Processing;

// Scratch
string str_ObjectClass;
string str_ObjectName;
list lst_ObjData;
string str_Data;
string str_LastObjName;
integer int_Searching;
integer int_IsUnique;

KCbucket$varsDB( objcache );
KCbucket$varsDB( namecache );
KCbucket$varsDB( idcache );

KCbucket$varsRead( objcache );
KCbucket$varsRead( namecache );

KCbucket$varsWrite( namecache );
KCbucket$varsWrite( idcache );


#define _setProgress( str_Text ) llSetText( str_Text, ZERO_VECTOR, 1 )

default 
{
    state_entry() {
		mem_usage();
		DB2$ini();
    }
    
    #include "xobj_core/_LM.lsl" 
	if(method$isCallback) {return;}
    
    if(method$byOwner) {
        
        if(METHOD == KCCellSaveObjectsUniqueMethod$buildUniquesList) {
			if(!(BFL&BFL_INDEXING)) {
				
				// Get cell info
				str_CellName = KCCell$getCellName();
				int_NumObjects = KCCell$getNumObjs();
				int_InputDataLength = KCCell$getCellDataLength();
				
				// Only run if there is something to do
				if (str_CellName != "" && int_InputDataLength > 0 && int_NumObjects > 0) {
					debugUncommon("Finding unique objects for CellName: " + str_CellName + ", objs: " + (string)int_NumObjects + ", input data length: " + (string)int_InputDataLength);
					
					BFL = BFL_INDEXING;
					llScriptProfiler(PROFILE_SCRIPT_MEMORY);
					
					int_StartTime = llGetUnixTime();
					
					//Reset all variables
					int_Cycles = 0;
					str_LastObjName = "";
					KCbucket$readSeek( objcache, 0 );
					KCbucket$readSeek( namecache, 0 );
					KCbucket$writeSeek( namecache, 0 );
					KCbucket$writeSeek( idcache, 0 );
					
					KCbucket$initDB( objcache, "CD", FALSE );
					KCbucket$initDB( namecache, "ND", TRUE );
					KCbucket$initDB( idcache, "ID", TRUE );
					
					// Find unique objects by name
					int_Processing = TRUE;
					do {
						int_Cycles++;
						KCbucket$readNext( objcache, str_Data )
						if (str_Data == "EOF") {
							int_Processing = FALSE;
						}
						else {
							lst_ObjData = llJson2List(str_Data);
							str_ObjectClass	= llList2String( lst_ObjData, 0 );
							if (str_ObjectClass == "OBJ") {
								int_ObjNum++;
								str_ObjectName 	= llList2String( lst_ObjData, 1 );
								if (str_ObjectName != str_LastObjName) {
									int_IsUnique = TRUE;
									KCbucket$readSeek( namecache, 0 );
									KCbucket$readAllOpen( namecache, str_Data, int_Searching, ,
										int_Cycles++;
										if (str_ObjectName == str_Data) {
											int_IsUnique = FALSE;
											int_Searching = FALSE;
										}
									);
									if (int_IsUnique) {
										str_LastObjName = str_ObjectName;
										KCbucket$write( namecache, str_ObjectName );
										KCbucket$write( idcache, llList2String(lst_ObjData, 2) );
										int_UniqueObjNum++;
									}
								}
							}
							// Update progress text every 4 steps
							if ((int_ObjNum % 4) == 0) {
								_setProgress(
									// Tick arrow spin once every 4 steps (8*4=32)
									KCLib$progressArrowSpin( int_ObjNum, 32 ) +
									" Processing uniques " +
									KCLib$progressPie( ((float)int_ObjNum / (float)int_NumObjects) ) + "\n" +
									(string)int_UniqueObjNum + " unique objects found\n \n "
								);
							}
						}
					} while(int_Processing && int_Cycles < int_MaxCycles);
					
					_setProgress( (string)int_UniqueObjNum + " unique objects found\n" );
					
					llOwnerSay("Unique Objects:");
					KCbucket$readAll( namecache, str_Data, int_Processing, , llOwnerSay(str_Data));
					
					llScriptProfiler(PROFILE_NONE);
					debugUncommon(
						"Runtime: " + (string)(llGetUnixTime() - int_StartTime) + " seconds." +
						" Cycles: " + (string)int_Cycles +
						"\nMax mem: " + (string)llGetSPMaxMemory() + " bytes" +
						"\nObj num: " + (string)int_ObjNum +
						"\nUnique obj num: " + (string)int_UniqueObjNum +
						"\nData blocks: " + (string)KCbucket$getNumWrittenBlocks( bucket_name )
					);
					
					CB_DATA = [TRUE, int_UniqueObjNum, KCbucket$getNumWrittenBlocks( bucket_name )];
				}
				else {
					CB_DATA = [FALSE, "NOWORK"];
				}
			}
			else {
				CB_DATA = [FALSE, "BUSY"];
			}
		}
    }
	
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
