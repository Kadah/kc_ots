

#define KCLevelLoadMethod$load 1200               // 

#define KCLevelLoadCB$objectLoadCB "Lo"                 // 



#define KCLevelLoad$load( int_Flags, vec_Pos, cb ) runMethod((string)LINK_THIS, "kc LevelLoad", KCLevelLoadMethod$load, ([int_Flags, vec_Pos]), cb)



