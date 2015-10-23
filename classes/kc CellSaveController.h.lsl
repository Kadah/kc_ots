

#define KCCellSaveControllerMethod$saveCell 500   // 


#define KCCellSaveControllerCB$saveCellCB "Cs"
#define KCCellSaveControllerCB$uniqueCellCB "Cu"
#define KCCellSaveControllerCB$indexCellCB "Ci"
#define KCCellSaveControllerCB$packageFolderCB "Cpf"
#define KCCellSaveControllerCB$packageStartCB "Cps"
#define KCCellSaveControllerCB$packageRunCB "Cpr"
#define KCCellSaveControllerCB$packageEndCB "Cpe"

//TODO: temp testing
#define KCCellSaveControllerCB$loadCellCB "Cl"



// Not currently used
//TODO: Exporting of staged cell data to mission controller for compilation in to distributable build
#define KCCellSaveController$saveCell( cb ) runMethod((string)LINK_SET, "kc CellSaveController", KCCellSaveControllerMethod$saveCell, ([]), cb)





