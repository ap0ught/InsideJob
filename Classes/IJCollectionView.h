//
//  IJCollectionView.h
//  InsideJob
//
//  Created by Ben K on 2011/03/14.
//  Copyright 2011 Ben K. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IJCollectionView : NSView {
	
	IBOutlet id delegate;
	BOOL selected;
	
}

@property BOOL selected;

@end
