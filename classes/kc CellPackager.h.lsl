

#define KCCellPackagerMethod$giveFolder 1500               // 
#define KCCellPackagerMethod$start 1501               // 
#define KCCellPackagerMethod$run 1502               // 
#define KCCellPackagerMethod$end 1503               // 



#define KCCellCellPackager$giveFolder( cb ) runMethod((string)LINK_SET, "kc CellPackager", KCCellPackagerMethod$giveFolder, ([]), cb)

#define KCCellCellPackager$start( cb ) runMethod((string)LINK_SET, "kc CellPackager", KCCellPackagerMethod$start, ([]), cb)

#define KCCellCellPackager$run( cb ) runMethod((string)LINK_SET, "kc CellPackager", KCCellPackagerMethod$run, ([]), cb)

#define KCCellCellPackager$end( cb ) runMethod((string)LINK_SET, "kc CellPackager", KCCellPackagerMethod$end, ([]), cb)
