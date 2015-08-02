

#define KCLevelSaveMethod$save 700               // 

#define KCLevelSaveCB$setupBoundaryCB "Sb"                 // 
#define KCLevelSaveCB$getBoundaryCB "Sg"                 // 
#define KCLevelSaveCB$objectsSaveCB "So"                 // 



#define KCLevelSave$save( cb ) runMethod((string)LINK_THIS, "kc LevelSave", KCLevelSaveMethod$save, ([]), cb)



