

#define KCCellLoadMethod$load 1200               // 

#define KCCellLoadCB$objectLoadCB "Lo"                 // 



#define KCCellLoad$load( int_Flags, vec_Pos, cb ) runMethod((string)LINK_THIS, "kc CellLoad", KCCellLoadMethod$load, ([int_Flags, vec_Pos]), cb)



