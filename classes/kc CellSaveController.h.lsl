

#define KCCellSaveControllerMethod$saveCell 500   // 


#define KCCellSaveControllerCB$saveCellCB "Cs"
#define KCCellSaveControllerCB$uniqueCellCB "Cu"
#define KCCellSaveControllerCB$indexCellCB "Ci"



// Not currently used
//TODO: Exporting of staged cell data to mission controller for compilation in to distributable build
#define KCCellSaveController$saveCell( cb ) runMethod((string)LINK_SET, "kc CellSaveController", KCCellSaveControllerMethod$saveCell, ([]), cb)





