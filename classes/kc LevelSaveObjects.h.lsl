

#define KCLevelSaveObjectsMethod$save 1000               // 



#define KCLevelSaveObjects$save( vec_Upper, vec_Lower, cb ) runMethod((string)LINK_THIS, "kc LevelSaveObjects", KCLevelSaveObjectsMethod$save, ([ vec_Upper, vec_Lower ]), cb)



list G_lst_BlockDB;
updateBlockDBPrims( integer int_Wipe ) {
    // Build list of RDB prims (copied from DB2)
    // Clear all old data
    G_lst_BlockDB = [];
    list prims; // Prim IDS
    list idx;    // Prim NR
    integer i; integer f;
    links_each(int_LinkNum, str_LinkName, 
        if("RBD" == llGetSubString(str_LinkName, 0, 2)) {
            if (llGetLinkNumberOfSides(int_LinkNum) != 9) {
                debugRare("ERROR: RDB prim \""+str_LinkName+"\" not set up correctly.");
                return;
            }
            if (int_Wipe) {
                for(f=0; f < 9; f++) {
                    llClearLinkMedia(int_LinkNum, f);
                }
            }
            prims += int_LinkNum;
            idx += (integer)llGetSubString(str_LinkName, 3, -1);
        }    
    )
    for(i=0; i<llGetListLength(idx); i++)G_lst_BlockDB += 0;
    for(i=0; i<llGetListLength(idx); i++)G_lst_BlockDB = llListReplaceList(G_lst_BlockDB, llList2List(prims,i,i), llList2Integer(idx,i),llList2Integer(idx,i));
    // DB can start with 0 or 1
    if(llList2Integer(G_lst_BlockDB,0) == 0)G_lst_BlockDB = llDeleteSubList(G_lst_BlockDB,0,0);
}


