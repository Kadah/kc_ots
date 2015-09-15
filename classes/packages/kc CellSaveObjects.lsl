/*
Cell Save: Objects

*/

#define USE_SHARED ["config", "mis"]
#include "../../_core.lsl"



#ifndef DATAWAIT_TIMEOUT
#define DATAWAIT_TIMEOUT 15
#endif

kcCBSimple$vars;

integer BFL;
#define BFL_RX 0x1
#define BFL_OBJS 0x2
#define BFL_DONE 0x4

integer G_int_ListenHandle;
string str_CellName;
integer G_int_NumObjs;

KCbucket$varsDB( objcache );
KCbucket$varsWrite( objcache );



default 
{
    state_entry() {
		mem_usage();
		DB2$ini();
    }
    
    timer() {
        llSetTimerEvent(0.0);
        llListenRemove(G_int_ListenHandle);
        if (!(BFL&BFL_RX)) {return;}
        debugUncommon((string)DATAWAIT_TIMEOUT + " seconds have passed since receiving any more data. Assuming finished");
        
        if (G_int_NumObjs == 0) {debugRare("WARNING: No objects found.");}
        
		KCbucket$writeClose( objcache );
        
        debugUncommon("Done Saving - #Objs: " + (string)G_int_NumObjs + " Data size: "+(string)KCbucket$getBlockNum(objcache) + " Prims: "+(string)KCbucket$getBlockNumPrims(objcache));
		
		llSetText( "Finished\n" + (string)G_int_NumObjs + " objects saved", ZERO_VECTOR, 1 );
        
		// Store general details about objects in this cell
        KCCell$setNumObjs( G_int_NumObjs );
        KCCell$setCellDataLength( KCbucket$getNumWrittenBlocks(objcache) );
        
        mem_usage();
		
		//Callback to controller instead of starting the indexing from here
		// KCCellSaveIndexer$index( str_CellName, KCCellSaveObjectsCB$indexCB );
		kcCBSimple$fireCB( ([ TRUE, G_int_NumObjs, KCbucket$getBlockNum(objcache), KCbucket$getBlockNumPrims(objcache) ]) );
    }
    
	
    
    listen(integer chan, string name, key id, string message) {
        debugCommon("COM received:\n"+message);
        if (chan == REZZED_REPLY_CHANNEL && llGetOwnerKey(id) == llGetOwner()) {
            if (llGetSubString(message,0,0) == "S") {
                list lst_ObjData = llGetObjectDetails(id, [OBJECT_NAME, OBJECT_POS, OBJECT_ROT]);
                vector vec_Pos = llGetRootPosition();
                vec_Pos = llList2Vector(lst_ObjData, 1) - FLOOR_VEC(vec_Pos);
                rotation rot_Rot = llList2Rot(lst_ObjData, 2);
                
				string str_ExtraData = "";
				if (llStringLength(message) > 1) {
					str_ExtraData = llGetSubString(message,0,1);
				}
				
				// There is no practial reason why this shouldn't be JSON_APPEND
				// The savings teh custom formate had are not that great
				string str_Data = llList2Json(JSON_ARRAY, [
					"OBJ", // class
					llList2String(lst_ObjData, 0), // nane
					id, // id, stored temporarily
					fuis(vec_Pos.x) + fuis(vec_Pos.y) + fuis(vec_Pos.z) + 
					fuis(rot_Rot.x) + fuis(rot_Rot.y) + fuis(rot_Rot.z) + fuis(rot_Rot.s), // pos/rot
					str_ExtraData, // nonspecific extra data
					KCbucket$dataAddress_Encode(KCbucket$writeGetNextAddress(objcache)) // data address
				]);
				// llOwnerSay((string)G_int_NumObjs+": "+str_Data);
				
				KCbucket$write( objcache, str_Data );
                
                G_int_NumObjs++;
				llSetText( (string)G_int_NumObjs + " objects saved", ZERO_VECTOR, 1 );
				
                // Reset timeout
                llSetTimerEvent(DATAWAIT_TIMEOUT);
            }
        }
    }
    
    
    
	// This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:
        METHOD - (int)method  
        INDEX - (int)obj_index
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
	
	// Here's where you receive callbacks from running methods
    if(method$isCallback) {
		if ((CB == KCCellSaveObjectsCB$indexCB) && (METHOD == KCCellSaveIndexerMethod$index)) {
			BFL = (BFL&~BFL_RX)|BFL_DONE;
			if ((integer)method_arg(0)) {
				integer int_LastDataFace = (integer)method_arg(1);
				debugUncommon("Data in: " + (string)int_LastDataFace + " data out: " + (string)int_LastDataFace);
				
				kcCBSimple$fireCB( ([ TRUE, G_int_NumObjs, int_LastDataFace ]) );
			}
			else {
				kcCBSimple$fireCB( ([ FALSE ]) );
			}
		}
		return;
	}
    
	// ByOwner means the method was run by the owner of the prim
    if(method$byOwner) {
        
        if(METHOD == KCCellSaveObjectsMethod$save) {
            debugUncommon("KCCellSaveObjectsMethod$save");
            
			G_int_NumObjs = 0;
			KCbucket$writeSeek( objcache, 0 );
			KCbucket$initDB( objcache, "CD", TRUE );
            
			if (KCbucket$DBOK(objcache)) {
				BFL = BFL_RX;
				G_int_ListenHandle = llListen(REZZED_REPLY_CHANNEL,"","","");
				
				str_CellName = method_arg(0);
				
				debugUncommon("Saving CellName: " + str_CellName);
				
				KCBasicCell$saveCellObjs( str_CellName );
				
				KCbucket$write( objcache, llList2Json(JSON_ARRAY, ["CELL", str_CellName]) );
				
				llSetTimerEvent(DATAWAIT_TIMEOUT);
				
				kcCBSimple$delayCB();
				return;
			}
        }
        
    }
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
