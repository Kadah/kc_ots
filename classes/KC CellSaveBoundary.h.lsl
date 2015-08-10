

#define KCLevelSaveBoundaryMethod$setup 800         // Returns [bool successful,bool already_setup]. returns FALSE,FALSE on error
#define KCLevelSaveBoundaryMethod$getBoundary 801   // 
#define KCLevelSaveBoundaryMethod$setBeams 802  	// 





#define KCLevelSaveBoundary$setup( cb ) runMethod((string)LINK_THIS, "kc LevelSaveBoundary", KCLevelSaveBoundaryMethod$setup, ([]), cb )
#define KCLevelSaveBoundary$getBoundary( cb ) runMethod((string)LINK_THIS, "kc LevelSaveBoundary", KCLevelSaveBoundaryMethod$getBoundary, ([]), cb )
#define KCLevelSaveBoundary$setBeams( int_Enable, cb ) runMethod((string)LINK_THIS, "kc LevelSaveBoundary", KCLevelSaveBoundaryMethod$setBeams, ([ int_Enable ]), cb )
#define KCLevelSaveBoundary$setBeamsUpper( id, int_Enable, vec_LowerBoundary ) runMethod((string)id, "kc LevelSaveBoundary", KCLevelSaveBoundaryMethod$setBeams, ([ int_Enable, vec_LowerBoundary ]), TNN )




#define KCLevelSaveBoundary$setUpperBoundaryMarker( id )    db2$setOther("config", ["ubm"], (string)id)
#define KCLevelSaveBoundary$getUpperBoundaryMarker()        db2$get("config", ["ubm"])

