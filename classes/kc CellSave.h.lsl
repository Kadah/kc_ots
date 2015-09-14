

#define KCCellSaveMethod$save 700               // 


#define KCCellSaveCB$objectsSaveCB "So"                 // 



#define KCCellSave$save( str_CellName, cb ) runMethod((string)LINK_THIS, "kc CellSave", KCCellSaveMethod$save, ([str_CellName]), cb)



