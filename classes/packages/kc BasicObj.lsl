/*
Basic Object

A basic rezable object

Template off this for more complex objects

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
				if (KCBasicCell$isOurCellName( llGetObjectDesc(), str_CellName )) {
					KCBasicCell$saveReplySimple();
				}
				
				// vector vec_Pos = llGetRootPosition();
                // list lst_data = llCSV2List(llGetSubString(message, 1, -1));
                // // integer int_Cellid = (integer)llList2String(lst_data, 0);
                // vector vec_UpperBoundary = (vector)llList2String(lst_data, 1);
                // vector vec_LowerBoundary = (vector)llList2String(lst_data, 2);
                
                // // debugUncommon("Pos: " + (string)vec_Pos + " U:" + (string)vec_UpperBoundary + " L:" + (string)vec_LowerBoundary);
                
                // // if ((vec_Pos.x >= vec_Lower.x) && (vec_Pos.y >= vec_Lower.y) && (vec_Pos.z >= vec_Lower.z)
                // // && (vec_Pos.x <= vec_Upper.x) && (vec_Pos.y <= vec_Upper.y) && (vec_Pos.z <= vec_Upper.z)) {
                // if (KCLib$isVectorWithinRect( vec_Pos, vec_UpperBoundary, vec_LowerBoundary )) {
                    // KCBasicCell$saveReplySimple();
                    
                // }
            }
        }
    } 
}
