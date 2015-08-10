
#define KCCellLoadObjectsMethod$init 1100               // 
#define KCCellLoadObjectsMethod$load 1101               // 
#define KCCellLoadObjectsMethod$rezObjectList 1102               // 


#define KCCellLoadObjectsCB$ping         "Lp"
#define KCCellLoadObjectsCB$loadingRezCB "Lr"


#define KCCellLoadObjects$init( json_Spawners, cb ) runMethod((string)LINK_SET, "kc CellLoadObjects", KCCellLoadObjectsMethod$init, ([json_Spawners]), cb)



#define KCCellLoadObjects$rezObjectList( str_SpawnHubName, json_Rez_Objects, int_Flags, cb ) runMethod((string)LINK_SET, "kc CellLoadObjects", KCCellLoadObjectsMethod$rezObjectList, ([str_SpawnHubName, json_Rez_Objects, int_Flags]), cb)


#define KCCellLoadObjects$load( int_Flags, vec_Pos, cb ) runMethod((string)LINK_THIS, "kc CellLoadObjects", KCCellLoadObjectsMethod$load, ([int_Flags, vec_Pos]), cb)




