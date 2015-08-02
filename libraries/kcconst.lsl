#ifndef KCCONST
#define KCCONST

/*

    An assortment of helpful and shorthand constants

*/


// *** CONSTANTS ***
#define VEC_0 ZERO_VECTOR
#define VEC_ZERO ZERO_VECTOR
#define VEC_WEST <-1,0,0>
#define VEC_NORTH <0,1,0>
#define VEC_EAST <1,0,0>
#define VEC_SOUTH <0,-1,0>
#define VEC_UP <0, 0, 1>
#define VEC_DOWN <0, 0, -1>
#define VEC_MAG <1,1,1>
//VEC_BAD is used when only positive vectors are considered valid
#define VEC_BAD <-1,-1,-1>

#define ROT_0 ZERO_ROTATION
#define ROT_90 <0.000000, 0.000000, 0.707107, 0.707107>
#define ROT_180 <0.000000, 0.000000, 1.000000, 0.000000>
#define ROT_270 <0.000000, -0.000000, -0.707107, 0.707107>
#define lst_Rot [ ROT_0, ROT_90, ROT_180, ROT_270 ]

//TODO: move to grid class when that exists
// these are directly used in block offsets by kcgrid
#define DIR_NORTH 3
#define DIR_EAST 2
#define DIR_SOUTH 1
#define DIR_WEST 0



#endif //KCCONST
