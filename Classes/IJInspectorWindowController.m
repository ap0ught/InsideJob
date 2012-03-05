//
//  KBInspectorWindowController.m
//  InsideJob
//
//  Created by Ben K on 2011/03/15.
//  Copyright 2011 Ben K. All rights reserved.
//

#import "IJInspectorWindowController.h"
#import "IJInventoryWindowController.h"
#import "IJItemPropertiesViewController.h"
#import "IJInventoryItem.h"
#import "BWSheetController.h"


@implementation IJInspectorWindowController
@synthesize presetArray;
@synthesize newPresetName;
@synthesize inventoryController;


#pragma mark -
#pragma mark Initialization & Cleanup

- (id) init {
  if ((self = [super initWithWindowNibName:@"Inspector"])) {
    
  }
  return self;
}

- (void)awakeFromNib
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
  [presetTableView setTarget:self];
  [presetTableView setDoubleAction:@selector(presetTableViewDoubleClicked:)];
  
  [inventoryController addObserver:self forKeyPath:@"selectedItem" options:0 context:@"KVO_ITEM_CHANGED"];

}

- (void)dealloc
{
  [self removeObserver:self forKeyPath:@"selectedItem"];
	[presetArray release];
	[armorInventory release];
	[quickInventory release];
	[normalInventory release];	
	[super dealloc];
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


- (IBAction)removeEnchantment:(id)sender;
{
  NSMutableArray *enchArray = [NSMutableArray arrayWithArray:[inventoryController.selectedItem.dataTag objectForKey:@"ench"]];
  [enchArray removeObjectAtIndex:[enchantmentTableView selectedRow]];
  
  if (enchArray.count > 0)
    [inventoryController.selectedItem.dataTag setObject:[NSArray arrayWithArray:enchArray] forKey:@"ench"];
  else
    [inventoryController.selectedItem.dataTag removeObjectForKey:@"ench"];
  [enchantmentTableView reloadData];
}
  
- (IBAction)newEnchantment:(id)sender
{
  NSMutableArray *enchArray = [NSMutableArray arrayWithArray:[inventoryController.selectedItem.dataTag objectForKey:@"ench"]];
  
  [enchArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects: [NSNumber numberWithInt:16], [NSNumber numberWithInt:1], nil]
                                                   forKeys:[NSArray arrayWithObjects: @"id", @"lvl", nil]]];
  [inventoryController.selectedItem.dataTag setObject:[NSArray arrayWithArray:enchArray] forKey:@"ench"];
  [enchantmentTableView reloadData];
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
#pragma mark Table View Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView
{
  if (theTableView == presetTableView) {
    return presetArray.count;
  }
  else if (theTableView == enchantmentTableView) {
    return [(NSArray *)[inventoryController.selectedItem.dataTag objectForKey:@"ench"] count];
  }

  return 0;
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  if (theTableView == presetTableView) {
    NSString *presetName = [[presetArray objectAtIndex:row] objectForKey:@"Name"];
    if ([tableColumn.identifier isEqualToString:@"presetName"]) {
      return presetName;
    }
  }
  else if (theTableView == enchantmentTableView) {
    NSArray *enchArray = [inventoryController.selectedItem.dataTag objectForKey:@"ench"];
    NSNumber *enchId = [[enchArray objectAtIndex:row] objectForKey:@"id"];
    NSNumber *enchLvl = [[enchArray objectAtIndex:row] objectForKey:@"lvl"];
    
    if ([tableColumn.identifier isEqualToString:@"1"]) {
      return enchId;
    }
    else if ([tableColumn.identifier isEqualToString:@"2"]) {
      return enchLvl;
    }
    else if ([tableColumn.identifier isEqualToString:@"0"]) {
      return [IJInventoryItem enchantmentNameForId:enchId];
    }
  }
  return nil;
}

- (void)tableView:(NSTableView *)theTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  if (theTableView == enchantmentTableView) {
    NSMutableArray *enchArray = [NSMutableArray arrayWithArray:[inventoryController.selectedItem.dataTag objectForKey:@"ench"]];
    
    if ([tableColumn.identifier isEqualToString:@"1"]) {
      NSNumber *enchId = [NSNumber numberWithInt:[object intValue]];
      if (![IJInventoryItem enchantmentNameForId:enchId]) {
        NSBeep();
        return;
      }
      
      NSNumber *enchLvl = [[enchArray objectAtIndex:row] objectForKey:@"lvl"];      
      [enchArray replaceObjectAtIndex:row withObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects: enchId, enchLvl, nil]
                                                                                 forKeys:[NSArray arrayWithObjects: @"id", @"lvl", nil]]];
      [inventoryController.selectedItem.dataTag setObject:[NSArray arrayWithArray:enchArray] forKey:@"ench"];
    }
    else if ([tableColumn.identifier isEqualToString:@"2"]) {
      NSNumber *enchId = [[enchArray objectAtIndex:row] objectForKey:@"id"];
      NSNumber *enchLvl = [NSNumber numberWithInt:[object intValue]];      
      [enchArray replaceObjectAtIndex:row withObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects: enchId, enchLvl, nil]
                                                                                 forKeys:[NSArray arrayWithObjects: @"id", @"lvl", nil]]];
      [inventoryController.selectedItem.dataTag setObject:[NSArray arrayWithArray:enchArray] forKey:@"ench"];
    }
  }
}

- (void)presetTableViewDoubleClicked:(id)sender
{  
  NSString *presetPath = [[presetArray objectAtIndex:[presetTableView selectedRow]] objectForKey:@"Path"];
	NSArray *newInventory = [NSKeyedUnarchiver unarchiveObjectWithFile:presetPath];
	
	[inventoryController clearInventory];
	[inventoryController loadInventory:newInventory];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
  if ([notification object] == presetTableView) {
  	if ([presetTableView selectedRow] == -1)
      [removePresetButton setEnabled:NO];
    else
      [removePresetButton setEnabled:YES];	
  }
  else if ([notification object] == enchantmentTableView) {
    if ([enchantmentTableView selectedRow] == -1)
      [removeEnchantmentButton setEnabled:NO];
    else
      [removeEnchantmentButton setEnabled:YES];
  }
}


#pragma mark -
#pragma mark IJInventoryItemDelegate

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context;
{
  if (context == @"KVO_ITEM_CHANGED") {
    [enchantmentTableView reloadData];
  }
}

@end
