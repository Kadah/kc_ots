

#define KCCellSaveControllerMethod$saveCell 500   // 


#define KCCellSaveControllerCB$saveCellCB "Slv"



// Not currently used
//TODO: Exporting of staged cell data to mission controller for compilation in to distributable build
#define KCCellSaveController$saveCell( cb ) runMethod((string)LINK_SET, "kc CellSaveController", KCCellSaveControllerMethod$saveCell, ([]), cb)



// Data storage and retrieval for this cell's info

#define KCCellData$setNumObjs( int_NumObjs )           db2$setOther(       "mis", ["lvo"], (string)int_NumObjs)
#define KCCellData$getNumObjs()                        ((integer)db2$get(  "mis", ["lvo"]))
#define KCCellData$setCellDataEnd( int_DataIndex )     db2$setOther(       "mis", ["lve"], (string)int_DataIndex)
#define KCCellData$getCellDataEnd()                    ((integer)db2$get(  "mis", ["lve"]))                         ((vector)db2$get(   "mis", ["lrp"]))
#define KCCellData$setCellName( str_CellName )         db2$setOther(       "mis", ["cname"], str_CellName)
#define KCCellData$getCellName()                       db2$get(  "mis", ["cname"])


// 
#define KCCellData$setinit( int_init )					db2$setOther(       "mis", ["init"], (string)int_init)
#define KCCellData$getinit()							((integer)db2$get(  "mis", ["init"]))


