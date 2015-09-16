





// Data storage and retrieval for this cell's info
#define KCCell$setNumObjs( int_NumObjs )           db2$setOther(       "mis", ["clo"], (string)int_NumObjs)
#define KCCell$getNumObjs()                        ((integer)db2$get(  "mis", ["clo"]))
#define KCCell$setCellDataLength( int_DataLength )     db2$setOther(       "mis", ["cld"], (string)int_DataLength)
#define KCCell$getCellDataLength()                    ((integer)db2$get(  "mis", ["cld"]))
#define KCCell$setCellName( str_CellName )         db2$setOther(       "mis", ["clname"], str_CellName)
#define KCCell$getCellName()                       db2$get(  "mis", ["clname"])


// 
#define KCCell$setinit( int_init )					db2$setOther(       "mis", ["init"], (string)int_init)
#define KCCell$getinit()							((integer)db2$get(  "mis", ["init"]))
