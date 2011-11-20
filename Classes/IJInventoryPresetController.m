//
//  KBInventoryPresetController.m
//  InsideJob
//
//  Created by Ben K on 2011/03/15.
//  Copyright 2011 Ben K. All rights reserved.
//

#import "IJInventoryPresetController.h"
#import "IJInventoryWindowController.h"
#import "IJItemPropertiesViewController.h"
#import "IJInventoryItem.h"
#import "BWSheetController.h"


@implementation IJInventoryPresetController
@synthesize presetArray;
@synthesize newPresetName;


#pragma mark -
#pragma mark Initialization

-(void)awakeFromNib
{
	presetArray = [[NSMutableArray alloc] init];
	
	armorInventory = [[NSMutableArray alloc] init];
	quickInventory = [[NSMutableArray alloc] init];
	normalInventory = [[NSMutableArray alloc] init];
  	
	//Checks to see AppSupport folder exits if not create it.
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *folderPath = [@"~/Library/Application Support/Inside Job/" stringByExpandingTildeInPath];
	if ([fileManager fileExistsAtPath: folderPath] == NO) {
		[fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:NULL];
	}
	
	[self reloadPresetList];
}



#pragma mark -
#pragma mark Actions

- (IBAction)newPreset:(id)sender
{	
	NSString *folderPath = [@"~/Library/Application Support/Inside Job/" stringByExpandingTildeInPath];
	NSString *presetPath = [folderPath stringByAppendingPathComponent:newPresetName];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath: presetPath]) {
    // TODO
		[newPresetName stringByAppendingString:@"_"];
		return;
	}
		
	NSArray *inventoryData = [inventoryController currentInventory];
	NSMutableArray *newPreset = [NSMutableArray array];
	
	int index;
	for (index = 0; index < [inventoryData count]; index++) {
		IJInventoryItem *item = [inventoryData objectAtIndex:index];
		if ((item.count > 0 || item.count < 0) && item.itemId > 0) {
			[newPreset addObject:item];
		}
	}
	
	[NSKeyedArchiver archiveRootObject:newPreset toFile:presetPath];
  
  self.newPresetName = @"";
	[self reloadPresetList];
}

- (IBAction)deletePreset:(id)sender
{
  NSString *presetPath = [[presetArray objectAtIndex:[presetTableView selectedRow]] objectForKey:@"Path"];
	[[NSFileManager defaultManager] removeItemAtPath:presetPath error:NULL];
	[self reloadPresetList];
}

- (IBAction)loadPreset:(id)sender
{
  NSString *presetPath = [[presetArray objectAtIndex:[presetTableView selectedRow]] objectForKey:@"Path"];
	NSArray *newInventory = [NSKeyedUnarchiver unarchiveObjectWithFile:presetPath];
	
	[inventoryController clearInventory];
	[inventoryController loadInventory:newInventory];
}


#pragma mark -
#pragma mark Methods

- (void)reloadPresetList
{
	[presetArray removeAllObjects];

	NSString *folderPath = [@"~/Library/Application Support/Inside Job/" stringByExpandingTildeInPath];
	NSArray *folderArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:NULL];
	
	int index;
	for (index = 0; index < [folderArray count]; index++) {
		NSString *fileName = [folderArray objectAtIndex:index];
		NSString *filePath = [folderPath stringByAppendingPathComponent:[folderArray objectAtIndex:index]];
		
		NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
		
		if (![[fileAttr valueForKey:NSFileType] isEqualToString:NSFileTypeRegular]) {
			continue;
		}
		
		if ([fileName hasPrefix:@"."]) {
			continue;
		}
		
		[presetArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
														fileName, @"Name",
														filePath, @"Path",
														nil]];
	}
  [presetTableView reloadData];
}


#pragma mark -
#pragma mark Preset View

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView
{
  if (theTableView == presetTableView) {
    return presetArray.count;
  }
  return 0;
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  
  if (theTableView == presetTableView) {
    NSString *presetName = [[presetArray objectAtIndex:row] objectForKey:@"Name"];
    if ([tableColumn.identifier isEqual:@"presetName"]) {
      return presetName;
    }
  }
  return nil;
}

- (void)tableView:(NSTableView *)theTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  
}


#pragma mark -
#pragma mark Cleanup

- (void)dealloc
{
	[presetArray release];
	[armorInventory release];
	[quickInventory release];
	[normalInventory release];	
	[super dealloc];
}

@end
