/*
Cell Save Controller

General interface to the user and mission save controller
Handles saving the cell

TODO: Currently it this is standalone till the mission controller is written
TODO: This can preform local rezs to a defined test location, this will likely change or be improved
TODO: Setup is lacking, as is documentation
TODO: Data export
TODO: Currently a spawn hub is directly linked to this object, that should change with the mission controller
TODO: Saving of cell data and such, like mobs and events
TODO: Saving the boundary of the cell for use in determining the rez area required
TODO: Increased cell ID range, 0x1 to 0xf is too limiting.
TODO: A system for updating scripts in mission objects
TODO: Rezing other cell development things, like spawn points and such.
TODO: Staging objects that need to be copied in to spawn hubs.
TODO: Indexing objects and figuring out what goes where and how to find them later.

*/

#define SCRIPT_IS_ROOT
#define USE_EVENTS
#define USE_SHARED ["*"]
#define DB2_PRESERVE_ON_RESET

#include "../../_core.lsl"

integer BFL;
#define BFL_INIT 0x1
#define BFL_NAMED 0x2
#define BFL_EXTRA 0x4
#define BFL_BUSY 0x100

#define BFL_BEACONS 0x800

vector vec_RezPos;
string str_CellName;

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
#define DIAG_CELLNAME 5
#define DIAG_EXTRA 6
#define DAIG_RESET 7
#define DAIG_REINIT 8

#define DiagMainMenuText ("Menu of the main.\nCell Name: " + str_CellName)
#define DiagOptionsMessage ("Options:\nCell Name: " + str_CellName)

#define CellDiag$Init() Dialog$spawn(llGetOwner(), "New cell, helpful text for initial setup will go here.", (["Initialize"]), DAIG_INIT, "")
#define CellDiag$Main() Dialog$spawn(llGetOwner(), DiagMainMenuText, (["Save Cell", "Unique", "Index", "Options", "Reset Scripts"]), DIAG_ROOT, "")
#define CellDiag$Options() Dialog$spawn(llGetOwner(), DiagOptionsMessage, (["Cell Name", "Reinitialize", "Back"]), DIAG_OPTIONS, "")
#define CellDiag$CellName() Dialog$spawn(llGetOwner(), "Enter name for this cell:", [], DIAG_CELLNAME, "")
#define CellDiag$Extra() Dialog$spawn(llGetOwner(), "This would be some other setup step.", ["Muffin"], DIAG_EXTRA, "")
#define CellDiag$Reset() Dialog$spawn(llGetOwner(), "Reset scripts?", (["Yes", "Nope"]), DAIG_RESET, "")
#define CellDiag$Reinitialize() Dialog$spawn(llGetOwner(), "Reinitialize? Are you sure?", (["Yes", "Nope"]), DAIG_REINIT, "")

// Named timers
// #define TIMER_DELAYED_STARTUP "st"
// timerEvent(string id, string data) {
    // if(id == TIMER_DELAYED_STARTUP) {
        // Nothing currently
    // }
// }

default 
{
	// Start up the script
    state_entry()
    {
        resetAllOthers();
		initiateListen();
        DB2$ini();
        // multiTimer([TIMER_DELAYED_STARTUP, "", 4, FALSE]);
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
			if (!BFL&BFL_INIT) {
				if (KCCell$getinit()) {
					BFL = BFL|BFL_INIT;
					str_CellName = KCCell$getCellName();
				}
			}
			
            if(BFL&BFL_BUSY) {
                Dialog$spawn(llGetOwner(), "System is busy.", (["OK"]), DAIG_NOTICE, "");
            }
            else if (!BFL&BFL_INIT) {
				CellDiag$Init();
			}
            else {
                CellDiag$Main();
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
            
            if(menu == DAIG_NOTICE) {
				return;
			}
            else if (menu == DAIG_NOTHINGSPECIAL) {
                CellDiag$Main();
            }
            else if (menu == DAIG_PROCESSCOMPLETE) {
                BFL = BFL&~BFL_BUSY;
                CellDiag$Main();
            }
            else if(menu == DIAG_ROOT) {
                if(message == "Save Cell") {
                    BFL = BFL|BFL_BUSY;
					KCCellSave$save( str_CellName, KCCellSaveControllerCB$saveCellCB );
                }
				else if (message == "Unique") {
					KCCellSaveObjectsUnique$buildUniquesList( KCCellSaveControllerCB$uniqueCellCB );
				}
				else if (message == "Index") {
					KCCellSaveIndexer$index( str_CellName, KCCellSaveControllerCB$indexCellCB );
				}
                else if(message == "Options") {
                    CellDiag$Options();
                }
                else if(message == "Reset Scripts") {
                    CellDiag$Reset();
                }
            }
            else if (menu == DIAG_OPTIONS) {
				//TODO: Needs improvement
                if(message == "Cell Name") CellDiag$CellName();
                else if(message == "Back") CellDiag$Main();
                else if(message == "Reinitialize") CellDiag$Reinitialize();
            }
            else if (menu == DIAG_CELLNAME) {
				if(~llSubStringIndex(tr(message)," ")) {
					debugRare("ERROR: Cell name cannot contain white space.");
					CellDiag$CellName();
					return;
				}
				str_CellName = tr(message);
                KCCell$setCellName( str_CellName );
                debugUncommon("Cell name set to: " + str_CellName);
				BFL = BFL|BFL_NAMED;
                if (BFL&BFL_INIT) CellDiag$Options();
            }
            else if (menu == DIAG_EXTRA) {
                string str_extra = tr(message);
				if(str_extra != "Muffin") {
					debugRare("ERROR: You are a special snowflake.");
					CellDiag$Extra();
					return;
				}
                debugUncommon("Code purple: Muffin.");
				BFL = BFL|BFL_EXTRA;
                if (BFL&BFL_INIT) CellDiag$Options();
            }
			
			// Reset Scripts
            else if (menu == DAIG_RESET) {
                if(message == "Yes") {
					llResetScript();
				}
            }
			
			// Reinitialize
            else if (menu == DAIG_REINIT) {
                if(message == "Yes") {
					clearDB2();
					llResetScript();
				}
            }
			
			// Setup and initialization
			if(menu == DAIG_INIT || !(BFL&BFL_INIT)) {
				//TODO: step through setup process
				if (!(BFL&BFL_NAMED)) {
					CellDiag$CellName();
				}
				else if (!(BFL&BFL_EXTRA)){
					CellDiag$Extra();
				}
				else {
					BFL = BFL|BFL_INIT;
					KCCell$setinit(TRUE);
					Dialog$spawn(llGetOwner(), "Initialization completed.", (["OK"]), DAIG_NOTHINGSPECIAL, "");
				}
			}
        }
		
        else if (CB == KCCellSaveControllerCB$saveCellCB && METHOD == KCCellSaveMethod$save) {
            string msg;
            if((integer)method_arg(0) == 1) msg = "Save completed.\nObjs saved: "+method_arg(1)+"\nData length: "+method_arg(2)+"\nData Prims: "+method_arg(3);
            else msg = "Save failed.";
            Dialog$spawn(llGetOwner(), msg, (["OK"]), DAIG_PROCESSCOMPLETE, "");
        }
        else if (CB == KCCellSaveControllerCB$uniqueCellCB && METHOD == KCCellSaveObjectsUniqueMethod$buildUniquesList ) {
            string msg;
            if((integer)method_arg(0) == 1) msg = "Unique list completed.\n# Unique Objects: "+method_arg(1)+"\nData length: "+method_arg(2)+"\nData Prims: "+(string)KCbucket$getNumPrims(method_arg(2));
            else msg = "Unique list failed.";
            Dialog$spawn(llGetOwner(), msg, (["OK"]), DAIG_PROCESSCOMPLETE, "");
		}
        else if (CB == KCCellSaveControllerCB$indexCellCB && METHOD == KCCellSaveIndexerMethod$index ) {
            string msg;
            if((integer)method_arg(0) == 1) msg = "Index completed.\n# Data length: "+method_arg(1)+"\nData Prims: "+method_arg(2);
            else msg = "Index failed.";
            Dialog$spawn(llGetOwner(), msg, (["OK"]), DAIG_PROCESSCOMPLETE, "");
		}
        return;
    }
    
    
    if(method$byOwner) {
        if(METHOD == KCCellSaveControllerMethod$saveCell) {
            debugUncommon("KCCellSaveControllerMethod$saveCell: ");
            
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
