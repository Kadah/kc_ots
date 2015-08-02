

#define KCLevelSaveControllerMethod$saveLevel 500   // 


#define KCLevelSaveControllerCB$boundarySetupCB "Bst"
#define KCLevelSaveControllerCB$boundaryTestCB "Btt"
#define KCLevelSaveControllerCB$saveLevelCB "Slv"
#define KCLevelSaveControllerCB$loadLevelCB "Llv"



// Not currently used
//TODO: Exporting of staged level data to mission controller for compilation in to distributable build
#define KCLevelSaveController$saveLevel( cb ) runMethod((string)LINK_SET, "kc LevelSaveController", KCLevelSaveControllerMethod$saveLevel, ([]), cb)



// Data storage and retrieval for this level's info

#define KCLevel$setNumObjs( int_NumObjs )           db2$setOther(       "mis", ["lvo"], (string)int_NumObjs)
#define KCLevel$getNumObjs()                        ((integer)db2$get(  "mis", ["lvo"]))
#define KCLevel$setLevelDataEnd( int_DataIndex )    db2$setOther(       "mis", ["lve"], (string)int_DataIndex)
#define KCLevel$getLevelDataEnd()                   ((integer)db2$get(  "mis", ["lve"]))

//TODO: For testing
#define KCLevel$setRezPos( vec_RezPos )             db2$setOther(       "mis", ["lrp"], FLOOR_VEC_STRING( vec_RezPos ))
#define KCLevel$getRezPos()                         ((vector)db2$get(   "mis", ["lrp"]))

//TODO: Needs improvement
#define KCLevel$setLevelid( int_Levelid )           db2$setOther(       "mis", ["lid"], (string)int_Levelid)
#define KCLevel$getLevelid()                        ((integer)db2$get(  "mis", ["lid"]))


// 
#define KCLevel$setinit( int_init )					db2$setOther(       "mis", ["init"], (string)int_init)
#define KCLevel$getinit()							((integer)db2$get(  "mis", ["init"]))


