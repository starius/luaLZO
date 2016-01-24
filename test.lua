
--
-- Test-script for the Lua LZO compression module.
--
-- To automatically build if neccessary and test the module just do a
-- "make test" in the directory containing these sources.
--
-- Note that is normal that the small compressed string will be longer
-- than the uncompressed one.
--
-- Adrian Perez de Castro <mobius@iespana.es>
--

-- Behaves like C's printf :P
function printf(fmt, ...)
	io.stdout:write(fmt:format(...))
	io.stdout:flush()
end

-- Load the library
printf("Loading 'luaLZO'\n")
lzo = require 'luaLZO'

-- We'll be using string.length() some times...
len = string.len

-- Basic checks
printf("Checking module availability... ")
assert(lzo)
assert(type(lzo) == "table")
assert(lzo.compress)
assert(lzo.decompress)
printf("ok\nSmall string compression...\n  (don't worry if compressed string is larger)\n")
str = "abcdefghijklm"
lzo_str = lzo.compress(str)
printf("  - Compressed %i bytes to %i bytes\n", len(str), len(lzo_str))
de_lzo_str = lzo.decompress(lzo_str)
printf("  - Decompressed %i bytes to %i bytes\n", len(lzo_str), len(de_lzo_str))
printf("  - Verifying data integrity... ")
assert(len(de_lzo_str) == len(str))
assert(de_lzo_str == str)	

-- Encode & decode the GPL license
printf("ok\nBig data buffer compression... \n")
f, err = io.open("minilzo.c", "r")
assert(f, err)
lic = f:read("*a")
f:close()
lzo_lic = lzo.compress(lic)
printf("  - Compressed %i bytes to %i bytes\n", len(lic), len(lzo_lic))
de_lzo_lic = lzo.decompress(lzo_lic)
printf("  - Decompressed %i bytes to %i bytes\n", len(lzo_lic), len(de_lzo_lic))
printf("  - Verifying data integrity... ")
assert(len(de_lzo_lic) == len(lic))
assert(de_lzo_lic == lic)
printf("ok\nAll tests were successful\n")

