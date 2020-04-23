//
//  IJWorldCollectionItem.h
//  InsideJob
//
//  Created by Ben K on 2011/03/14.
//  Copyright 2011 Ben K. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IJWorldCollectionItem : NSCollectionViewItem {
	
	NSString *worldName;
	NSString *worldMeta;
	NSImage *worldIcon;
	
	id delegate;
	NSString *worldPath;
	
}

@property (nonatomic, retain) NSString *worldName;
@property (nonatomic, retain) NSString *worldMeta;
@property (nonatomic, retain) NSImage *worldIcon;
@property (nonatomic, retain) NSString *worldPath;


- (void)setRepresentedObject:(id)object;

@end
