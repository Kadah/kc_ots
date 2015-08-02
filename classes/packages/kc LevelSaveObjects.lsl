/*
Level Save: Objects

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
integer G_int_NumObjs;
integer G_int_DataIndex;
string G_str_ObjDataBuffer;


writeBlock() {
    // debugUncommon("Saving Rez Data");
    // llOwnerSay(llGetSubString(G_str_ObjDataBuffer,0,1023));
    // llOwnerSay(llGetSubString(G_str_ObjDataBuffer,1024,2047));
    if (llGetListLength(G_lst_BlockDB) < llFloor(G_int_DataIndex/9)) {
        debugRare("ERROR: Ran out of rez DB prims, add more and try again.");
        return;
    }
    llSetLinkMedia( llList2Integer(G_lst_BlockDB, llFloor(G_int_DataIndex/9)), (G_int_DataIndex%9), [
        PRIM_MEDIA_HOME_URL, llGetSubString(G_str_ObjDataBuffer,0,1023),
        PRIM_MEDIA_CURRENT_URL, llGetSubString(G_str_ObjDataBuffer,1024,2047), 
        PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_NONE, PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE
    ]);
    G_int_DataIndex++;
    if (llStringLength(G_str_ObjDataBuffer) < 2048) {
        G_str_ObjDataBuffer = "";
    }
    else {
        G_str_ObjDataBuffer = llGetSubString(G_str_ObjDataBuffer,2048, -1);
    }
    // mem_usage();
}



default 
{
	// Start up the script
    state_entry() {
		mem_usage();
    }
    
	// Timer event
    timer() {
        llSetTimerEvent(0.0);
        llListenRemove(G_int_ListenHandle);
        if (!(BFL&BFL_RX)) {return;}
        debugUncommon((string)DATAWAIT_TIMEOUT + " seconds have passed since receiving any more data. Assuming finished");
        
        if (G_int_NumObjs == 0) {debugRare("WARNING: No objects found.");}
        
        writeBlock();
        
        if (G_str_ObjDataBuffer != "") {debugRare("ERROR: Extra data left in buffer: " + G_str_ObjDataBuffer); return;}
        
        
        debugUncommon("Done Saving - Objs: " + (string)G_int_NumObjs);
        
        
        KCLevel$setNumObjs( G_int_NumObjs );
        KCLevel$setLevelDataEnd( G_int_DataIndex );
        
        BFL = (BFL&~BFL_RX)|BFL_DONE;
        mem_usage();
        
        kcCBSimple$fireCB( ([ TRUE, G_int_NumObjs, G_int_DataIndex ]) );
    }
    
	
    
    listen(integer chan, string name, key id, string message) {
        debugCommon("COM received:\n"+message);
        if (chan == REZZED_REPLY_CHANNEL && llGetOwnerKey(id) == llGetOwner()) {
            // Simple objects
            if (llGetSubString(message,0,0) == "S") {
                // Simple objects
                list lst_ObjData = llGetObjectDetails(id, [OBJECT_NAME, OBJECT_POS, OBJECT_ROT]);
                vector vec_Pos = llGetRootPosition();
                vec_Pos = llList2Vector(lst_ObjData, 1) - FLOOR_VEC(vec_Pos);
                rotation rot_Rot = llList2Rot(lst_ObjData, 2);
                
                
                //16383
                // string d = llGetSubString(llIntegerToBase64(16383),3,5);
                // integer i = llBase64ToInteger("AAA"+d);
                
                
                
                // G_str_ObjDataBuffer += llList2String(lst_ObjData, 0) + fuis(vec_Pos.x) + fuis(vec_Pos.y) + fuis(vec_Pos.z) + fuis(rot_Rot.x) + fuis(rot_Rot.y) + fuis(rot_Rot.z) + fuis(rot_Rot.s) + ";";
                G_str_ObjDataBuffer += llList2String(lst_ObjData, 0) + fuis(vec_Pos.x) + fuis(vec_Pos.y) + fuis(vec_Pos.z) + fuis(rot_Rot.x) + fuis(rot_Rot.y) + fuis(rot_Rot.z) + fuis(rot_Rot.s) + ";";
                
                
                // debugUncommon(" Obj: " + (string)G_int_NumObjs + ": " + llDumpList2String(lst_ObjData, ", ") + " - " + (string)vec_Pos + " - " + (string)llStringLength(G_str_ObjDataBuffer));

                G_int_NumObjs++;

                if (llStringLength(G_str_ObjDataBuffer) >= 2048) {
                    writeBlock();
                }
                
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
    if(method$isCallback) {return;}
    
	// ByOwner means the method was run by the owner of the prim
    if(method$byOwner) {
        
        if(METHOD == KCLevelSaveObjectsMethod$save) {
            debugUncommon("KCLevelSaveObjectsMethod$save");
            
            G_int_NumObjs = 0;
            G_int_DataIndex = 0;
            G_str_ObjDataBuffer = "";
            
            updateBlockDBPrims(TRUE);
            
            BFL = BFL_RX;
            G_int_ListenHandle = llListen(REZZED_REPLY_CHANNEL,"","","");
            
            vector vec_Upper = (vector)method_arg(0);
            vector vec_Lower = (vector)method_arg(1);
            
            debugUncommon("vec_Upper: " + (string)vec_Upper + " vec_Lower: " + (string)vec_Lower);
            
            KCBasicCell$saveLevelObjs( 0, vec_Upper, vec_Lower );
            
            llSetTimerEvent(DATAWAIT_TIMEOUT);
            
            kcCBSimple$delayCB();
            return;
        }
        
    }
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
