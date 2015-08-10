/*
Level Save Boundary markers

Define one of these on the object
#define UPPER
#define LOWER

Lower marker is always the level controler and handles rezing the upper.
*/

#ifndef UPPER_BOUNDARY_MARKER_NAME
#define UPPER_BOUNDARY_MARKER_NAME "OTS Dev: Upper Boundary Marker"
#endif


#ifdef UPPER
    #ifdef LOWER
        #error Define UPPER _or_ lower, not both!
    #endif
#else
    #ifndef LOWER
        #error Define as UPPER or lower
    #endif
#endif


#ifdef UPPER
    #define SCRIPT_IS_ROOT
#else
    #define USE_SHARED ["config"]
#endif

#include "../../_core.lsl"

#ifdef LOWER
    kcCBSimple$vars;
#endif



makeSparkles( integer int_Link, integer int_Length) {
    // http://wiki.secondlife.com/wiki/LlParticleSystem
    // PSYS_PART_MAX_AGE = length in meters
    llLinkParticleSystem( int_Link, [
        PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_ANGLE,
        PSYS_SRC_BURST_RADIUS,0,
        PSYS_SRC_ANGLE_BEGIN,0,
        PSYS_SRC_ANGLE_END,0,
        PSYS_SRC_TARGET_KEY,llGetKey(),
        PSYS_PART_START_COLOR,<1.000000,0.000000,1.000000>,
        PSYS_PART_END_COLOR,<1.000000,1.000000,1.000000>,
        PSYS_PART_START_ALPHA,1,
        PSYS_PART_END_ALPHA,1,
        PSYS_PART_START_GLOW,0,
        PSYS_PART_END_GLOW,0,
        PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
        PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
        PSYS_PART_START_SCALE,<0.500000,0.500000,0.000000>,
        PSYS_PART_END_SCALE,<0.500000,0.500000,0.000000>,
        PSYS_SRC_TEXTURE,"",
        PSYS_SRC_MAX_AGE,0,
        PSYS_PART_MAX_AGE, int_Length,
        PSYS_SRC_BURST_RATE,1,
        PSYS_SRC_BURST_PART_COUNT,4,
        PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
        PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
        PSYS_SRC_BURST_SPEED_MIN,1.5,
        PSYS_SRC_BURST_SPEED_MAX,2,
        PSYS_PART_FLAGS,0
    ]);
}

list G_lst_Pointers;

default 
{
    state_entry()
    {
        #ifdef UPPER
            initiateListen();
        #endif
        
        G_lst_Pointers = [0,0,0];
        integer int_Index;
        links_each(int_LinkNum, str_LinkName,
            if ((int_LinkNum > 0) && (llGetSubString(str_LinkName, 0, 1) == db2$prefix)) {
                int_Index = (integer)llGetSubString(str_LinkName, -1, -1);
                G_lst_Pointers = llListReplaceList(G_lst_Pointers, [int_LinkNum], int_Index, int_Index);
            }
        )
        // debugUncommon("G_lst_Pointers: " + llDumpList2String(G_lst_Pointers, ", "));
        for(int_Index=0; int_Index<llGetListLength(G_lst_Pointers); int_Index++) {
            if (llList2Integer(G_lst_Pointers, int_Index) == 0) {
                debugRare("ERROR: Missing pointer prim.");
            }
        }
        
        // This script doesn't do much, for now.
        memLim(1.2);
        mem_usage();
    }
    
    #ifdef LOWER
    object_rez(key id) {
        if (llKey2Name(id) == UPPER_BOUNDARY_MARKER_NAME) {
            // debugUncommon("Upper marker rezzed");
            KCLevelSaveBoundary$setUpperBoundaryMarker( ((string)id) );
            kcCBSimple$fireCB( [1] );
        }
    }
    #else
    on_rez(integer int_RezParam){llResetScript();}
    
    changed(integer change){
        if(change&CHANGED_OWNER)llResetScript();
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
    if(method$isCallback) {
        return;
    }
    
	// ByOwner means the method was run by the owner of the prim
    if(method$byOwner) {
        if(METHOD == KCLevelSaveBoundaryMethod$setBeams) {
            // debugUncommon("KCLevelSaveBoundaryMethod$setBeams" );
            
            #ifdef LOWER
                string str_UpperMarkerUUID = KCLevelSaveBoundary$getUpperBoundaryMarker();
            #endif
            
            if ((integer)method_arg(0)) {
            
                #ifdef LOWER
                    list lst_ObjData = llGetObjectDetails(str_UpperMarkerUUID, [OBJECT_POS]);
                    if (lst_ObjData == []) {
                        debugRare("ERROR: Upper bounding marker missing.");
                        return;
                    }
                    vector vec_UpperBoundary = llList2Vector(lst_ObjData, 0);
                    vector vec_LowerBoundary = llGetRootPosition();
                        
                    KCLevelSaveBoundary$setBeamsUpper( str_UpperMarkerUUID, method_arg(0), vec_LowerBoundary );
                #else
                    
                    vector vec_UpperBoundary = llGetRootPosition();
                    vector vec_LowerBoundary = (vector)method_arg(1);
                    
                #endif
                
                // X
                // debugUncommon("x: " + (string)((integer)vec_UpperBoundary.x - (integer)vec_LowerBoundary.x));
                makeSparkles( llList2Integer(G_lst_Pointers, 0), ((integer)vec_UpperBoundary.x - (integer)vec_LowerBoundary.x)/2);
                
                // Y
                // debugUncommon("y: " + (string)((integer)vec_UpperBoundary.y - (integer)vec_LowerBoundary.y));
                makeSparkles( llList2Integer(G_lst_Pointers, 1), ((integer)vec_UpperBoundary.y - (integer)vec_LowerBoundary.y)/2);
                
                // Z
                // debugUncommon("z: " + (string)((integer)vec_UpperBoundary.z - (integer)vec_LowerBoundary.z));
                makeSparkles( llList2Integer(G_lst_Pointers, 2), ((integer)vec_UpperBoundary.z - (integer)vec_LowerBoundary.z)/2);
                
            }
            else {
                #ifdef LOWER
                    KCLevelSaveBoundary$setBeamsUpper( str_UpperMarkerUUID, method_arg(0), llGetRootPosition() );
                #endif
                llLinkParticleSystem(LINK_ALL_OTHERS, []);
            }
            
        }
        #ifdef LOWER
        else if(METHOD == KCLevelSaveBoundaryMethod$setup) {
            // debugUncommon("KCLevelSaveBoundaryMethod$setup" );
            
            string str_UpperMarkerUUID = KCLevelSaveBoundary$getUpperBoundaryMarker();
            // debugUncommon("Upper Boundary Marker: " + str_UpperMarkerUUID);
            
            list lst_ObjData = llGetObjectDetails(str_UpperMarkerUUID, [OBJECT_POS]);
            if (lst_ObjData != []) {
                CB_DATA = [TRUE, TRUE];
            }
            else {
                if(llGetInventoryType(UPPER_BOUNDARY_MARKER_NAME) == INVENTORY_OBJECT){
                    // kcCBSimple$delayCB();
                    llRezAtRoot( UPPER_BOUNDARY_MARKER_NAME, (llGetRootPosition()+<2,2,2>), ZERO_VECTOR, ZERO_ROTATION, 1 );
					CB_DATA = [TRUE, FALSE];
                } else {
                    debugRare("ERROR: could not find marker to rez. Object \""+UPPER_BOUNDARY_MARKER_NAME+"\" missing.");
					CB_DATA = [FALSE, FALSE];
                }
            }
        }
        else if(METHOD == KCLevelSaveBoundaryMethod$getBoundary) {
            // debugUncommon("KCLevelSaveBoundaryMethod$getBoundary" );
            
            list lst_ObjData = llGetObjectDetails(KCLevelSaveBoundary$getUpperBoundaryMarker(), [OBJECT_POS]);
            if (lst_ObjData == []) {
                debugRare("ERROR: Upper bounding marker missing.");
                CB_DATA = [FALSE];
            }
            vector vec_UpperBoundary = llList2Vector(lst_ObjData, 0);
            // debugUncommon("Upper Boundary at: " + FLOOR_VEC_STRING( vec_UpperBoundary ));
            CB_DATA = [TRUE, vec_UpperBoundary, llGetRootPosition()];
            
        }
        #endif
    }
	
	// Public code can be put here

    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
}
