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

// Level saving includes
#include "./classes/kc LevelSaveController.h.lsl"
#include "./classes/kc LevelSaveBoundary.h.lsl"
#include "./classes/kc LevelSave.h.lsl"
#include "./classes/kc LevelSaveObjects.h.lsl"

// Level loading includes
#include "./classes/kc LevelLoad.h.lsl"
#include "./classes/kc LevelLoadObjects.h.lsl"


