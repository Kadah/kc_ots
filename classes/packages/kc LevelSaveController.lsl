/*
Level Save Controller

General interface to the user and mission save controller
Handles saving the level

TODO: Currently it this is standalone till the mission controller is written
TODO: This can preform local rezs to a defined test location, this will likely change or be improved
TODO: Setup is lacking, as is documentation
TODO: Data export
TODO: Currently a spawn hub is directly linked to this object, that should change with the mission controller
TODO: Saving of level data and such, like mobs and events
TODO: Saving the boundary of the level for use in determining the rez area required
TODO: Increased level ID range, 0x1 to 0xf is too limiting.
TODO: A system for updating scripts in mission objects
TODO: Rezing other level development things, like spawn points and such.
TODO: Staging objects that need to be copied in to spawn hubs.
TODO: Indexing objects and figuring out what goes where and how to find them later.

*/

#define SCRIPT_IS_ROOT
#define USE_EVENTS
#define USE_SHARED ["*"]

#include "../../_core.lsl"

integer BFL;
#define BFL_BUSY 0x1

#define BFL_BEACONS 0x800

vector vec_RezPos;
integer int_Levelid;

// DAIG_NOTICE - Does nothing
// DAIG_NOTHINGSPECIAL - Returns to main
// DAIG_PROCESSCOMPLETE - Clears BFL_BUSY and returns to main
#define DAIG_INIT -2
#define DAIG_NOTICE -1
#define DAIG_NOTHINGSPECIAL 0
#define DAIG_PROCESSCOMPLETE 1
#define DIAG_ROOT 2
#define DIAG_OPTIONS 3
#define DIAG_TESTPOS 4
#define DIAG_LEVELID 5

#define DiagMainMenuText ("Menu of the main.\nRez vec: " + FLOOR_VEC_STRING(vec_RezPos) + "\nLevel id: " + (string)int_Levelid)
#define DiagOptionsMessage ("Options:\nRez vec: " + FLOOR_VEC_STRING(vec_RezPos) + "\nLevel id: " + (string)int_Levelid)

#define LevelDiag$Init() Dialog$spawn(llGetOwner(), "New level, helpful text for initial setup will go here.", (["Initialize"]), DAIG_INIT, "")
#define LevelDiag$Main() Dialog$spawn(llGetOwner(), DiagMainMenuText, (["Save Level", "Test Load", "Clear Test", "Bound Beacons", "Options"]), DIAG_ROOT, "")
#define LevelDiag$Options() Dialog$spawn(llGetOwner(), DiagOptionsMessage, (["Test Position", "Level id", "Back"]), DIAG_OPTIONS, "")
#define LevelDiag$TestPos() Dialog$spawn(llGetOwner(), "Enter vector for test rezing position (region cords)", [], DIAG_TESTPOS, "")
#define LevelDiag$Levelid() Dialog$spawn(llGetOwner(), "Enter level id:", [], DIAG_LEVELID, "")

// Named timers
timerEvent(string id, string data) {
    
    if(id == "st") {
        // debugUncommon("DB2 workaround fired");
        //db2$setOther("config", ["t"], "t");
        //db2$setOther("mis", ["t"], "t");
        KCLevelLoadObjects$init( llList2Json(JSON_ARRAY, ["LV Hall 1.0 Spawn Hub"]), TNN );
    }
}

default 
{
	// Start up the script
    state_entry()
    {
        resetAllOthers();
		initiateListen();
        
        // string str_DB2_CACHE = (string)llGetLinkMedia(LINK_ROOT, 2, [PRIM_MEDIA_HOME_URL, PRIM_MEDIA_CURRENT_URL]);
        // DB2_CACHE = llJson2List(str_DB2_CACHE);
        
        // debugUncommon("state_entry = str_DB2_CACHE: "+str_DB2_CACHE);
        // debugUncommon("state_entry = DB2_CACHE: "+llDumpList2String(DB2_CACHE,", "));
        
        // db2$rootSend();
        db2$index();
        
        multiTimer(["st", "", 4, FALSE]);
        mem_usage();
    }
    
	// Timer event
    timer(){multiTimer([]);}
    
    // Touch handlers
    touch_start(integer total){
        if(llDetectedKey(0) != llGetOwner())return;
        // string ln = llGetLinkName(llDetectedLinkNumber(0));
        // string desc = (string)llGetLinkPrimitiveParams(llDetectedLinkNumber(0), [PRIM_DESC]);
        
        if (llDetectedLinkNumber(0) == LINK_ROOT) {
            if(BFL&BFL_BUSY) {
                Dialog$spawn(llGetOwner(), "System is busy.", (["OK"]), DAIG_NOTICE, "");
            }
            else if (KCLevel$getinit() == 0) {
				LevelDiag$Init();
			}
            else {
                vec_RezPos = KCLevel$getRezPos();
                int_Levelid = KCLevel$getLevelid();
                LevelDiag$Main();
            }
        }
        
        raiseEvent(evt$TOUCH_START, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0)]));
    }
    
    touch_end(integer total){ 
        if(llDetectedKey(0) != llGetOwner())return;
        raiseEvent(evt$TOUCH_END, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0)]));
    }
    
    changed(integer change){
        if(change&CHANGED_OWNER)llResetScript();
    }
    
    // This is the listener
    #define LISTEN_LIMIT_FREETEXT if(llGetOwnerKey(id) != llGetOwner())return;
    #include "xobj_core/_LISTEN.lsl"
    
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
        if(Dialog$isCallback){
            integer menu = (integer)llJsonGetValue(PARAMS, ["menu"]);
            string message = llJsonGetValue(PARAMS, ["message"]);
            
            if(menu == DAIG_INIT) {
				//TODO: step through setup process
				KCLevel$setinit(1);
				KCLevelSaveBoundary$setup( KCLevelSaveControllerCB$boundarySetupCB );
			}
            else if(menu == DIAG_ROOT) {
                if(message == "Save Level") {
                    BFL = BFL|BFL_BUSY;
					//TODO: for now it only checks for a valid boundary setup, likely will have additional steps.
					KCLevelSaveBoundary$setup( KCLevelSaveControllerCB$boundaryTestCB );
                }
				//TODO: For testing
                else if (message == "Test Load") {
                    BFL = BFL|BFL_BUSY;
                    KCLevelLoad$load( int_Levelid, vec_RezPos, KCLevelSaveControllerCB$loadLevelCB );
                }
                else if(message == "Clear Test") {
                    KCBasicCell$clearGroup( int_Levelid );
                }
                else if(message == "Bound Beacons") {
                    KCLevelSaveBoundary$setBeams( ((BFL=BFL^BFL_BEACONS)==BFL_BEACONS), TNN );
                }
                else if(message == "Options") {
                    LevelDiag$Options();
                }
            }
            else if (menu == DIAG_OPTIONS) {
				//TODO: For testing
                if     (message == "Test Position")     LevelDiag$TestPos();
				//TODO: Needs improvement
                else if(message == "Level id")          LevelDiag$Levelid();
                else if(message == "Back")              LevelDiag$Main();
            }
            else if (menu == DIAG_TESTPOS) {
                vec_RezPos = (vector)tr(message);
                KCLevel$setRezPos( vec_RezPos );
                debugUncommon("Test rez vector set to: " + (string)vec_RezPos);
                LevelDiag$Options();
            }
            else if (menu == DIAG_LEVELID) {
                int_Levelid = (integer)tr(message);
                KCLevel$setLevelid( int_Levelid );
                debugUncommon("Level id set to: " + (string)int_Levelid);
                LevelDiag$Options();
            }
            else if (menu == DAIG_NOTHINGSPECIAL) {
                LevelDiag$Main();
            }
            else if (menu == DAIG_PROCESSCOMPLETE) {
                BFL = BFL&~BFL_BUSY;
                LevelDiag$Main();
            }
        }
        else if (CB == KCLevelSaveControllerCB$boundarySetupCB && METHOD == KCLevelSaveBoundaryMethod$setup) {
            if((integer)method_arg(0)) {
                //TODO: step through setup process
				LevelDiag$Main();
            }
            else {
                Dialog$spawn(llGetOwner(), "Error setting up boundary.", (["OK"]), DAIG_PROCESSCOMPLETE, "");
            }
		}
        else if (CB == KCLevelSaveControllerCB$boundaryTestCB && METHOD == KCLevelSaveBoundaryMethod$setup) {
            if((integer)method_arg(0) && (integer)method_arg(1)) {
				KCLevelSave$save( KCLevelSaveControllerCB$saveLevelCB );
            }
            else {
                Dialog$spawn(llGetOwner(), "Upper boundary not found, new one rezzed. Setup upper marker and try again.", (["OK"]), DAIG_PROCESSCOMPLETE, "");
            }
        }
        else if (CB == KCLevelSaveControllerCB$saveLevelCB && METHOD == KCLevelSaveMethod$save) {
            string msg;
            if((integer)method_arg(0) == 1) msg = "Save completed.\nObjs saved: "+method_arg(1);
            else msg = "Save failed.";
            Dialog$spawn(llGetOwner(), msg, (["OK"]), DAIG_PROCESSCOMPLETE, "");
        }
        else if (CB == KCLevelSaveControllerCB$loadLevelCB && METHOD == KCLevelLoadMethod$load) {
            string msg;
            if((integer)method_arg(0) == 1) msg = "Load completed.\nObjes Loaded: "+method_arg(1)+"/"+method_arg(2);
            else msg = "Load fail.";
            Dialog$spawn(llGetOwner(), msg, (["OK"]), DAIG_PROCESSCOMPLETE, "");
        }
        return;
    }
    
	// Internal means the method was sent from within the linkset
    // if(method$internal) {
        
    // }
    
	// ByOwner means the method was run by the owner of the prim
    if(method$byOwner) {
        if(METHOD == KCLevelSaveControllerMethod$saveLevel) {
            debugUncommon("KCLevelSaveControllerMethod$saveLevel: ");
            
			//TODO: this
			
            CB_DATA = [
                
                
                
            ];
        }
    }
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
