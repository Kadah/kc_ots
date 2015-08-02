
#define KCLevelLoadObjectsMethod$init 1100               // 
#define KCLevelLoadObjectsMethod$load 1101               // 
#define KCLevelLoadObjectsMethod$rezObjectList 1102               // 


#define KCLevelLoadObjectsCB$ping         "Lp"
#define KCLevelLoadObjectsCB$loadingRezCB "Lr"


#define KCLevelLoadObjects$init( json_Spawners, cb ) runMethod((string)LINK_SET, "kc LevelLoadObjects", KCLevelLoadObjectsMethod$init, ([json_Spawners]), cb)



#define KCLevelLoadObjects$rezObjectList( str_SpawnHubName, json_Rez_Objects, int_Flags, cb ) runMethod((string)LINK_SET, "kc LevelLoadObjects", KCLevelLoadObjectsMethod$rezObjectList, ([str_SpawnHubName, json_Rez_Objects, int_Flags]), cb)


#define KCLevelLoadObjects$load( int_Flags, vec_Pos, cb ) runMethod((string)LINK_THIS, "kc LevelLoadObjects", KCLevelLoadObjectsMethod$load, ([int_Flags, vec_Pos]), cb)




