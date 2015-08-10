/*
Cell Load: Objects

TODO: Figure out how to tell what spawn hub to send data to

*/

#define USE_SHARED ["config", "mis"]
#include "../../_core.lsl"


#ifndef BATCH_LOAD_SIZE
#   define BATCH_LOAD_SIZE 5
#endif


integer BFL;
#define BFL_LOADING 0x40
#define BFL_DONELOADING_WAITFORREZ 0x80

kcCBSimple$vars;

list G_lst_SpawnHubs; // [ str_SpawnHubName, str_SpawnHubUUID ]
list G_lst_SpawnHubsWaiting; // [ str_SpawnHubName ]

integer G_int_LoadFlag;
vector G_vec_Pos;
integer G_int_NumObjs;
integer G_int_NumObjsLoaded;
integer G_int_DataIndex;
integer G_int_DataIndexEnd;
list G_lst_ObjData;


list readNextObject() {
    if ((llGetListLength(G_lst_ObjData) < 2) && (G_int_DataIndex <= G_int_DataIndexEnd)) {
        string str_RezData = llList2String(G_lst_ObjData, 0) + (string)llGetLinkMedia(llList2Integer(G_lst_BlockDB, llFloor(G_int_DataIndex/9)), (G_int_DataIndex%9), [PRIM_MEDIA_HOME_URL, PRIM_MEDIA_CURRENT_URL, PRIM_MEDIA_WHITELIST]);
        G_int_DataIndex++;
        G_lst_ObjData = llParseString2List(str_RezData, [";"], []);
        // debugUncommon("G_int_DataIndex: " + (string)G_int_DataIndex + " G_lst_ObjData: " + llDumpList2String(G_lst_ObjData, ", "));
    }
    if (llGetListLength(G_lst_ObjData) == 0) {
        debugUncommon("Reached end of data");
        return [];
    }
    
    string str_ObjData = llList2String(G_lst_ObjData, 0);
    
    // LSL is stupid
    if (llGetListLength(G_lst_ObjData) > 1) { G_lst_ObjData = llList2List(G_lst_ObjData, 1, -1);}
    else { G_lst_ObjData = [];}
    
    string str_ObjectName = llGetSubString( str_ObjData, 0, -43 );    
    vector vec_Pos = KCLib$base64ToVector( str_ObjData, -42 );
    rotation rot_Rot = KCLib$base64ToRotation( str_ObjData, -24 );
    
    vector vec_RootPos = llGetRootPosition();
    vec_Pos = vec_Pos + G_vec_Pos;
    
    G_int_NumObjsLoaded++;
    
    return [ str_ObjectName, vec_Pos, rot_Rot ];
}


loadBatchAndRezObjects() {
    // if (!BFL&BFL_LOADING) {return;}
    
    if (G_int_NumObjsLoaded < G_int_NumObjs) {
        string str_SpawnHubName = "LV Hall 1.0 Spawn Hub";
        integer pos = llListFindList(G_lst_SpawnHubs, [str_SpawnHubName]);
        if(pos == -1) {
            debugRare("ERROR: Spawn hub not found.");
            BFL = BFL&~BFL_LOADING;
            return;
        }
        string str_SpawnHubUUID = llList2String(G_lst_SpawnHubs, pos+1 );
        
        list lst_ObjData;
        list lst_ObjDataRez;
        integer i;
        // for(i=0; ; i++) {
        while (BFL&BFL_LOADING && i < BATCH_LOAD_SIZE) {
            i++;
            lst_ObjData = readNextObject();
            if (lst_ObjData == []) {
                debugUncommon("Out of data");
                BFL = (BFL&~BFL_LOADING)|BFL_DONELOADING_WAITFORREZ;
            }
            else {
                // debugUncommon("loadAndRezObjs: " + (string)G_int_NumObjsLoaded + "/" + (string)G_int_NumObjs);
                // debugUncommon("ObjData: " + llDumpList2String(lst_ObjData, ", "));
                lst_ObjDataRez += lst_ObjData;
            }
        }
        
        if (lst_ObjDataRez != []) {
            // debugUncommon("ObjDataRez: " + llDumpList2String(lst_ObjDataRez, ", "));
            KCSpawnHub$rezObjectList(str_SpawnHubUUID, llList2Json(JSON_ARRAY, lst_ObjDataRez), G_int_LoadFlag, cls$name, KCCellLoadObjectsCB$loadingRezCB);
        }
    }
    else {
    // if (BFL&BFL_DONELOADING_WAITFORREZ) {
        BFL = BFL&~BFL_LOADING;
        debugUncommon("BFL_DONELOADING_WAITFORREZ");
        kcCBSimple$fireCB( ([TRUE, G_int_NumObjs, G_int_NumObjsLoaded]) );
    }
}

// Named timers
#define PING_TIMEOUT "P"
timerEvent(string id, string data) {
    if(id == PING_TIMEOUT) {
        debugRare("PING_TIMEOUT - Spawn hubs not found: " + llDumpList2String(G_lst_SpawnHubsWaiting, ", ") );
        kcCBSimple$fireCB( ([ FALSE, llList2Json(JSON_ARRAY, G_lst_SpawnHubsWaiting) ]) );
    }
}

default 
{
	// Start up the script
    state_entry() {
		mem_usage();
    }
    
	// Timer event
    timer() {multiTimer([]);}
	
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
        if ((CB == KCCellLoadObjectsCB$ping) && (METHOD == KCSpawnHubMethod$ping)) {
            string str_SpawnHubName = method_arg(0);
            debugUncommon("KCCellLoadObjectsCB$ping responce from: \"" + str_SpawnHubName + "\"");
            
            // Store the UUID/link so we can talk to it
            string uuidOrLink;
            if (link > 0) {uuidOrLink = (string)link;} else {uuidOrLink = (string)id;}
            integer pos = llListFindList(G_lst_SpawnHubs, [str_SpawnHubName]);
            if(~pos) {
                debugRare("WARNING: Duplicate spawn hub found: " + str_SpawnHubName);
                G_lst_SpawnHubs = llListReplaceList( G_lst_SpawnHubs, [uuidOrLink], pos+1, pos+1 );
                
            } else {
                G_lst_SpawnHubs += [ str_SpawnHubName, uuidOrLink ];
            }
            
            // Remove from waiting list
            pos = llListFindList(G_lst_SpawnHubsWaiting, [str_SpawnHubName]);
            if(~pos) {
                G_lst_SpawnHubsWaiting = llDeleteSubList(G_lst_SpawnHubsWaiting, pos, pos);
            }
            
            if (G_lst_SpawnHubsWaiting == []) {
                multiTimer([PING_TIMEOUT]);
                // KCCore$moduleReady();
                
                kcCBSimple$fireCB( [TRUE] );
            }
        }
        else if ((CB == KCCellLoadObjectsCB$loadingRezCB) && (METHOD == KCSpawnHubMethod$rezObjectList)) {
            debugUncommon("KCCellLoadObjectsCB$loadingRezCB");
            
            loadBatchAndRezObjects();
            
        }
    return;
    }
    
	// ByOwner means the method was run by the owner of the prim
    if(method$byOwner) {
        
        if(METHOD == KCCellLoadObjectsMethod$init) {
            debugUncommon("KCRezMethod$init: " + method_arg(0));
            G_lst_SpawnHubsWaiting = llJson2List(method_arg(0));
            G_lst_SpawnHubs = [];
            KCSpawnHub$pingLocal( KCCellLoadObjectsCB$ping );
            KCSpawnHub$pingRemote( KCCellLoadObjectsCB$ping );
            multiTimer([PING_TIMEOUT, "", 10, FALSE]);
            
            kcCBSimple$delayCB();
            return;
        }
        
        else if(METHOD == KCCellLoadObjectsMethod$rezObjectList) {
            debugUncommon("KCCellLoadObjectsMethod$rezObjectList");
            
            string str_SpawnHubName = method_arg(0);
            string json_Rez_Objects = method_arg(1);
            integer int_Flags = (integer)method_arg(2);
            
            debugUncommon("KCRezMethod$rezObjectList: " + str_SpawnHubName + " - data: " + json_Rez_Objects);
            
            integer pos = llListFindList(G_lst_SpawnHubs, [str_SpawnHubName]);
            if(~pos) {
                string str_SpawnHubUUID = llList2String(G_lst_SpawnHubs, pos+1 );
                KCSpawnHub$rezObjectList(str_SpawnHubUUID, json_Rez_Objects, int_Flags, SENDER_SCRIPT, CB);
            } else {
                debugRare("KCRezMethod$rezObject - ERROR: Unable to locate spawn hub \"" + str_SpawnHubName + "\"");
            }
            return; //The callback will be handled by the spawn hub
        }
        
        else if (METHOD == KCCellLoadObjectsMethod$load) {
            debugUncommon("KCCellLoadObjectsMethod$load");
            
            if (BFL&BFL_LOADING) {
                debugRare("ERROR: Spawn hub is busy loading data already.");
                return;
            }
            
            debugUncommon("Loading cell");
            BFL = BFL|BFL_LOADING;
            
            updateBlockDBPrims(FALSE);
            debugUncommon("G_lst_BlockDB: " + llDumpList2String(G_lst_BlockDB, ", "));
            
            G_int_LoadFlag = (integer)method_arg(0);
            G_vec_Pos = (vector)method_arg(1);
            G_int_NumObjsLoaded = 0;
            G_int_DataIndex = 0;
            G_lst_ObjData       = [];
            G_int_NumObjs       = KCCell$getNumObjs();
            G_int_DataIndexEnd  = KCCell$getCellDataEnd();
            
            debugUncommon("NumObjs: "+(string)G_int_NumObjs + " DataEnd: "+(string)G_int_DataIndexEnd + " Pos: " + (string)G_vec_Pos);
            
            kcCBSimple$delayCB();
            
            loadBatchAndRezObjects();
            
            return;
        }
        
    }
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
