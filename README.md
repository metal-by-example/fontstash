*This project has been substantially modified from the original project
to remove dependence on GLFW and OpenGL. This fork is specific to Metal
on Apple platforms and is not intended as a drop-in replacement for the
GL backend of the original project. The sample backend is provided merely
for illustrative purposes and should not be used in production code.*

Font Stash
==========

Font Stash is a lightweight online font texture atlas builder written in C. It uses Core Text and Core Graphics to render fonts on-demand to a texture atlas.

The code is split into two parts: the font atlas and glyph quad generator [fontstash.h](/src/fontstash.h), and an example Metal backend [mtlfontstash.h](/src/mtlfontstash.h).

## Screenshot

![screenshot of some text rendered with the sample program](/screenshots/screen-01.png?raw=true)

## Example
``` C
// Create a Metal stash for 512x512 texture; our coordinate system has a top-left origin.
struct FONScontext* fs = mtlfonsCreate(device, 512, 512, FONS_ZERO_TOPLEFT);

// Add font to stash.
int fontNormal = fonsAddFont(fs, "sans", "DroidSerif-Regular.ttf");

// Render some text
float dx = 10, dy = 10;
unsigned int white = packRGBA(255,255,255,255);
unsigned int brown = packRGBA(192,128,0,128);

fonsSetFont(fs, fontNormal);
fonsSetSize(fs, 124.0f);
fonsSetColor(fs, white);
fonsDrawText(fs, dx,dy,"The big ", NULL);

fonsSetSize(fs, 24.0f);
fonsSetColor(fs, brown);
fonsDrawText(fs, dx,dy,"brown fox", NULL);
```

## Using Font Stash in your project

In order to use fontstash in your own project, just copy fontstash.h and potentially mtlfontstash.h to your project.
In one C/C++ file, define FONTSTASH_IMPLEMENTATION before including the library to expand the font stash implementation in that file.

``` C
#include <stdio.h>					// malloc, free, fopen, fclose, ftell, fseek, fread
#include <string.h>					// memset
#define FONTSTASH_IMPLEMENTATION	// Expands implementation
#include "fontstash.h"
```

``` C
#define MTLFONTSTASH_IMPLEMENTATION	// Expands implementation
#include "mtlfontstash.h"
```

## Creating a new rendering backend

The default rendering backend uses Metal to render the glyphs. If you want to render text using some other API, or want tighter integration with your code base, you can write your own rendering backend. Take a look at [mtlfontstash.h](/src/mtlfontstash.h) for a reference implementation.

To create a font stash object that uses your rendering backend, write a function that populates an instance of the `FONSparams` struct, then calls `fonsCreateInternal` to create the Font Stash context. The various function pointer members of the params struct point to the functions that implement your rendering backend.

```C
struct FONSparams {
	...
	void* userPtr;
	int (*renderCreate)(void* uptr, int width, int height);
	int (*renderResize)(void* uptr, int width, int height);
	void (*renderUpdate)(void* uptr, int* rect, const unsigned char* data);
	void (*renderDraw)(void* uptr, const float* verts, const float* tcoords, const unsigned int* colors, int nverts);
	void (*renderDelete)(void* uptr);
};
```

- **renderCreate** is called to create renderer for specific API, this is where you should create a texture of given size.
	- return 1 of success, or 0 on failure.
- **renderResize** is called to resize the texture. Called when user explicitly expands or resets the atlas texture.
	- return 1 of success, or 0 on failure.
- **renderUpdate** is called to update texture data
	- _rect_ describes the region of the texture that has changed
	- _data_ pointer to full texture data
- **renderDraw** is called when the font triangles should be drawn
	- _verts_ pointer to vertex position data, 2 floats per vertex
	- _tcoords_ pointer to texture coordinate data, 2 floats per vertex
	- _colors_ pointer to color data, 1 uint per vertex (or 4 bytes)
	- _nverts_ is the number of vertices to draw
- **renderDelete** is called when the renderer should be deleted
- **userPtr** is passed to all calls as first parameter

FontStash uses this API as follows:

```
fonsDrawText() {
	foreach (glyph in input string) {
		if (internal buffer full) {
			updateTexture()
			render()
		}
		add glyph to interal draw buffer
	}
	updateTexture()
	render()
}
```

The size of the internal buffer is defined using `FONS_VERTEX_COUNT` define. The default value is 1024; you can override it when you include fontstash.h and specify the implementation:

``` C
#define FONS_VERTEX_COUNT 2048
#define FONTSTASH_IMPLEMENTATION	// Expands implementation
#include "fontstash.h"
```

## Compiling

Open the included Xcode project and run the `fontstash` target.

# License
The library is licensed under [zlib license](LICENSE.txt)
