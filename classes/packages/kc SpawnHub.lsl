/*
Spawn Hub

TODO: Documentation
TODO: System for staging objects that need to be saved to hubs.
TODO: A clear set to of guidelines for what types of objects go in to what hub.
TODO: A clear system of what hub to find objects in.
TODO: Object lists/indexing
TODO: Hubs should likely be linked to the mission save controller, or possibly unlinked, for testing rez.
TODO: A system for updating scripts in mission objects
TODO: Expose tick rate via method so that it can be adjusted, ie. Initial mission spawn can be done as fast as possible while later cell loading could be done at a slower rate that would not affect play.

Make this spawn hub independent from being a child prim to a root object
#define STANDALONE_SPAWN

Allow only one of the same named spawn hubs
#define ONLY_ONE_SPAWN

TODO: Rework this
Use dictionary list of objects to save memory
Only saves memory in cases when lots of duplicate objects will be queued at the same time
#define REZ_USE_DICT

*/

// Seconds to wait before considering a rez opperation as failed
#ifndef REZ_TICK_RATE
#define REZ_TICK_RATE 0.5
#endif

// Seconds to wait before considering a rez opperation as failed
#ifndef REZ_TIMEOUT
#define REZ_TIMEOUT 5
#endif

#define DEBUG DEBUG_UNCOMMON
#include "../../_core.lsl"


integer BFL;
#define BFL_QUEUE 1

list _REZABLE_OBJECTS; // [ str_ObjectName ] index = int_ObjectName
list _REZ_QUEUE; // [ int_ObjectName, vec_Pos, rot_Rot, int_Flags, delayed_cb_data ]; delayed_cb_data = [ uuidOrLink, SENDER_SCRIPT, CB ]
#define queueDeleteFirst() _REZ_QUEUE= llDeleteSubList(_REZ_QUEUE, 0, 4)
#define TIMER_REZ_TIMEOUT "r"
#define MULTIREZ_QUEUE_CB "Q"
list _MULTIREZ_CB_DATA;

runQueue() {
    if (!(BFL&BFL_QUEUE) && _REZ_QUEUE != []) {
        BFL = BFL|BFL_QUEUE;
        llSetTimerEvent(REZ_TICK_RATE);
    }
}

default 
{
	// Start up the script
    state_entry() {
        // Start listening
        #ifdef STANDALONE_SPAWN
        initiateListen();
        #endif
        
        string str_SpawnHubName = llGetObjectDesc();
        debugUncommon("KCSpawnHub - state_entry: " + str_SpawnHubName);
        
        // Kill other instances
        #ifdef ONLY_ONE_SPAWN
        KCSpawnHub$remove(str_SpawnHubName);
        #endif
        
        // Build list of rezable objects
        #ifdef REZ_USE_DICT
        _REZABLE_OBJECTS = [];
        integer i = llGetInventoryNumber(INVENTORY_OBJECT);
        string  str_ObjectName;
        while (i--) {
            str_ObjectName = llGetInventoryName(INVENTORY_OBJECT, i);
            if (str_ObjectName != llGetScriptName() ) {
                _REZABLE_OBJECTS += str_ObjectName;
            }
        }
        #endif
    }
    
    #ifdef REZ_USE_DICT
    changed(integer change) {
        if (change&CHANGED_INVENTORY) {
            debugUncommon("WARNING: Spawn hub inventory changed, reset may be required");
        }
    }
    #endif
    
	// Timer event
    timer() {
        if(_REZ_QUEUE == []) {
            llSetTimerEvent(0.0);
            return;
        }
        
        #ifdef REZ_USE_DICT
        string str_ObjectName   = llList2String(_REZABLE_OBJECTS, llList2Integer(_REZ_QUEUE, 0));
        #else
        string str_ObjectName   = llList2String(_REZ_QUEUE, 0);
        #endif
        vector vec_Pos          = (vector)llList2String(_REZ_QUEUE, 1);
        rotation rot_Rot        = (rotation)llList2String(_REZ_QUEUE, 2);
        integer int_Flags       = (integer)llList2String(_REZ_QUEUE, 3);
        
        
        // debugUncommon("Tick - " + str_ObjectName + " pos:" + FLOOR_VEC_STRING(vec_Pos));
        
        // Process vector to send rezed object
        vector vec_PosMajor = FLOOR_VEC(vec_Pos);
        // integer int_PosMajor = KCLib$vectorToInteger(vec_PosMajor)|0x10000000; // major vector to send via rez parm, add 1<<28 to prevent 0
        integer int_PosMajor = KCLib$vectorToIntegerFlags( vec_PosMajor, int_Flags ); // major vector to send via rez parm
        vec_Pos = vec_Pos - vec_PosMajor; // minor vector to offsent prim rez
        
        // Rez object 8m above hub
        vector vec_RootPos = llGetRootPosition() + <0,0,8>;
        vec_Pos = vec_Pos + FLOOR_VEC(vec_RootPos);
        llRezAtRoot(str_ObjectName, vec_Pos, ZERO_VECTOR, rot_Rot, int_PosMajor);
        llSetTimerEvent(REZ_TIMEOUT);
    }
    
    object_rez(key key_RezzedObjectKey) {
        // debugUncommon("object_rez: " + (string)key_RezzedObjectKey + " - Data: " + llDumpList2String(llGetObjectDetails(key_RezzedObjectKey, [OBJECT_NAME, OBJECT_POS]),", "));
        
        string str_ObjectName = llKey2Name(key_RezzedObjectKey);
        
        // multiTimer([TIMER_REZ_TIMEOUT]);
        
        string delayed_cb_data = llList2String(_REZ_QUEUE, 4);
        
        if (delayed_cb_data != "") {
            _MULTIREZ_CB_DATA += [ str_ObjectName, key_RezzedObjectKey ];
            
            if (delayed_cb_data != MULTIREZ_QUEUE_CB) {
                list delayed_callback = llJson2List(delayed_cb_data);
                string uuidOrLink = llList2String(delayed_callback,0);
                string script = llList2String(delayed_callback,1);
                integer method = (integer)llList2String(delayed_callback,2);
                string callback = llList2String(delayed_callback,3);
                string cbdata = llList2Json(JSON_ARRAY, _MULTIREZ_CB_DATA);
                
                debugUncommon("delayed_cb - id: " + uuidOrLink + " data: " + delayed_cb_data);
                
                sendCallback(uuidOrLink, script, method, cbdata, callback);
                
                _MULTIREZ_CB_DATA = [];
            }
        }
        
        queueDeleteFirst();
        BFL = BFL&~BFL_QUEUE;
        runQueue();
    }
    
    #ifdef STANDALONE_SPAWN
    on_rez(integer int_RezParam)
    {
        llResetScript(); 
    }
    
    // This is the listener
    #define LISTEN_LIMIT_FREETEXT if(llGetOwnerKey(id) != llGetOwner())return;
    #include "xobj_core/_LISTEN.lsl"
    #endif
    
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
    if(method$isCallback) { return; }
    
	// ByOwner means the method was run by the owner of the prim
    if(method$byOwner) {
        if(METHOD == KCSpawnHubMethod$ping) {
            string str_SpawnHubName = llGetObjectDesc();
            // debugUncommon("KCSpawnHubMethod$ping: " + str_SpawnHubName);
            // KCRez$rezSpawnHubCB(str_SpawnHubName);
            // return;
            CB_DATA = [str_SpawnHubName];
        }
        
        #ifdef STANDALONE_SPAWN
        else if(METHOD == KCSpawnHubMethod$remove) {
            string str_SpawnHubName = method_arg(0);
            // debugUncommon("KCSpawnHubMethod$remove: " + str_SpawnHubName);
            // Kills spawn hub is wildcard or name match. Cannot delete itself (allows it to remove all others).
            if ((str_SpawnHubName == "*") || ((str_SpawnHubName == llGetObjectDesc()) && (id != llGetKey()))) {
                llDie();
            }
        }
        #endif
        
        else if (METHOD == KCSpawnHubMethod$rezObject) {
            string str_ObjectName = method_arg(0);
            
            #ifdef REZ_USE_DICT
            integer int_ObjectName = llListFindList(_REZABLE_OBJECTS, [str_ObjectName]);
            if(~int_ObjectName) {
            #else
            if(llGetInventoryType(str_ObjectName) == INVENTORY_OBJECT){
            #endif
                vector vec_Pos = (vector)method_arg(1);
                rotation rot_Rot = (rotation)method_arg(2);
                integer int_Flags = (integer)method_arg(3);
                // SENDER_SCRIPT = method_arg(4);
                
                string delayed_cb_data = "";
                if (CB != "") {
                    string uuidOrLink;
                    if (link > 0) {uuidOrLink = (string)link;} else {uuidOrLink = (string)id;}
                    delayed_cb_data = llList2Json(JSON_ARRAY, [ uuidOrLink, method_arg(4), METHOD, CB ]);
                }
                #ifdef REZ_USE_DICT
                    _REZ_QUEUE += [ int_ObjectName, vec_Pos, rot_Rot, int_Flags, delayed_cb_data ];
                #else
                    _REZ_QUEUE += [ str_ObjectName, vec_Pos, rot_Rot, int_Flags, delayed_cb_data ];
                #endif
                
                // debugUncommon("KCSpawnHubMethod$rezObject: " + llGetObjectDesc() + " - queued - Object: " + str_ObjectName + " - FinalPos: " + method_arg(1));
                
            }
            runQueue();
            return;
        }
        
        else if (METHOD == KCSpawnHubMethod$rezObjectList) {
            list lst_Rez_Objects = llJson2List(method_arg(0)); //json_Rez_Objects
            integer int_Flags = (integer)method_arg(1);
            string SENDER_SCRIPT = method_arg(2);
            
            string delayed_cb_data = "";
            if (CB != "") {
                delayed_cb_data = MULTIREZ_QUEUE_CB;
            }
            // Rebuild the list to save memory
            #ifdef REZ_USE_DICT
            integer int_ObjectName;
            #endif
            string str_ObjectName;
            vector vec_Pos;
            rotation rot_Rot;
            integer i;
            integer int_Count = llGetListLength(lst_Rez_Objects);
            for(i=0; i<int_Count; i+=3) {
                str_ObjectName = llList2String(lst_Rez_Objects, i);
                #ifdef REZ_USE_DICT
                integer int_ObjectName = llListFindList(_REZABLE_OBJECTS, [str_ObjectName]);
                if(~int_ObjectName) {
                #else
                if(llGetInventoryType(str_ObjectName) == INVENTORY_OBJECT){
                #endif
                    vec_Pos        = (vector)llList2String(lst_Rez_Objects, i+1);
                    rot_Rot        = (rotation)llList2String(lst_Rez_Objects, i+2);
                    #ifdef REZ_USE_DICT
                        _REZ_QUEUE += [ int_ObjectName, vec_Pos, rot_Rot, int_Flags, delayed_cb_data ];
                    #else
                        _REZ_QUEUE += [ str_ObjectName, vec_Pos, rot_Rot, int_Flags, delayed_cb_data ];
                    #endif
                }
            }
            // debugUncommon("KCSpawnHubMethod$rezObjectList - data: " + llDumpList2String(_REZ_QUEUE, ", ") + " id:" + (string)id);
            
            if (CB != "") {
                string uuidOrLink = id;
                if ((key)id) {uuidOrLink = (string)id;} else {uuidOrLink = (string)link;}
                _REZ_QUEUE = llListReplaceList(_REZ_QUEUE, [llList2Json(JSON_ARRAY, [ uuidOrLink, SENDER_SCRIPT, METHOD, CB ])], -1,-1);
            }
            
            // debugUncommon("KCSpawnHubMethod$rezObjectList: " + method_arg(0) + " - Queue: " + llDumpList2String(_REZ_QUEUE, ", "));
            
            runQueue();
            return;
        }
    }
    
    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
