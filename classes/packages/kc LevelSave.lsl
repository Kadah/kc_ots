/*
Level Save

TODO: Much.

*/

#define USE_SHARED ["config","mis"]
#include "../../_core.lsl"


integer BFL;
#define BFL_BOUNDSSETUP 0x1
#define BFL_BOUNDS 0x2
#define BFL_OBJS 0x4
#define BFL_SAVING 0x8
#define BFL_DONE 0x10


kcCBSimple$vars;



// Named timers
// timerEvent(string id, string data) {
    
// }

default 
{
	// Start up the script
    state_entry()
    {
        mem_usage();
    }
    
	// Timer event
    // timer(){multiTimer([]);}
    
	
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
        
        if ((CB == KCLevelSaveCB$setupBoundaryCB) && (METHOD == KCLevelSaveBoundaryMethod$setup)) {
            BFL = BFL|BFL_BOUNDSSETUP;
            
            debugUncommon("setupBoundaryCB: " + method_arg(0));
        }
        else if ((CB == KCLevelSaveCB$getBoundaryCB) && (METHOD == KCLevelSaveBoundaryMethod$getBoundary)) {
            
            BFL = BFL|BFL_BOUNDS;
            
            debugUncommon("getBoundaryCB: " + method_arg(0));
            
            vector vec_Upper = (vector)method_arg(1);
            vector vec_Lower = (vector)method_arg(2);
            
            KCLevelSaveObjects$save( vec_Upper, vec_Lower, KCLevelSaveCB$objectsSaveCB );
            
        }
        else if ((CB == KCLevelSaveCB$objectsSaveCB) && (METHOD == KCLevelSaveObjectsMethod$save)) {
            BFL = (BFL&~BFL_SAVING)|BFL_OBJS;
            if((integer)method_arg(0) == 1) {
            
                kcCBSimple$fireCB( ([TRUE, method_arg(1)]) );
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
        if(METHOD == KCLevelSaveMethod$save) {
            debugUncommon("KCLevelSaveMethod$save");
            
            BFL = BFL|BFL_SAVING;
            KCLevelSaveBoundary$getBoundary( KCLevelSaveCB$getBoundaryCB );
            kcCBSimple$delayCB()
            return;
        }
        
    }
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
