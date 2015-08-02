

#define KCSpawnHubMethod$ping 300               // 
#define KCSpawnHubMethod$remove 301             // 
#define KCSpawnHubMethod$rezObject 302          // 
#define KCSpawnHubMethod$rezObjectList 303     // 


#define KCSpawnHub$pingLocal( cb ) runMethod((string)LINK_SET, "kc SpawnHub", KCSpawnHubMethod$ping, ([]), cb)
#define KCSpawnHub$pingRemote( cb ) runOmniMethod("kc Spawn Hub", KCSpawnHubMethod$ping, ([]), cb)

#define KCSpawnHub$remove( str_SpawnHubName ) runOmniMethod("kc SpawnHub", KCSpawnHubMethod$remove, ([str_SpawnHubName]), TNN)

#define KCSpawnHub$rezObject( uuidOrLink, str_ObjectName, vec_Pos, rot_Rot, int_Flags, str_SENDER_SCRIPT, cb ) runMethod(uuidOrLink, "kc SpawnHub", KCSpawnHubMethod$rezObject, ([str_ObjectName, vec_Pos, rot_Rot, int_Flags, str_SENDER_SCRIPT]), cb)

// json_Rez_Objects = [str_ObjectName, vec_Pos, rot_Rot]
#define KCSpawnHub$rezObjectList( uuidOrLink, json_Rez_Objects, int_Flags, str_SENDER_SCRIPT, cb ) runMethod(uuidOrLink, "kc SpawnHub", KCSpawnHubMethod$rezObjectList, ([json_Rez_Objects, int_Flags, str_SENDER_SCRIPT]), cb)

