/*
Cell Save

TODO: Much.

*/

#define USE_SHARED ["config","mis"]
#include "../../_core.lsl"

string str_CellName;

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
		DB2$ini();
    }
    
	// Timer event
    // timer(){multiTimer([]);}
    
	
    #include "xobj_core/_LM.lsl" 
	
	// Here's where you receive callbacks from running methods
    if(method$isCallback) {
        if ((CB == KCCellSaveCB$objectsSaveCB) && (METHOD == KCCellSaveObjectsMethod$save)) {
            BFL = (BFL&~BFL_SAVING)|BFL_OBJS;
            if((integer)method_arg(0) == 1) {
            
                kcCBSimple$fireCB( ([TRUE, method_arg(1), method_arg(2), method_arg(3)]) );
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
			
			str_CellName = method_arg(0);
            
			KCCellSaveObjects$save( str_CellName, KCCellSaveCB$objectsSaveCB );
			
            kcCBSimple$delayCB()
            return;
        }
        
    }
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
