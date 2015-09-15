


// #define KCBasicCell$clearAll() llRegionSay(REZZED_CHANNEL, "CLEARALL")

#define KCBasicCell$clearGroup( int_RezGroup ) llRegionSay(REZZED_CHANNEL, "C"+(string)int_RezGroup)

#define KCBasicCell$saveCellObjs( str_CellName ) llRegionSay(REZZED_CHANNEL, "S"+str_CellName)



// Responses to a request to be saved

// Simple: Basic object that just needs to be rezzed and placed at a given rotation.
#define KCBasicCell$saveReply( str_ExtraData ) llSleep(llFrand(10.0)); llRegionSay(REZZED_REPLY_CHANNEL, "S"+str_ExtraData)
#define KCBasicCell$saveReplySimple() llSleep(llFrand(10.0)); llRegionSay(REZZED_REPLY_CHANNEL, "S")


//TODO: this stuff or something like it
// Mob: 
#define KCBasicCell$saveReplyMob( json_Data ) llSleep(llFrand(10.0)); llRegionSay(REZZED_REPLY_CHANNEL, "M"+json_Data)



#define KCBasicCell$isOurCellName( str_ObjDesc, str_CellName ) (llGetSubString(str_ObjDesc, 0, llStringLength(str_CellName)) == str_CellName)
