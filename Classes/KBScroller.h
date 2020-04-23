//
//  KBScroller.h
//  Inside Job
//
//  Created by Ben K on 2010/11/21.
//  Copyright 2011 Ben K. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KBScroller : NSScroller {
	BOOL isVertical;
	BOOL usesAlternateStyle;
}

@property BOOL usesAlternateStyle;


@end
