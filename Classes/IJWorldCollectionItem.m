//
//  IJWorldCollectionItem.m
//  InsideJob
//
//  Created by Ben K on 2011/03/14.
//  Copyright 2011 Ben K. All rights reserved.
//

#import "IJWorldCollectionItem.h"
#import "IJCollectionView.h"


@implementation IJWorldCollectionItem
@synthesize worldName;
@synthesize worldMeta;
@synthesize worldIcon;
@synthesize worldPath;

- (id)init
{
	if ((self = [super init])) {
		worldName = [[NSString alloc] init];
		worldMeta = [[NSString alloc] init];
		worldIcon = [[NSImage alloc] init];
		worldPath = [[NSString alloc] init];
	}
	return self;
}


- (void)setRepresentedObject:(id)object {
	[super setRepresentedObject: object];
	
	if (object == nil) 
		return;
	
	NSDictionary* data	= (NSDictionary*) [self representedObject];	
	
	[self setWorldName:(NSString*)[data valueForKey:@"Name"]];	
	[self setWorldMeta:(NSString*)[data valueForKey:@"Meta"]];
	[self setWorldIcon:(NSImage*)[data valueForKey:@"Icon"]];
	[self setWorldPath:(NSString*)[data valueForKey:@"Path"]];
	delegate = [data valueForKey:@"Delegate"];
	
}

-(void)setSelected:(BOOL)flag
{
	[super setSelected:flag];
	[(IJCollectionView *)self.view setSelected:flag];
	// Force displaying of the view 
	[(IJCollectionView *)self.view display];
}

-(void)doubleClick:(id)sender
{
	if(delegate && [delegate respondsToSelector:@selector(openWorldAtPath:)]) {
		[delegate performSelector:@selector(openWorldAtPath:) withObject:worldPath];
	}
}


- (void) dealloc
{
	[worldName release];
	[worldMeta release];
	[worldIcon release];
	[worldPath release];
	[super dealloc];
}


@end
