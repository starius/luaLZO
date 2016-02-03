
/*
 * Lua interface to the mini-LZO compression library
 * Copyright (C) 2003, Adrian Perez de Castro
 *
 * Compressed strings have the "LZO\0" string prepended, and two
 * lzo_uint values:
 *
 *	offset ------------------	value --------------------------------
 *
 *		0													"LZO\0"
 *		4													original size (bytes)
 *		4 + sizeof(lzo_uint)			compressed size (bytes)
 *		4 + 2*sizeof(lzo_uint)		compressed data
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * ME RCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include "minilzo.h"
#include "defs.h"
#include <lua.h>
#include <lauxlib.h>

#define PADSIZE (4 + sizeof(lzo_uint) + sizeof(lzo_uint))

#if LUA_VERSION_NUM == 501
#define compat_rawlen lua_objlen
#else
#define compat_rawlen lua_rawlen
#endif

/*
 * Only the initialization function (luaopen_luaLZO) needs to be exported.
 */
API int luaopen_luaLZO(lua_State*);
    int luaLZO_compress(lua_State*);
    int luaLZO_decompress(lua_State*);
		int luaLZO_adler(lua_State*);

int
luaopen_luaLZO(lua_State* L)
{
	ASSERT(L);
	
	if (lzo_init() != LZO_E_OK) {
		luaL_error(L, "failed to initialize the mini-LZO (de)compressor");
	}

	/* Decide where to put the stuff, "lzo" by default */
	if (lua_gettop(L) == 0) {
		lua_pushstring(L, "lzo");
	} else {
		luaL_checktype(L, -1, LUA_TSTRING);
	}
	
	/* Create table */
	lua_newtable(L);

	/* Register functions */
	lua_pushstring(L, "compress");
	lua_newuserdata(L, LZO1X_1_MEM_COMPRESS); // temp_buffer
	lua_pushcclosure(L, luaLZO_compress, 1);
	lua_rawset(L, -3);

	lua_pushstring(L, "decompress");
	lua_pushcfunction(L, luaLZO_decompress);
	lua_rawset(L, -3);

	lua_pushstring(L, "adler");
	lua_pushcfunction(L, luaLZO_adler);
	lua_rawset(L, -3);

	return 1;
}


int
luaLZO_compress(lua_State *L)
{
	lzo_align_t* temp_buffer = lua_touserdata(L, lua_upvalueindex(1));
	lzo_byte *out, *in;
	lzo_uint in_len, out_len;
	
	ASSERT(L);

	if (!lua_isstring(L, -1) || (lua_gettop(L) != 1)) {
		luaL_error(L, "argument must be a string");
	}

	in_len 	= (lzo_uint) compat_rawlen(L, -1);
	out_len	= in_len + (in_len>>6) + 26 + sizeof(lzo_uint);
	in			= (lzo_byte*) lua_tostring(L, -1);
	out			= (lzo_byte*) lua_newuserdata(L, sizeof(lzo_byte) * out_len);

	if (lzo1x_1_compress(in, in_len, out + PADSIZE,
											 &out_len, temp_buffer) != LZO_E_OK)
	{
		lua_pop(L, 2);
		lua_pushnil(L);
		lua_pushstring(L, "LZO was not able of encoding the data");
		return 2;
	}

	out[0] = 'L';	out[1] = 'Z';	out[2] = 'O';	out[3] = '\0';
	*((lzo_uint*) (out + 4)) = in_len;
	*((lzo_uint*) (out + 4 + sizeof(lzo_uint))) = out_len;

	lua_pushlstring(L, out, (size_t) (out_len + PADSIZE));
	
	return 1;
}


int
luaLZO_decompress(lua_State *L)
{
	lzo_byte *out, *in;
	lzo_uint out_len, in_len, decoded_len;
	
	ASSERT(L);

	if (!lua_isstring(L, -1) || (lua_gettop(L) != 1)) {
		luaL_error(L, "argument must be a string");
	}

	in = (lzo_byte*) lua_tostring(L, -1);
	if ((in[0] != 'L') || (in[1] != 'Z') || (in[2] != 'O') || (in[3] != '\0')) {
		lua_pushnil(L);
		lua_pushstring(L, "string is not luaLZO-compressed data");
		return 2;
	}

	out_len	= *((lzo_uint*) (in + 4));
	in_len 	= *((lzo_uint*) (in + 4 + sizeof(lzo_uint)));
	out			= (lzo_byte*) lua_newuserdata(L, sizeof(lzo_byte) * out_len);

	if (lzo1x_decompress(in + PADSIZE, in_len, out,
											 &decoded_len, NULL) != LZO_E_OK)
	{
		lua_pop(L, 2);
		lua_pushnil(L);
		lua_pushstring(L, "LZO wasn't able to decode the data");
		return 2;
	}

	ASSERT(decoded_len == out_len);
	lua_pushlstring(L, out, (size_t) out_len);
	
	return 1;
}


int
luaLZO_adler(lua_State *L)
{
	lzo_uint32 adler = 0;
	
	ASSERT(L);

	switch (lua_gettop(L)) {
		case 2:
			 adler = (lzo_uint32) luaL_checknumber(L, -1);
			 lua_pop(L, 1);
		case 1:
			 if (!lua_isstring(L, -1)) {
				 luaL_error(L, "string expected as first argument");
			 }
			 break;
		default:
			 luaL_error(L, "one or two arguments expected");
			 return 0;
	}

	adler = lzo_adler32(adler, 
			(lzo_byte*) lua_tostring(L, -1),
			(lzo_uint) compat_rawlen(L, -1));
	lua_pop(L, 1);
	lua_pushnumber(L, adler);
	return 1;
}

