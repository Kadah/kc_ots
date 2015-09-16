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


kcCBSimple$vars;

integer BFL;
#define BFL_PROCESSING 0x1
#define BFL_DONE 0x2

// Config
#define int_MaxCycles 100000

// Main
string str_CellName;
integer int_InputDataLength;
integer int_NumObjects;

// Stats and processing
integer int_Cycles;
integer int_TotalCycles;
integer int_StartTime;
integer int_ObjNum;
integer int_UniqueObjNum;
integer int_Processing;

// Scratch
string str_ObjectClass;
string str_ObjectName;
list lst_ObjData;
string str_Data;
string str_CurrentObjName;
integer int_SubProcessing;

KCbucket$varsDB( objcache );
KCbucket$varsDB( namecache );
KCbucket$varsDB( export );

KCbucket$varsRead( objcache );
KCbucket$varsRead( namecache );

KCbucket$varsWrite( export );

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
        
        if(METHOD == KCCellSaveIndexerMethod$index) {
			if(!(BFL&BFL_PROCESSING)) {
				
				// Get cell info
				str_CellName = KCCell$getCellName();
				int_NumObjects = KCCell$getNumObjs();
				int_InputDataLength = KCCell$getCellDataLength();
				
				debugUncommon("=Indexing CellName: " + str_CellName + ", objs: " + (string)int_NumObjects + ", data length: " + (string)int_InputDataLength);
				
				// Only run if there is something to do
				if (str_CellName != "" && int_InputDataLength > 0 && int_NumObjects > 0) {
					debugUncommon("Indexing CellName: " + str_CellName + ", objs: " + (string)int_NumObjects + ", data length: " + (string)int_InputDataLength);
					
					BFL = BFL_PROCESSING;
					llScriptProfiler(PROFILE_SCRIPT_MEMORY);
					
					int_StartTime = llGetUnixTime();
					
					//Reset all variables
					int_Cycles = 0;
					KCbucket$writeSeek( export, 0 );
					
					KCbucket$initDB( objcache, "CD", FALSE );
					KCbucket$initDB( namecache, "ND", FALSE );
					KCbucket$initDB( export, "ED", TRUE );
					
					KCbucket$readSeek( namecache, 0 );
					KCbucket$readAll( namecache, str_CurrentObjName, int_Processing, 
						KCbucket$writeClose( export );,
						// Write object name to export db
						KCbucket$write( export, llList2Json(JSON_ARRAY, [
							"OBJNAME",
							str_CurrentObjName
						]));
						// Write object details for matching objects
						KCbucket$readSeek( objcache, 0 );
						KCbucket$readAll( objcache, str_Data, int_SubProcessing, ,
							int_Cycles++;
							lst_ObjData = llJson2List(str_Data);
							str_ObjectClass	= llList2String( lst_ObjData, 0 );
							if (str_ObjectClass == "OBJ") {
								str_ObjectName 	= llList2String( lst_ObjData, 1 );
								if (str_ObjectName == str_CurrentObjName) {
									str_Data = llList2Json(JSON_ARRAY, [
										"OBJ",
										llList2String( lst_ObjData, 3 ), // str_ObjectData
										llList2String( lst_ObjData, 4 ) // str_ExtraData
									]);
									KCbucket$write( export, str_Data );
									int_ObjNum++;
								}
							}
						);
						
						// Update progress text every 4 steps
						if ((int_ObjNum % 4) == 0) {
							_setProgress(
								// Tick arrow spin once every 4 steps (8*4=32)
								KCLib$progressArrowSpin( int_ObjNum, 32 ) +
								" Indexing objects " +
								KCLib$progressPie( ((float)int_ObjNum / (float)int_NumObjects) ) + "\n" +
								(string)int_ObjNum + " objects indexed\n \n "
							);
						}
					);
					
					_setProgress( (string)int_ObjNum + " objects indexed\n" );
					
					llScriptProfiler(PROFILE_NONE);
					debugUncommon(
						"Index runtime: " + (string)(llGetUnixTime() - int_StartTime) + " seconds." +
						"\nCycles: " + (string)int_Cycles +
						"\nMax mem: " + (string)llGetSPMaxMemory() + " bytes" +
						"\nObj num: " + (string)int_ObjNum +
						"\nData in: " + (string)int_InputDataLength +
						"\nData blocks: " + (string)KCbucket$getNumWrittenBlocks(export)
					);
					
					BFL = (BFL&~BFL_PROCESSING);
					CB_DATA = [TRUE, int_ObjNum, KCbucket$getNumWrittenBlocks(export)];
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
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
