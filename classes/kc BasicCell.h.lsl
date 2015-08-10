


// #define KCBasicCell$clearAll() llRegionSay(REZZED_CHANNEL, "CLEARALL")

#define KCBasicCell$clearGroup( int_RezGroup ) llRegionSay(REZZED_CHANNEL, "C"+(string)int_RezGroup)

#define KCBasicCell$saveCellObjs( int_RezGroup, vec_UpperBoundary, vec_LowerBoundary ) llRegionSay(REZZED_CHANNEL, "S"+llList2CSV([int_RezGroup, FLOOR_VEC_STRING(vec_UpperBoundary), FLOOR_VEC_STRING(vec_LowerBoundary)]))



// Responses to a request to be saved

// Simple: Basic object that just needs to be rezzed and placed at a given rotation.
#define KCBasicCell$saveReplySimple() llSleep(llFrand(10.0)); llRegionSay(REZZED_REPLY_CHANNEL, "S")


//TODO: this stuff or something like it
// Mob: 
#define KCBasicCell$saveReplyMob( json_Data ) llSleep(llFrand(10.0)); llRegionSay(REZZED_REPLY_CHANNEL, "M"+json_Data)


