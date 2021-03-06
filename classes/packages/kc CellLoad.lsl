/*
Cell Load
Functionally this is the cell loading controller at this stage

This currently only supports test rezing from the Cell Save Controler.
TODO: This will need to also support rezing in the distributable mission package.
TODO: Possible support for loading data from other sources like notecards

*/

#define USE_SHARED ["config"]
#include "../../_core.lsl"


integer BFL;
#define BFL_OBJS 0x1
#define BFL_LOADING 0x2
#define BFL_DONE 0x3


kcCBSimple$vars;

string str_CellName;
string str_DataAddress;
vector vec_Pos;
rotation rot_Rot;


// Named timers
timerEvent(string id, string data) {
    
}

// When event is received
onEvt(string script, integer evt, string data) {
	if(script == "kc Core" && evt == evt$CONFIG_LOADED) {
        KCConfig_LoadVars();
        KCCore$moduleReady();
    }
}

default 
{
	// Start up the script
    state_entry()
    {
        mem_usage();
    }
    
	// Timer event
    timer(){multiTimer([]);}
    
	
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
        
        if (CB == KCCellLoadCB$objectLoadInitCB) {
			if((integer)method_arg(0) == 1) {
				
				KCCellLoadObjects$load( str_DataAddress, vec_Pos, rot_Rot , KCCellLoadCB$objectLoadCB );
			}
			else {
				kcCBSimple$fireCB( ([FALSE, method_arg(1)]) );
			}
		}
        else if ((CB == KCCellLoadCB$objectLoadCB) && (METHOD == KCCellLoadObjectsMethod$load)) {
            // BFL = BFL|BFL_OBJS;
            
			BFL = (BFL&~BFL_LOADING);
			
            debugUncommon("objectLoadCB: " + method_arg(0));
            
            if((integer)method_arg(0) == 1) {
            
                kcCBSimple$fireCB( ([TRUE, method_arg(1), method_arg(2)]) );
            }
            else {
                kcCBSimple$fireCB( ([FALSE, method_arg(1)]) )
            }
        }
        
        return;
    }
    
	// Internal means the method was sent from within the linkset
    if(method$internal) {
        
    }
    
	// ByOwner means the method was run by the owner of the prim
    if(method$byOwner) {
        if(METHOD == KCCellLoadMethod$load) {
            debugUncommon("KCCellLoadMethod$load");
            
            BFL = BFL|BFL_LOADING;
			
            str_CellName = method_arg(0);
            vec_Pos = (vector)method_arg(1);
			
			//TODO: temp hack
			str_DataAddress = KCbucket$dataAddress_Encode( 0 );
			rot_Rot = ZERO_ROTATION;
			
			
			KCCellLoadObjects$init( llList2Json(JSON_ARRAY, ["Mission"]), KCCellLoadCB$objectLoadInitCB );
			
            
            
            kcCBSimple$delayCB()
            return;
        }
        
    }
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
