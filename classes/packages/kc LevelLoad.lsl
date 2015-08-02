/*
Level Load
Functionally this is the level loading controller at this stage

This currently only supports test rezing from the Level Save Controler.
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
        
        if ((CB == KCLevelLoadCB$objectLoadCB) && (METHOD == KCLevelLoadObjectsMethod$load)) {
            BFL = BFL|BFL_OBJS;
            
            debugUncommon("objectLoadCB: " + method_arg(0));
            
            if((integer)method_arg(0) == 1) {
            
                kcCBSimple$fireCB( ([TRUE, method_arg(1), method_arg(2)]) );
            }
            else {
                kcCBSimple$fireCB( [FALSE] )
            }
        }
        
        return;
    }
    
	// Internal means the method was sent from within the linkset
    if(method$internal) {
        
    }
    
	// ByOwner means the method was run by the owner of the prim
    if(method$byOwner) {
        if(METHOD == KCLevelLoadMethod$load) {
            debugUncommon("KCLevelLoadMethod$load");
            
            BFL = BFL|BFL_LOADING;
            integer int_Flags = (integer)method_arg(0);
            vector vec_Pos = (vector)method_arg(1);
            KCLevelLoadObjects$load( int_Flags, vec_Pos, KCLevelLoadCB$objectLoadCB );
            
            kcCBSimple$delayCB()
            return;
        }
        
    }
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
