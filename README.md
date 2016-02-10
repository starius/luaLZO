# luaLZO, Lua miniLZO Module

[![Travis build][travis-badge]][travis-page]
[![AppVeyor build][appveyor-badge]][appveyor-page]
[![License][license]](LICENSE)

[license]: https://img.shields.io/badge/License-GPL2-brightgreen.png
[travis-page]: https://travis-ci.org/starius/luaLZO
[travis-badge]: https://travis-ci.org/starius/luaLZO.png
[appveyor-page]: https://ci.appveyor.com/project/starius/luaLZO
[appveyor-badge]: https://ci.appveyor.com/api/projects/status/25c553lmnp8tkgn6

Original auhors:
    Adrián Pérez de Castro <mobius@iespana.es>

Updated for Lua 5.1 and LuaJIT by:
    Boris Nagaev <bnagaev@gmail.com>

Acknowledgements:
    The miniLZO and the full LZO library were created by
    Markus Franz Xaver Johannes Oberhumer <markus@oberhumer.com>.
    More info at http://www.oberhumer.com/opensource/lzo/

## Introduction

The Lua LZO module adds lossless data compression functionality to the Lua
language.  To achieve this, the miniLZO library is used, see README.LZO in
order to know more about this small & fast compression library.

Compression ratios achieved with the miniLZO compressor are not as good as
with other  algorithms as used by  Gzip, Bzip2 or  even the full-blown LZO
algorithm. Keep in mind that this is a "mini" version, designed to be very
small in size and fast at execution.

I used miniLZO  as I wanted a extremely  small and easy  to use Lua module.
The module is  about 18 kB under  MacOS X and about  14 kB in  Linux boxes.
In order to be simple, the module only export two new functions to the Lua
interpreter:  `lzo.compress()` and `lzo.decompress()`.
I think that it's very hard to make it simpler ;)


## Requirements

You will need the following in order to build the module:

  * Working C compiler, GCC recommended;
  * Lua 5.1 or above, including headers and libraries. Dynamically
    loadable versions of the libraries are recommended;
  * luarocks.

## Operation

```lua
lzo = require 'luaLZO'

-- This function takes a Lua string and returns a compressed copy of it.
compressed_str = lzo.compress(str)

-- This function takes a Lua string (previously compressed with the above
-- function) and returns a decompressed copy of it.
str = lzo.decompress(compressed_str)
```

As a rule of thumb, the following properties are always true:

  * `str == lzo.decompress(lzo.compress(str))`
  * `str == lzo.compress(lzo.decompress(str))`

Note that only (and when I say 'only', I mean  'only') Lua string may be
compressed...  What about other kinds of data? You have to convert other
kinds of  Lua values to byte streams  (marshaling)  before encoding them.
Remember: a compression algorith just takes a stream of bytes, does some-
thing interesting with it and returns another stream of bytes. It has no
knowledge of what a Lua table is.

Here is a quick example showing how to compress a file (the file must be
shorter than the amount of available memory):

```lua
in_filename  = "/path/to/file"
out_filename = "/path/to/another/file"
inf  = io.open(in_filename,  "rb")
outf = io.open(out_filename, "wb")

-- Read, compress & write
outf:write(lzo.compress(inf:read("*a")))

outf:close()
inf:close()
```

To decompress the file again, just change the line in the middle to:

```lua
outf:write(lzo.decompress(inf:read("*a")))
```

## Extras

The module exports an extra function: `lzo.adler()`.  This function takes a
Lua string and computes its sum using the Adler32 algorithm. The returned
value is a decimal number.  You may specify a second argument  as initial
sum, so you can use the function  to obtain the sum of a long byte stream
that is split in pieces, i.e:

```lua
bytes = obtain_some_bytes()
sum   = 0
while (string.len(bytes) > 0) do
    sum   = lzo.adler(bytes, sum)
    bytes = obtain_more_bytes()
end
```

This function is not needed to be  exported in order to (de)compress data,
but it may be useful to the people out there.

## MT-Safety

All the functions contained in this Lua module are reentrant, so its code
is multithread-safe. There's no shared globals or static storage.
