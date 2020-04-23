//
//  KBSearchField.m
//  InsideJob
//
//  Created by Ben K on 2011/03/13.
//  Copyright 2011 Ben K. All rights reserved.
//

#import "KBSearchField.h"
#import "KBSearchFieldCell.h"

@implementation KBSearchField

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	if (self != nil) {
		[self setFrameSize:NSMakeSize([self frame].size.width, [self frame].size.height+1)];
		[self setFrameOrigin:NSMakePoint([self frame].origin.x, [self frame].origin.y-1)];
	}
	
	return self;
}

@end
