#define DEBUG DEBUG_UNCOMMON

#define REZZED_CHANNEL 0xCA7CA7
#define REZZED_REPLY_CHANNEL 0xCA7CA75
#define PC_SALT 4832
#define TOKEN_SALT "There are better things do"

// Boost
#include <boost/preprocessor/cat.hpp>

// Include the XOBJ framework
#include "../xobj_core/_ROOT.lsl"
#include "../xobj_core/classes/jas Dialog.lsl"

// Our  libraries
#include "./libraries/kclib.lsl"
#include "./libraries/kc bucket.lsl"


// Cells and Objects
#include "./classes/kc Cell.h.lsl"
#include "./classes/kc BasicObj.h.lsl"

// Cell saving
#include "./classes/kc CellSaveController.h.lsl"
#include "./classes/kc CellPackager.h.lsl"
#include "./classes/kc CellSave.h.lsl"
#include "./classes/kc CellSaveObjects.h.lsl"
#include "./classes/kc CellSaveIndexer.h.lsl"
#include "./classes/kc CellSaveObjectsUnique.h.lsl"

// Cell loading
#include "./classes/kc CellLoad.h.lsl"
#include "./classes/kc CellLoadObjects.h.lsl"
#include "./classes/kc SpawnHub.h.lsl"


