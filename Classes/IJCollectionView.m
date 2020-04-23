//
//  IJCollectionView.m
//  InsideJob
//
//  Created by Ben K on 2011/03/14.
//  Copyright 2011 Ben K. All rights reserved.
//

#import "IJCollectionView.h"


@implementation IJCollectionView
@synthesize selected;


- (id)init
{
	self = [super init];
	if (self != nil) {
		selected = NO;
	}
	return self;
}


- (NSView *)hitTest:(NSPoint)aPoint
{
	// don't allow any mouse clicks for subviews in this view
	if(NSPointInRect(aPoint,[self convertRect:[self bounds] toView:[self superview]])) {
		return self;
	} else {
		return nil;    
	}
}

-(void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
	
	// check for click count above one, which we assume means it's a double click
	if([theEvent clickCount] > 1) {
		if(delegate && [delegate respondsToSelector:@selector(doubleClick:)]) {
			[delegate performSelector:@selector(doubleClick:) withObject:self];
		}
	}
}

- (void)drawRect:(NSRect)dirtyRect
{	
	NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
	[ctx saveGraphicsState];
	
	if (selected) {
		
		NSShadow *shadow = [[NSShadow alloc] init];
		[shadow setShadowBlurRadius:2];
		[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0 alpha:0.2]];
		[shadow set];
		
		NSRect selectionRect = NSInsetRect([self bounds], 5, 5);
		
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:3 yRadius:3];
		[path setLineWidth:2];
		[[NSColor grayColor] set];
		[path stroke];
		
		NSGradient *innerGradient = [[NSGradient alloc] initWithColorsAndLocations:
																 [NSColor colorWithDeviceWhite:0.95f alpha:1.0f], 0.0f, 
																 [NSColor colorWithDeviceWhite:1.00f alpha:1.0f], 1.0f, 
																 nil];
		
		[innerGradient drawInBezierPath:path angle:90.0f];
		[innerGradient release];
		
		[shadow release];
	}	
	
	[ctx restoreGraphicsState];
}


@end
