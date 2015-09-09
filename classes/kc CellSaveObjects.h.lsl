

#define KCCellSaveObjectsMethod$save 1000               // 


#define KCCellSaveObjectsCB$indexCB "ix"                 // 

#define KCCellSaveObjects$save( str_CellName, cb ) runMethod((string)LINK_THIS, "kc CellSaveObjects", KCCellSaveObjectsMethod$save, ([ str_CellName ]), cb)

