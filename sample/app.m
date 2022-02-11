//
// Copyright (c) 2009-2013 Mikko Mononen memon@inside.org
// Adapted to Metal, 2022 by Warren Moore wm@warrenmoore.net
//
// This software is provided 'as-is', without any express or implied
// warranty.  In no event will the authors be held liable for any damages
// arising from the use of this software.
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
//

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import "app.h"

#define FONTSTASH_IMPLEMENTATION
#include "fontstash.h"

#define MTLFONTSTASH_IMPLEMENTATION
#include "mtlfontstash.h"

void dash(float dx, float dy)
{
//    glBegin(GL_LINES);
//    glColor4ub(0,0,0,128);
//    glVertex2f(dx-5,dy);
//    glVertex2f(dx-10,dy);
//    glEnd();
}

void line(float sx, float sy, float ex, float ey)
{
//    glBegin(GL_LINES);
//    glColor4ub(0,0,0,128);
//    glVertex2f(sx,sy);
//    glVertex2f(ex,ey);
//    glEnd();
}

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end

@interface MetalView () {
    FONScontext *fs;
    int fontNormal;
    int fontItalic;
    int fontBold;
    int fontJapanese;
}
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, assign) MTLPixelFormat colorPixelFormat;
@end

@implementation MetalView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self commonMetalViewInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonMetalViewInit];
    }
    return self;
}

- (void)dealloc {
    mtlfonsDelete(fs);
}

- (CALayer *)makeBackingLayer {
    return [CAMetalLayer layer];
}

- (CAMetalLayer *)metalLayer {
    return (CAMetalLayer *)self.layer;
}

- (void)commonMetalViewInit {
    self.device = MTLCreateSystemDefaultDevice();
    self.commandQueue = [self.device newCommandQueue];
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;

    fs = mtlfonsCreate(self.device, 1024, 512, FONS_ZERO_TOPLEFT);
    if (fs == NULL) {
        printf("Could not create stash.\n");
    }

    chdir(NSBundle.mainBundle.resourcePath.fileSystemRepresentation);

    fontNormal = fonsAddFont(fs, "sans", "DroidSerif-Regular.ttf");
    if (fontNormal == FONS_INVALID) {
        printf("Could not add font normal.\n");
    }
    fontItalic = fonsAddFont(fs, "sans-italic", "DroidSerif-Italic.ttf");
    if (fontItalic == FONS_INVALID) {
        printf("Could not add font italic.\n");
    }
    fontBold = fonsAddFont(fs, "sans-bold", "DroidSerif-Bold.ttf");
    if (fontBold == FONS_INVALID) {
        printf("Could not add font bold.\n");
    }
    fontJapanese = fonsAddFont(fs, "sans-jp", "DroidSansJapanese.ttf");
    if (fontJapanese == FONS_INVALID) {
        printf("Could not add font japanese.\n");
    }

    mtlfonsSetRenderTargetPixelFormat(fs, self.colorPixelFormat);
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    [self setNeedsDisplay:YES];
}

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    [self setNeedsDisplay:YES];
}

- (void)setNeedsDisplay:(BOOL)needsDisplay {
    [super setNeedsDisplay:needsDisplay];
    if (needsDisplay && self.window != nil) {
        if (self.metalLayer.device == nil) {
            self.metalLayer.device = self.device;
            self.metalLayer.pixelFormat = self.colorPixelFormat;
        }
        CGFloat scale = fmax(1, self.window.backingScaleFactor);
        CGSize boundsSize = self.bounds.size;
        CGSize drawableSize = CGSizeMake(boundsSize.width * scale, boundsSize.height * scale);
        self.metalLayer.drawableSize = drawableSize;

        [self drawRect:self.bounds];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    if (drawable == nil) {
        return;
    }

    MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0.3, 0.3, 0.32, 1.0);
    pass.colorAttachments[0].loadAction  = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].texture = drawable.texture;

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:pass];

    CGSize drawableSize = self.metalLayer.drawableSize;
    int width = drawableSize.width, height = drawableSize.height;

    MTLViewport viewport = { .originX = 0, .originY = 0, .height = height, .width = width };
    mtlfonsSetRenderCommandEncoder(fs, renderCommandEncoder, viewport);

    unsigned int white = mtlfonsRGBA(255,255,255,255);
    unsigned int brown = mtlfonsRGBA(192,128,0,128);
    unsigned int blue = mtlfonsRGBA(0,192,255,255);
    unsigned int black = mtlfonsRGBA(0,0,0,255);

    float sx, sy, dx, dy, lh = 0;
    sx = 50; sy = 50;
    dx = sx; dy = sy;

    dash(dx,dy);

    fonsClearState(fs);

    float scale = fmax(1, self.window.backingScaleFactor);

    fonsSetSize(fs, scale * 124.0f);
    fonsSetFont(fs, fontNormal);
    fonsVertMetrics(fs, NULL, NULL, &lh);
    dx = sx;
    dy += lh;
    dash(dx,dy);

    fonsSetSize(fs, scale * 124.0f);
    fonsSetFont(fs, fontNormal);
    fonsSetColor(fs, white);
    dx = fonsDrawText(fs, dx,dy,"The quick ",NULL);

    fonsSetSize(fs, scale * 48.0f);
    fonsSetFont(fs, fontItalic);
    fonsSetColor(fs, brown);
    dx = fonsDrawText(fs, dx,dy,"brown ",NULL);

    fonsSetSize(fs, scale * 24.0f);
    fonsSetFont(fs, fontNormal);
    fonsSetColor(fs, white);
    dx = fonsDrawText(fs, dx,dy,"fox ",NULL);

    fonsVertMetrics(fs, NULL, NULL, &lh);
    dx = sx;
    dy += lh*1.2f;
    dash(dx,dy);
    fonsSetFont(fs, fontItalic);
    dx = fonsDrawText(fs, dx,dy,"jumps over ",NULL);
    fonsSetFont(fs, fontBold);
    dx = fonsDrawText(fs, dx,dy,"the lazy ",NULL);
    fonsSetFont(fs, fontNormal);
    dx = fonsDrawText(fs, dx,dy,"dog.",NULL);

    dx = sx;
    dy += lh*1.2f;
    dash(dx,dy);
    fonsSetSize(fs, scale * 12.0f);
    fonsSetFont(fs, fontNormal);
    fonsSetColor(fs, blue);
    fonsDrawText(fs, dx,dy,"Now is the time for all good men to come to the aid of the party.",NULL);

    fonsVertMetrics(fs, NULL,NULL,&lh);
    dx = sx;
    dy += lh*1.2f*2;
    dash(dx,dy);
    fonsSetSize(fs, scale * 18.0f);
    fonsSetFont(fs, fontItalic);
    fonsSetColor(fs, white);
    fonsDrawText(fs, dx,dy,"Ég get etið gler án þess að meiða mig.",NULL);

    fonsVertMetrics(fs, NULL,NULL,&lh);
    dx = sx;
    dy += lh*1.2f;
    dash(dx,dy);
    fonsSetFont(fs, fontJapanese);
    fonsDrawText(fs, dx,dy,"私はガラスを食べられます。それは私を傷つけません。",NULL);

    // Font alignment
    fonsSetSize(fs, scale * 18.0f);
    fonsSetFont(fs, fontNormal);
    fonsSetColor(fs, white);

    dx = scale * 50; dy = scale * 350;
    line(dx-10,dy,dx+250,dy);
    fonsSetAlign(fs, FONS_ALIGN_LEFT | FONS_ALIGN_TOP);
    dx = fonsDrawText(fs, dx,dy,"Top",NULL);
    dx += scale * 10;
    fonsSetAlign(fs, FONS_ALIGN_LEFT | FONS_ALIGN_MIDDLE);
    dx = fonsDrawText(fs, dx,dy,"Middle",NULL);
    dx += scale * 10;
    fonsSetAlign(fs, FONS_ALIGN_LEFT | FONS_ALIGN_BASELINE);
    dx = fonsDrawText(fs, dx,dy,"Baseline",NULL);
    dx += scale * 10;
    fonsSetAlign(fs, FONS_ALIGN_LEFT | FONS_ALIGN_BOTTOM);
    fonsDrawText(fs, dx,dy,"Bottom",NULL);

    dx = scale * 150; dy = scale * 400;
    line(dx,dy-30,dx,dy+80.0f);
    fonsSetAlign(fs, FONS_ALIGN_LEFT | FONS_ALIGN_BASELINE);
    fonsDrawText(fs, dx,dy,"Left",NULL);
    dy += scale * 30;
    fonsSetAlign(fs, FONS_ALIGN_CENTER | FONS_ALIGN_BASELINE);
    fonsDrawText(fs, dx,dy,"Center",NULL);
    dy += scale * 30;
    fonsSetAlign(fs, FONS_ALIGN_RIGHT | FONS_ALIGN_BASELINE);
    fonsDrawText(fs, dx,dy,"Right",NULL);

    // Blur
    dx = scale * 500; dy = scale * 350;
    fonsSetAlign(fs, FONS_ALIGN_LEFT | FONS_ALIGN_BASELINE);

    fonsSetSize(fs, scale * 60.0f);
    fonsSetFont(fs, fontItalic);
    fonsSetColor(fs, white);
    fonsSetSpacing(fs, 5.0f);
    fonsSetBlur(fs, 10.0f);
    fonsDrawText(fs, dx,dy,"Blurry...",NULL);

    dy += scale * 50.0f;

    fonsSetSize(fs, scale * 18.0f);
    fonsSetFont(fs, fontBold);
    fonsSetColor(fs, black);
    fonsSetSpacing(fs, 0.0f);
    fonsSetBlur(fs, 3.0f);
    fonsDrawText(fs, dx,dy+2,"DROP THAT SHADOW",NULL);

    fonsSetColor(fs, white);
    fonsSetBlur(fs, 0);
    fonsDrawText(fs, dx,dy,"DROP THAT SHADOW",NULL);

    [renderCommandEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

@end

int main(int argc, const char * argv[]) {
    return NSApplicationMain(argc, argv);
}