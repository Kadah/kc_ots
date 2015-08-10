/*
Cell Save

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
        
        if ((CB == KCCellSaveCB$setupBoundaryCB) && (METHOD == KCCellSaveBoundaryMethod$setup)) {
            BFL = BFL|BFL_BOUNDSSETUP;
            
            debugUncommon("setupBoundaryCB: " + method_arg(0));
        }
        else if ((CB == KCCellSaveCB$getBoundaryCB) && (METHOD == KCCellSaveBoundaryMethod$getBoundary)) {
            
            BFL = BFL|BFL_BOUNDS;
            
            debugUncommon("getBoundaryCB: " + method_arg(0));
            
            vector vec_Upper = (vector)method_arg(1);
            vector vec_Lower = (vector)method_arg(2);
            
            KCCellSaveObjects$save( vec_Upper, vec_Lower, KCCellSaveCB$objectsSaveCB );
            
        }
        else if ((CB == KCCellSaveCB$objectsSaveCB) && (METHOD == KCCellSaveObjectsMethod$save)) {
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
        if(METHOD == KCCellSaveMethod$save) {
            debugUncommon("KCCellSaveMethod$save");
            
            BFL = BFL|BFL_SAVING;
            KCCellSaveBoundary$getBoundary( KCCellSaveCB$getBoundaryCB );
            kcCBSimple$delayCB()
            return;
        }
        
    }
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
