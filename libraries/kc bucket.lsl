/*
	Bucket Storage
	"I needed a bigger bucket"
	
	Functions has massive WORM (write-one/read-many) list storage with minimal script memory requirements.
	Typically <2KB of stored data is in memory as a time. 
	Estimated maximum capacity is 6,878KB with 255 db prims.
	
	Warning: Unicode will cause problems without llEscapeURL first. MoaP data fields appears to be 7-bit.
	
	Write data to named bucket:
		KCbucket$varsDB( bucket_name );
		KCbucket$varsWrite( bucket_name );
		KCbucket$initDB( bucket_name, "db prefix", TRUE );
		KCbucket$write( bucket_name, "data" );
		...
		KCbucket$writeClose( bucket_name );
	
	Read back data:
		KCbucket$varsDB( bucket_name );
		KCbucket$varsRead( bucket_name );
		KCbucket$initDB( bucket_name, "prefix", FALSE );
		KCbucket$readAll( bucket_name, str_Data, int_Processing, llOwnerSay("Reached EOF"), llOwnerSay("Got data: " + str_Data) );
	
	Read a bucket while still open for writing:
		KCbucket$varsDB( bucket_name );
		KCbucket$varsWrite( bucket_name );
		KCbucket$varsRead( bucket_name );
		KCbucket$initDB( bucket_name, "db prefix", TRUE );
		KCbucket$write( bucket_name, "data" );
		KCbucket$readAllOpen( bucket_name, str_Data, int_Processing, llOwnerSay("Reached EOF"), llOwnerSay("Got data: " + str_Data) );
		...
		KCbucket$writeClose( bucket_name );
	
	Get address of a write:
		integer int_DataAddress = KCbucket$writeGetNextAddress( bucket_name );
		KCbucket$write( bucket_name, "data" );
		//or
		string str_DataAddress = KCbucket$dataAddress_Encode(KCbucket$writeGetNextAddress( bucket_name ));
		KCbucket$write( bucket_name, "data" );
	
	Seek read:
		KCbucket$readSeek( bucket_name, int_DataAddress );
		KCbucket$readSeek( bucket_name, KCbucket$dataAddress_Decode( str_DataAddress ) );
	
	Seek write: note this only supports reseting to the beginning. Of limited use, may cause data inconsistency.
		KCbucket$writeSeek( bucket_name, 0 );
	
	To get the address of a read, store the address in the written data for elements that will require addressing later:
		string str_DataAddress = KCbucket$dataAddress_Encode(KCbucket$writeGetNextAddress( bucket_name ));
		KCbucket$write( bucket_name, llList2Json(JSON_ARRAY, [str_DataAddress, ...]) );
*/

#ifndef KCbucket$Separator
	#define KCbucket$Separator "`"
#endif

// Because PRIM_MEDIA_WHITELIST is limited to 1023 for some reason instead of 1024..
#define KCbucket$BlockSize 1023
#define KCbucket$BlockSizeLessOne 1022


// Variable names
#define KCbucket$getPrefix( bucket_name ) 		CAT(pffsDBprefix_, bucket_name)
#define KCbucket$getDB( bucket_name ) 			CAT(lst_PrimDB_, bucket_name)

#define KCbucket$getWriteBlockAddress( bucket_name ) 	CAT(int_WriteBlockAddress_, bucket_name)
#define KCbucket$getWriteBuffer( bucket_name ) 		CAT(str_Buffer_, bucket_name)

#define KCbucket$getReadBlockAddress( bucket_name ) 	CAT(int_ReadBlockAddress_, bucket_name)
#define KCbucket$getReadBuffer( bucket_name ) 		CAT(lst_Buffer_, bucket_name)


// You must define pffsDBprefix_name before calling KCbucket$varsDefine
//#define pffsDBprefix_name "prefix"
#define KCbucket$varsDB( bucket_name ) \
	list KCbucket$getDB(bucket_name)

#define KCbucket$varsWrite( bucket_name ) \
	_writeMethodDef( bucket_name )\
	integer KCbucket$getWriteBlockAddress(bucket_name);\
	string KCbucket$getWriteBuffer(bucket_name)

#define KCbucket$varsRead( bucket_name ) \
	integer KCbucket$getReadBlockAddress(bucket_name);\
	list KCbucket$getReadBuffer( bucket_name )

	
#define KCbucket$initDB( bucket_name, str_Prefix, int_Clear ) \
	KCbucket$getDB(bucket_name) = _updateBlockDBPrims( str_Prefix, int_Clear )



#define KCbucket$varsPrint( bucket_name ) \
	llOwnerSay("bucket Vars: " + TOSTRING(bucket_name) + "\nPrefix: " + KCbucket$getPrefix(bucket_name) + "\n" + TOSTRING(KCbucket$getDB(bucket_name)) + ": " + llList2Json(JSON_ARRAY, KCbucket$getDB(bucket_name)) + "\n" + TOSTRING(KCbucket$getWriteBlockAddress(bucket_name)) + ": " + (string)KCbucket$getWriteBlockAddress(bucket_name) + "\n" + TOSTRING(KCbucket$getWriteBuffer(bucket_name)) + ": " + (string)KCbucket$getWriteBuffer(bucket_name))


/*============
  Addressing
============*/
#define _getDataAddress( int_BlockAddress, int_Offset) ((int_BlockAddress << 10) | (int_Offset & 0x3ff))
#define KCbucket$dataAddress_Encode( int_DataAddress ) llGetSubString(llIntegerToBase64(int_DataAddress<<2), 1, 4)
#define KCbucket$dataAddress_Decode( str_DataAddress ) (llBase64ToInteger("A" + str_DataAddress + "A")>>2)
#define _getDataAddress_Block( int_DataAddress ) (int_DataAddress >> 10)
#define _getDataAddress_Offset( int_DataAddress ) (int_DataAddress & 0x3ff)

// Write
#define _getBlockLinkNum( bucket_name, int_BlockAddress ) llList2Integer( KCbucket$getDB(bucket_name), llFloor(int_BlockAddress/27) )
#define _getBlockFaceNum( int_BlockAddress ) (llFloor(int_BlockAddress/3)%9)
#define _getBlockSector( int_BlockAddress ) (_getPrimMediaField(int_BlockAddress%3))
// Read
#define _getBlockLinkNumCurrent( bucket_name ) llList2Integer( KCbucket$getDB(bucket_name), llFloor(KCbucket$getReadBlockAddress(bucket_name)/27) )
#define _getBlockFaceNumCurrent( bucket_name ) (llFloor(KCbucket$getReadBlockAddress(bucket_name)/3)%9)
#define _getBlockSectorCurrent( bucket_name ) (_getPrimMediaField(KCbucket$getReadBlockAddress(bucket_name)%3))

#define _getBlockNumPrims( bucket_name ) (llCeil(KCbucket$getReadBlockAddress(bucket_name)/27.0))

integer _getPrimMediaField( integer int_Index ) {
	if (int_Index == 0) return PRIM_MEDIA_HOME_URL;
	else if (int_Index == 1) return PRIM_MEDIA_CURRENT_URL;
	return PRIM_MEDIA_WHITELIST;
}

/*============
	Write
============*/
integer int_BlockPrim;

// Writes a first block of str_data in the buffer to int_BlockAddress
#define _writeRaw( bucket_name, int_BlockAddress, str_Data ) {\
	int_BlockPrim = _getBlockLinkNum(bucket_name, int_BlockAddress);\
	if (int_BlockPrim <= 0) {\
		debugRare("ERROR: Ran out of DB prims, add more and try again. Bad things have happened and you're data has been eaten by a grue.");\
	} else {\
		/*llOwnerSay("_writeRaw - Index: " + (string)int_BlockAddress + " BlockPrim: " + (string)int_BlockPrim + " FaceNum: " + (string)_getBlockFaceNum(int_BlockAddress) + " Sector: " + (string)(int_BlockAddress%3) + " Buffer Length: " + (string)llStringLength(str_Data));*/\
		/*llOwnerSay(str_Data);*/\
		llSetLinkMedia(\
			int_BlockPrim,\
			_getBlockFaceNum(int_BlockAddress),\
			[_getBlockSector(int_BlockAddress),\
			llGetSubString(str_Data,0,KCbucket$BlockSizeLessOne),\
			PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_NONE, PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE]\
		);\
	}\
}

// Writes a first block of str_data in the buffer to int_BlockAddress and removes it str_data
#define _writeBlock( bucket_name, int_BlockAddress, str_Buffer ) {\
	_writeRaw( bucket_name, int_BlockAddress, str_Buffer );\
	if (llStringLength(str_Buffer) <= KCbucket$BlockSize) {\
		str_Buffer =  "";\
	}else {\
		str_Buffer =  llGetSubString(str_Buffer, KCbucket$BlockSize, -1);\
	}\
	int_BlockAddress++;\
}

// Construct the write function
#define _writeMethod( bucket_name ) CAT(_write_, bucket_name)
#define _writeMethodDef( bucket_name ) _writeMethod( bucket_name )( string str_Data, integer int_Flush ) {\
	KCbucket$getWriteBuffer(bucket_name) += KCbucket$Separator + str_Data;\
	while((llStringLength(KCbucket$getWriteBuffer(bucket_name)) >= KCbucket$BlockSize) || (int_Flush && (llStringLength(KCbucket$getWriteBuffer(bucket_name)) > 0))) {\
		_writeBlock( bucket_name, KCbucket$getWriteBlockAddress(bucket_name), KCbucket$getWriteBuffer(bucket_name) );\
	}\
}

// Appends str_Data in to named buffer, writes out when buffer size >= block size
#define KCbucket$write( bucket_name, str_Data ) \
	_writeMethod( bucket_name )(str_Data, FALSE)

// Writes out the remaining data in the buffer
#define KCbucket$writeClose( bucket_name ) \
	_writeMethod( bucket_name )("EOF", TRUE)

#define KCbucket$writeSeek( bucket_name, int_DataAddress ) \
	KCbucket$getWriteBlockAddress(bucket_name) = _getDataAddress_Block(int_DataAddress); \
	KCbucket$getWriteBuffer(bucket_name) = ""

#define KCbucket$writeGetNextAddress( bucket_name ) \
	_getDataAddress( KCbucket$getWriteBlockAddress(bucket_name), llStringLength(KCbucket$getWriteBuffer(bucket_name)))

/*============
	Read
============*/
integer int_bucketSeek;

#define KCbucket$readNext( bucket_name, str_Data ) {\
	while ((llGetListLength(KCbucket$getReadBuffer(bucket_name)) < 2) && (llList2String(KCbucket$getReadBuffer(bucket_name), -1) != "EOF")) {\
		str_Data = (string)llGetLinkMedia(\
			_getBlockLinkNumCurrent(bucket_name),\
			_getBlockFaceNumCurrent(bucket_name),\
			[_getBlockSectorCurrent(bucket_name)]\
		);\
		KCbucket$getReadBlockAddress(bucket_name)++;\
		if (str_Data == "EOF" || str_Data == "") {\
			KCbucket$getReadBuffer(bucket_name) += "EOF";\
		} else {\
			if (int_bucketSeek) {\
				str_Data = llGetSubString(str_Data, int_bucketSeek, -1);\
				int_bucketSeek = 0 ;\
			} else {\
				str_Data = llList2String(KCbucket$getReadBuffer(bucket_name), -1) + str_Data;\
			}\
			if (llGetListLength(KCbucket$getReadBuffer(bucket_name)) > 1) {\
				KCbucket$getReadBuffer(bucket_name) = llList2List(KCbucket$getReadBuffer(bucket_name), 0, -2) + llParseString2List(str_Data, [KCbucket$Separator], []);\
			} else {\
				KCbucket$getReadBuffer(bucket_name) = llParseString2List(str_Data, [KCbucket$Separator], []);\
			}\
		}\
	}\
	str_Data = llList2String(KCbucket$getReadBuffer(bucket_name), 0);\
	if (llGetListLength(KCbucket$getReadBuffer(bucket_name)) > 1) { KCbucket$getReadBuffer(bucket_name) = llList2List(KCbucket$getReadBuffer(bucket_name), 1, -1);}\
	else { KCbucket$getReadBuffer(bucket_name) = [];}\
}

// Same as above, but reads from an unfinished bucket
#define KCbucket$readNextOpen( bucket_name, str_Data ) {\
	while ((llGetListLength(KCbucket$getReadBuffer(bucket_name)) < 2) && (KCbucket$getReadBlockAddress(bucket_name) <= KCbucket$getWriteBlockAddress(bucket_name))) {\
		if (KCbucket$getReadBlockAddress(bucket_name) < KCbucket$getWriteBlockAddress(bucket_name)) {\
			str_Data = (string)llGetLinkMedia(\
				_getBlockLinkNumCurrent(bucket_name),\
				_getBlockFaceNumCurrent(bucket_name),\
				[_getBlockSectorCurrent(bucket_name)]\
			);\
		} else if (KCbucket$getReadBlockAddress(bucket_name) == KCbucket$getWriteBlockAddress(bucket_name)) {\
			str_Data = KCbucket$getWriteBuffer(bucket_name) + KCbucket$Separator + "EOF";\
		}\
		KCbucket$getReadBlockAddress(bucket_name)++;\
		if (str_Data == "EOF" || str_Data == "") {\
			KCbucket$getReadBuffer(bucket_name) += "EOF";\
		} else {\
			if (int_bucketSeek) {\
				str_Data = llGetSubString(str_Data, int_bucketSeek, -1);\
				int_bucketSeek = 0 ;\
			} else {\
				str_Data = llList2String(KCbucket$getReadBuffer(bucket_name), -1) + str_Data;\
			}\
			if (llGetListLength(KCbucket$getReadBuffer(bucket_name)) > 1) {\
				KCbucket$getReadBuffer(bucket_name) = llList2List(KCbucket$getReadBuffer(bucket_name), 0, -2) + llParseString2List(str_Data, [KCbucket$Separator], []);\
			} else {\
				KCbucket$getReadBuffer(bucket_name) = llParseString2List(str_Data, [KCbucket$Separator], []);\
			}\
		}\
	}\
	str_Data = llList2String(KCbucket$getReadBuffer(bucket_name), 0);\
	if (llGetListLength(KCbucket$getReadBuffer(bucket_name)) > 1) { KCbucket$getReadBuffer(bucket_name) = llList2List(KCbucket$getReadBuffer(bucket_name), 1, -1);}\
	else { KCbucket$getReadBuffer(bucket_name) = [];}\
}


#define _readAll( method_read, bucket_name, str_Data, int_Processing, method_onEOF, method_onData ) {\
	int_Processing = TRUE;\
	do {\
		method_read( bucket_name, str_Data )\
		if (str_Data == "EOF") {\
			method_onEOF;\
			int_Processing = FALSE;\
		} else {\
			method_onData;\
		}\
	} while(int_Processing);\
}

#define KCbucket$readAll( ... ) \
	_readAll( KCbucket$readNext, __VA_ARGS__ )
	
#define KCbucket$readAllOpen( ... ) \
	_readAll( KCbucket$readNextOpen, __VA_ARGS__ )

#define KCbucket$readSeek( bucket_name, int_DataAddress ) \
	KCbucket$getReadBlockAddress(bucket_name) = _getDataAddress_Block(int_DataAddress); \
	int_bucketSeek = _getDataAddress_Offset(int_DataAddress);\
	KCbucket$getReadBuffer(bucket_name) = []


/*============
	Prim DB
============*/

// Returns list of all prims matching prefix in numerical order
list _updateBlockDBPrims( string str_Prefix, integer int_Wipe ) {
    // Build list of RDB prims (copied from DB2)
    // Clear all old data
    list lst_BlockDB = [];
    list prims; // Prim IDS
    list idx;    // Prim NR
    integer i; integer f;
    links_each(int_LinkNum, str_LinkName, 
        if(str_Prefix == llGetSubString(str_LinkName, 0, llStringLength(str_Prefix)-1)) {
			// debugUncommon("str_LinkName: "+str_LinkName);
            if (llGetLinkNumberOfSides(int_LinkNum) != 9) {
                debugRare("ERROR: RDB prim \""+str_LinkName+"\" not set up correctly.");
                return [];
            }
            if (int_Wipe) {
                for(f=0; f < 9; f++) {
                    llClearLinkMedia(int_LinkNum, f);
                }
            }
            prims += int_LinkNum;
            idx += (integer)llGetSubString(str_LinkName, llStringLength(str_Prefix), -1);
        }    
    )
    for(i=0; i<llGetListLength(idx); i++)lst_BlockDB += 0;
    for(i=0; i<llGetListLength(idx); i++)lst_BlockDB = llListReplaceList(lst_BlockDB, llList2List(prims,i,i), llList2Integer(idx,i),llList2Integer(idx,i));
    // DB can start with 0 or 1
    if(llList2Integer(lst_BlockDB,0) == 0)lst_BlockDB = llDeleteSubList(lst_BlockDB,0,0);
	return lst_BlockDB;
}

