

#define KCCellSaveMethod$save 700               // 

#define KCCellSaveCB$setupBoundaryCB "Sb"                 // 
#define KCCellSaveCB$getBoundaryCB "Sg"                 // 
#define KCCellSaveCB$objectsSaveCB "So"                 // 



#define KCCellSave$save( cb ) runMethod((string)LINK_THIS, "kc CellSave", KCCellSaveMethod$save, ([]), cb)



