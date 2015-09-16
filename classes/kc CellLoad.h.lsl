

#define KCCellLoadMethod$load 1200               // 

#define KCCellLoadCB$objectLoadCB "Lo"                 // 



#define KCCellLoad$load( str_CellName, vec_Pos, cb ) runMethod((string)LINK_THIS, "kc CellLoad", KCCellLoadMethod$load, ([str_CellName, vec_Pos]), cb)



