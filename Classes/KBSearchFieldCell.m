//
//  KBSearchFieldCell.m
//  InsideJob
//
//  Created by Ben K on 2010/08/08.
//  Copyright 2011 Ben K. All rights reserved.
//

#import "KBSearchFieldCell.h"

static NSImage *leftCap, *centerFill, *rightCap, *leftCapD, *centerFillD, *rightCapD;

@implementation KBSearchFieldCell


#pragma mark -
#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder:decoder];
  if (self != nil) {
    NSBundle *bundle = [NSBundle bundleForClass:[KBSearchFieldCell class]];
    leftCap = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"KBSTextFieldLC.png"]];
    centerFill = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"KBSTextFieldCF.png"]];
    rightCap = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"KBSTextFieldRC.png"]];
    
    leftCapD = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"KBTextFieldLCD.png"]];
    centerFillD = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"KBTextFieldCFD.png"]];
    rightCapD = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"KBTextFieldRCD.png"]];
  }
  return self;
}

#pragma mark -
#pragma mark Delegate messages

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view
{	
  NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
  
  //Background
  [ctx saveGraphicsState];
  if([[[self controlView] window] isMainWindow]) {
    NSDrawThreePartImage(frame,leftCap,centerFill,rightCap,NO,NSCompositeSourceOver,1.0,YES);
  } else {
    NSDrawThreePartImage(frame,leftCapD,centerFillD,rightCapD,NO,NSCompositeSourceOver,1.0,YES);
  }
  [ctx restoreGraphicsState];
  
  // If we have focus, draw a focus ring around the entire cellFrame.
  if ([self showsFirstResponder]) {
    NSRect focusFrame = frame;
    focusFrame.size.height -= 1.0;
    [NSGraphicsContext saveGraphicsState];
    [[NSColor redColor] set];
    NSSetFocusRingStyle(NSFocusRingOnly);
    [[NSBezierPath bezierPathWithRoundedRect:focusFrame xRadius:2 yRadius:2] fill];
    [NSGraphicsContext restoreGraphicsState];
  }
  
  [self drawInteriorWithFrame:frame inView:view];	
}


- (void)drawInteriorWithFrame:(NSRect)aRect inView:(NSView*)controlView
{
  aRect = NSMakeRect(aRect.origin.x, aRect.origin.y-1, aRect.size.width, aRect.size.height);
  [super drawInteriorWithFrame:aRect inView:controlView];
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
  aRect = NSMakeRect(aRect.origin.x, aRect.origin.y-1, aRect.size.width, aRect.size.height);
  [super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
  aRect = NSMakeRect(aRect.origin.x, aRect.origin.y-1, aRect.size.width, aRect.size.height);
  [super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (BOOL)drawsBackground{
  return NO;
}


#pragma mark -
#pragma mark Cleanup

- (void)dealloc
{	
  [leftCap release];
  [rightCap release];
  [centerFill release];
  [leftCapD release];
  [rightCapD release];
  [centerFillD release];
  [super dealloc];
}

@end
