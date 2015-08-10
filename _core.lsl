#define DEBUG DEBUG_UNCOMMON

#define REZZED_CHANNEL 0xCA7CA7
#define REZZED_REPLY_CHANNEL 0xCA7CA75
#define PC_SALT 4832
#define TOKEN_SALT "There are better things do"

// Include the XOBJ framework
#include "xobj_core/_ROOT.lsl"
#include "xobj_core/classes/jas Dialog.lsl"

// Our  libraries
#include "./libraries/kclib.lsl"

#include "./classes/kc BasicCell.h.lsl"
#include "./classes/kc SpawnHub.h.lsl"

// Cell saving includes
#include "./classes/kc CellSaveController.h.lsl"
#include "./classes/kc CellSaveBoundary.h.lsl"
#include "./classes/kc CellSave.h.lsl"
#include "./classes/kc CellSaveObjects.h.lsl"

// Cell loading includes
#include "./classes/kc CellLoad.h.lsl"
#include "./classes/kc CellLoadObjects.h.lsl"


