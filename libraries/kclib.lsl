#ifndef KCUTIL
#define KCUTIL

/*
	This file is a mess

	A collection of random universal functions to make life more complicated

	
*/

#include "./kcconst.lsl"


#define mem_usage() debugUncommon(cls$name + " - " + (string)llGetFreeMemory() + " bytes free " + (string)llGetUsedMemory() + " bytes used of " + (string)llGetMemoryLimit() + " bytes limit")


// Simple delayed callback, single level
// Declare kcCBSimple$vars; within your variables section.
// Do kcCBSimple$delayCB();return; at the end of the method being delayed.
// Call kcCBSimple$fireCB(([returned,data])); to fire callback.
#define kcCBSimple$vars               string delayed_callback_id; integer delayed_callback_method = -1; string delayed_callback_cb; string delayed_callback_script
#define kcCBSimple$delayCB()          if(CB != ""){delayed_callback_id = (string)id; delayed_callback_method = METHOD; delayed_callback_cb = CB; delayed_callback_script = SENDER_SCRIPT;}
#define kcCBSimple$fireCB( CB_DATA )  if(delayed_callback_cb != ""){sendCallback(delayed_callback_id, delayed_callback_script, delayed_callback_method, llList2Json(JSON_ARRAY, CB_DATA), delayed_callback_cb); delayed_callback_id = ""; delayed_callback_method = -1; delayed_callback_cb = ""; delayed_callback_script = "";}





// This shortcut template macro takes a vector and expands it for passing to functions that take x,y,z integers
#define VEC_TO_INTS_PRAMS(vec) (integer)vec.x, (integer)vec.y, (integer)vec.z

// string hex(integer bits) {
   // integer lsn; // least significant nybble
   // string nybbles = "";
   // do
       // nybbles = llGetSubString("0123456789ABCDEF", lsn = (bits & 0xF), lsn) + nybbles;
   // while (bits = (0xfffFFFF & (bits >> 4)));
   // return nybbles;
// }
// http://wiki.secondlife.com/wiki/Efficient_Hex
string hex(integer value)
{
    string lead = "0x";
    if (value & 0x80000000) // means (integer < 0) but is smaller and faster
    {
        lead = "-0x";
        value = -value; // unnecessary when value == -0x80000000
    }
 
    integer lsn; // least significant nybble
    string nybbles = "";
    do
    {
        nybbles = llGetSubString("0123456789abcdef", lsn = (value & 0xF), lsn) + nybbles;
    }
    while ((value = (0xfffFFFF & (value >> 4))));
 
    return lead + nybbles;
}
// http://wiki.secondlife.com/wiki/Float2Hex
string hexc="0123456789ABCDEF";//faster
string Float2Hex(float input)// Doubles Unsupported, LSO Safe, Mono Safe
{// Copyright Strife Onizuka, 2006-2007, LGPL, http://www.gnu.org/copyleft/lesser.html or (cc-by) http://creativecommons.org/licenses/by/3.0/
    if(input != (integer)input)//LL screwed up hex integers support in rotation & vector string typecasting
    {
        string str = (string)input;
        if(!~llSubStringIndex(str, ".")) return str; //NaN and Infinities, it's quick, it's easy.
        float unsigned = llFabs(input);//logs don't work on negatives.
        integer exponent = llFloor((llLog(unsigned) / 0.69314718055994530941723212145818));//floor(log2(b)) + rounding error
        integer mantissa = (integer)((unsigned / (float)("0x1p"+(string)(exponent -= ((exponent >> 31) | 1)))) * 0x4000000);//shift up into integer range
        integer index = (integer)(llLog(mantissa & -mantissa) / 0.69314718055994530941723212145818);//index of first 'on' bit
        str = "p" + (string)(exponent + index - 26);
        mantissa = mantissa >> index;
        do
            str = llGetSubString(hexc, 15 & mantissa, 15 & mantissa) + str;
        while(mantissa = mantissa >> 4);
        if(input < 0)
            return "-0x" + str;
        return "0x" + str;
    }//integers pack well so anything that qualifies as an integer we dump as such, supports negative zero
    return llDeleteSubString((string)input,-7,-1);//trim off the float portion, return an integer
}

// http://wiki.secondlife.com/wiki/User:Strife_Onizuka/Float_Functions
// Float <-Union-> Integer
integer fui(float a)//Mono Safe, LSO Safe, Doubles Unsupported, LSLEditor Unsafe
{//union float to integer
    if((a)){//is it nonzero?
        integer b = 0x80000000 * (a < 0);//the sign
        if((a = llFabs(a)) < 2.3509887016445750159374730744445e-38)//Denormalized range check & last stride of normalized range
            return b | (integer)(a / 1.4012984643248170709237295832899e-45);//the math overlaps; saves cpu time.
        if(a > 3.4028234663852885981170418348452e+38)//Round up to infinity
            return b | 0x7F800000;//Positive or negative infinity
        if(a > 1.4012984643248170709237295832899e-45){//It should at this point, except if it's NaN
            integer c = ~-llFloor(llLog(a) * 1.4426950408889634073599246810019);//extremes will error towards extremes. following yuch corrects it
            return b | (0x7FFFFF & (integer)(a * (0x1000000 >> c))) | ((126 + (c = ((integer)a - (3 <= (a *= llPow(2, -c))))) + c) * 0x800000);
        }//the previous requires a lot of unwinding to understand it.
        return 0x7FC00000;//NaN time! We have no way to tell NaN's apart so lets just choose one.
    }//Mono does not support indeterminates so I'm not going to worry about them.
    return 0x80000000 * ((string)a == "-0.000000");//for grins, detect the sign on zero. it's not pretty but it works.
}

float iuf(integer a)
{//union integer to float
    if(!(0x7F800000 & ~a))
        return (float)llGetSubString("-infnan", 3 * ~!(a & 0x7FFFFF), ~a >> 31);
    return llPow(2, (a | !a) + 0xffffff6a) * (((!!(a = (0xff & (a >> 23)))) * 0x800000) | (a & 0x7fffff)) * (1 | (a >> 31));
}

// Base64-Float
string fuis(float b) { return llGetSubString(llIntegerToBase64(fui(b)),0,5); }
float siuf(string b) { return iuf(llBase64ToInteger(b)); }

integer max( integer x, integer y) {
   if( y > x ) return y;
   return x;
}
#define minAbs( x, y ) (( ( llAbs(x) >= llAbs(y) ) * y ) + ( ( llAbs(x) < llAbs(y) ) * x ))
#define minf( x, y ) (( ( llAbs( x >= y ) ) * y ) + ( ( llAbs( x < y ) ) * x ))



// Converts a floored vector within <0,0,0> to <255,255,4095> in to 28-bits integer
#define KCLib$vectorToInteger( vec_Pos ) (((integer)vec_Pos.x & 0xff) | (((integer)vec_Pos.y & 0xff)  << 8) | (((integer)vec_Pos.z & 0xfff) << 16))
#define KCLib$integerToVector( int_Pos ) (< (int_Pos & 0xff), ((int_Pos >> 8) & 0xff), ((int_Pos >> 16) & 0xfff) >)
// Same as above but uses the remaining 4-bits for flags/extra data
#define KCLib$vectorToIntegerFlags( vec_Pos, flags ) (((integer)vec_Pos.x & 0xff) | (((integer)vec_Pos.y & 0xff)  << 8) | (((integer)vec_Pos.z & 0xfff) << 16)| ((flags & 0xf) << 28))
#define KCLib$integerToVectorFlags( int_Pos ) ((int_Pos >> 28) & 0xf)

#define KCLib$vectorToBase64( vec_Pos ) (fuis(vec_Pos.x) + fuis(vec_Pos.y) + fuis(vec_Pos.z))
#define KCLib$rotationToBase64( rot_Rot ) (fuis(rot_Rot.x) + fuis(rot_Rot.y) + fuis(rot_Rot.z) + fuis(rot_Rot.s))

#define KCLib$base64ToVector( str_Data, int_Offest ) (< siuf(llGetSubString(str_Data, (0 + int_Offest), (5 + int_Offest))), siuf(llGetSubString(str_Data, (6 + int_Offest), (11 + int_Offest))), siuf(llGetSubString(str_Data, (12 + int_Offest), (17 + int_Offest))) >)
#define KCLib$base64ToRotation( str_Data, int_Offest ) (< siuf(llGetSubString(str_Data, (0 + int_Offest), (5 + int_Offest))), siuf(llGetSubString(str_Data, (6 + int_Offest), (11 + int_Offest))), siuf(llGetSubString(str_Data, (12 + int_Offest), (17 + int_Offest))), siuf(llGetSubString(str_Data, (18 + int_Offest), (23 + int_Offest))) >)




// Long bitmasked integers takes 1-11 characters as a string, they can be transmitted reliably as 6 base64 characters
#define KCLib$integerToString( int_Number ) llGetSubString(llIntegerToBase64(int_Number),0, 5)
#define KCLib$stringToInteger( str_Number ) llBase64ToInteger(str_Number)


#define KCLib$isVectorWithinRect( vec_Pos, vec_Upper, vec_Lower ) ((vec_Pos.x >= vec_Lower.x) && (vec_Pos.y >= vec_Lower.y) && (vec_Pos.z >= vec_Lower.z) && (vec_Pos.x < vec_Upper.x) && (vec_Pos.y < vec_Upper.y) && (vec_Pos.z < vec_Upper.z))


// Floors valuse in vectors
// String one useful as an alternative to (string)vector for debug output and in comm when decimals are not needed
#define FLOOR_VEC( vec ) (< (integer)vec.x, (integer)vec.y, (integer)vec.z >)
#define FLOOR_VEC_STRING( vec_Pos ) ("<" + (string)((integer)vec_Pos.x) + "," + (string)((integer)vec_Pos.y) + "," + (string)((integer)vec_Pos.z) + ">")




// *** util_rotate_around_point ***
// Rotate a point at right angles around the give center point of a rect
// The z component of vec_point and vec_center is not important
// Also used to translate the center point of a rectangle
vector util_rotate_around_point( vector vec_point, vector vec_center, rotation rot_rot ) {
    if (rot_rot == ROT_90) {
        vec_point = vec_point - vec_center;
        return < -vec_point.y, vec_point.x, vec_point.z > + < vec_center.y, vec_center.x, vec_center.z >;
    }
    else if (rot_rot == ROT_180) {
        vec_point = vec_point - vec_center;
        return < -vec_point.x, -vec_point.y, vec_point.z > + vec_center;
    }
    else if (rot_rot == ROT_270) {
        vec_point = vec_point - vec_center;
        return < vec_point.y, -vec_point.x, vec_point.z > + < vec_center.y, vec_center.x, vec_center.z >;
    }
    // ZERO_ROTATION
    return vec_point;
}
// This will rotate a point around another point for the given rotation, but this isn't what's fully needed here.
// vector util_rotate_around_point( vector vec_point, vector vec_center, rotation rot_rot ) {
    // return vec_center + ((vec_point - vec_center) * rot_rot);
// }






// vector grid_util_move_vector_dir( vector vec_Vec, integer int_Dir ) {
    // if (int_Dir == DIR_NORTH)      vec_Vec += VEC_NORTH;
    // else if (int_Dir == DIR_EAST)  vec_Vec += VEC_EAST;
    // else if (int_Dir == DIR_SOUTH) vec_Vec += VEC_SOUTH;
    // else if (int_Dir == DIR_WEST)  vec_Vec += VEC_WEST;
    // return vec_Vec;
// }


// #define util_xyz_to_cell_index( int_X, int_Y, int_Z ) ((int_X & 0x3ff) | ((int_Y & 0x3ff) << 10) | ((int_Z & 0x3ff) << 20))
// #define util_vector_to_cell_index( vec_Pos ) (((integer)vec_Pos.x & 0x3ff) | (((integer)vec_Pos.y & 0x3ff)  << 10)| (((integer)vec_Pos.z & 0x3ff) << 20))
// #define util_cell_index_to_vector( int_Pos ) (< (int_Pos & 0x3ff), ((int_Pos >> 10) & 0x3ff), ((int_Pos >> 20) & 0x3ff) >)
// #define util_vector_to_floored_string( vec_Pos ) ("<" + (string)((integer)vec_Pos.x) + "," + (string)((integer)vec_Pos.y) + "," + (string)((integer)vec_Pos.z) + ">")


// // Similar to llBase64ToInteger, but converts an integer to 4 characters instead of 6 at the cost of addition memory and time.
// #ifdef KCUTIL_BASE256
// // Due to an issue in the preproc, the lookup string cannot be assigned to a global variable on compile.
// // Workaround: do the below once before use.
// //g_256Chars = util_256Chars;
// string g_256Chars;
// #define util_256Chars  "0123456789abcdefghijklmnopqrstuvwxyz!\"#$%&'()*+™-./:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`{|}~¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿŀŁłŃńŅ"


// string util_integer_compress( integer int_Data ) {
    // integer int_Index;
    // return
    // llGetSubString( g_256Chars, int_Index = ((int_Data >> 24) & 0xff), int_Index) +
    // llGetSubString( g_256Chars, int_Index = ((int_Data >> 16) & 0xff), int_Index) +
    // llGetSubString( g_256Chars, int_Index = ((int_Data >> 8) & 0xff), int_Index) +
    // llGetSubString( g_256Chars, int_Index = (int_Data & 0xff), int_Index);
// }

// integer util_integer_decompress( string str_Data ) {
    // return
    // (llSubStringIndex( g_256Chars, llGetSubString( str_Data, 0, 0 )) << 24) |
    // (llSubStringIndex( g_256Chars, llGetSubString( str_Data, 1, 1 )) << 16) |
    // (llSubStringIndex( g_256Chars, llGetSubString( str_Data, 2, 2 )) << 8) |
     // llSubStringIndex( g_256Chars, llGetSubString( str_Data, 3, 3 ));
// }
// #endif //KCUTIL_BASE256






#endif //KCUTIL
