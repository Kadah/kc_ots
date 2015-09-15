/*
Test Object

Example object that stores some extra info in its description in the form of:
cell_name;extra_data

*/

#include "../../_core.lsl"

integer BFL;
// BFL_SPAWNED: object was rezed by mission and can be cleaned up.
#define BFL_SPAWNED 0x1

integer int_CleanupGroup;

default 
{
    on_rez(integer int_Pos) {
        if (int_Pos != 0) {
            // How to read vectors for rezed objects
            // 1. Get difference of vec_RezPos and floor(vec_RezPos) for minor vector
            // 2. Convert int_Pos in to get major vector
            // 3. Add both to get final vector
            vector vec_Pos = llGetRootPosition();
            vec_Pos = (vec_Pos - FLOOR_VEC(vec_Pos)) + KCLib$integerToVector( int_Pos );
            llSetRegionPos(vec_Pos);
			
            int_CleanupGroup = KCLib$integerToVectorFlags( int_Pos );
			if (int_CleanupGroup > 0) {
				BFL = BFL|BFL_SPAWNED;
			}
            
            // debugUncommon("on_rez: " + (string)int_Pos + " - FinalPos: " + (string)vec_Pos + " - flags: " + (string)flags);
        }
    }
    
    state_entry() {
        llListen(REZZED_CHANNEL,"","","");
        memLim(1.2);
    }
    
    listen(integer chan, string name, key id, string message){
        if (llGetOwnerKey(id) == llGetOwner()) {
            if (BFL&BFL_SPAWNED && llGetSubString(message, 0, 0) == "C") {
                if (int_CleanupGroup == (integer)llGetSubString(message, 1, -1)) {
                    llDie();
                }
            }
            else if (llGetSubString(message, 0, 0) == "S") {
				string str_CellName = llGetSubString(message, 1, -1);
				string str_Desc = llGetObjectDesc();
				if (KCBasicCell$isOurCellName( str_Desc, str_CellName )) {
					KCBasicCell$saveReply( llList2String(llParseStringKeepNulls(str_Desc, [";"], []), 1) );
				}
            }
        }
    } 
}
