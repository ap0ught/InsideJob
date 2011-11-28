//
//  IJInventoryWindowController.m
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJInventoryWindowController.h"
#import "IJMinecraftLevel.h"
#import "IJMinecraftPlayer.h"
#import "IJInventoryItem.h"
#import "IJInventoryView.h"
#import "IJItemPropertiesViewController.h"
#import "IJWorldCollectionController.h"
#import "MAAttachedWindow.h"
#import "BWSheetController.h"


@implementation IJInventoryWindowController
@synthesize inventory;
@synthesize contentView, inventoryView, quickView, armorView;
@synthesize statusMessage;
@synthesize level;
@synthesize player;


#pragma mark -
#pragma mark Initialization

- (void)awakeFromNib
{	
	loadedWorldPath = [[NSString alloc] init];
	loadedPlayerName = [[NSString alloc] initWithString:@"Default_Player"];
	attemptedLoadWorldPath = [[NSString alloc] init];
	
	armorInventory = [[NSMutableArray alloc] init];
	quickInventory = [[NSMutableArray alloc] init];
	normalInventory = [[NSMutableArray alloc] init];
	[self setStatusMessage:@""];
	
	[inventoryView setRows:3 columns:9 invert:NO];
	[quickView setRows:1 columns:9 invert:NO];
	[armorView setRows:4 columns:1 invert:YES];
	inventoryView.delegate = self;
	quickView.delegate = self;
	armorView.delegate = self;
	
	// Item Table View setup
	NSArray *keys = [[IJInventoryItem itemIdLookup] allKeys];  
  // Properly sort the array
	keys = [keys sortedArrayUsingComparator:^(id obj1, id obj2){
    if ([obj1 isKindOfClass:[NSString class]] && [obj2 isKindOfClass:[NSString class]]) {
      NSArray *itemData1 = [(NSString*)obj1 componentsSeparatedByString:@":"];
      NSArray *itemData2 = [(NSString*)obj2 componentsSeparatedByString:@":"];
      
      if ([[itemData1 objectAtIndex:0] intValue] < [[itemData2 objectAtIndex:0] intValue]) {
        return (NSComparisonResult)NSOrderedAscending;
      } else if ([[itemData1 objectAtIndex:0] intValue] > [[itemData2 objectAtIndex:0] intValue]) {
        return (NSComparisonResult)NSOrderedDescending;
      } else {
        if ([[itemData1 objectAtIndex:1] intValue] < [[itemData2 objectAtIndex:1] intValue]) {
          return (NSComparisonResult)NSOrderedAscending;
        } else if ([[itemData1 objectAtIndex:1] intValue] > [[itemData2 objectAtIndex:1] intValue]) {
          return (NSComparisonResult)NSOrderedDescending;
        }
      }
    }
    
    return (NSComparisonResult)NSOrderedSame;
  }];
	allItemKeys = [[NSArray alloc] initWithArray:keys];
	filteredItemKeys = [allItemKeys retain];
	
	[itemTableView setTarget:self];
	[itemTableView setDoubleAction:@selector(itemTableViewDoubleClicked:)];
  [toolbar setVisible:NO];
	[contentView selectTabViewItemAtIndex:2];
}


#pragma mark -
#pragma mark World Selection

- (BOOL)loadWorldAtPath:(NSString *)worldPath;
{
	NSString *levelPath = [worldPath stringByExpandingTildeInPath];
	
	if ([self isDocumentEdited]) {
		[attemptedLoadWorldPath release];
		attemptedLoadWorldPath = [levelPath copy];
		// Note: We use the didDismiss selector so that any subsequent alert sheets don't bugger up
		NSBeginAlertSheet(@"Do you want to save the changes you made in this world?", @"Save", @"Don't Save", @"Cancel", self.window, self, nil, @selector(dirtyOpenSheetDidEnd:returnCode:contextInfo:), @"Load", 
																	 @"Your changes will be lost if you do not save them.");
		return NO;
	}
	
	if (![IJMinecraftLevel worldExistsAtPath:levelPath]) {
		NSBeginCriticalAlertSheet(@"Error loading world.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
															@"Inside Job was unable to locate the level.dat file.");
		return NO;
	}	
	
	sessionLockValue = [IJMinecraftLevel writeToSessionLockAtPath:levelPath];
	if (![IJMinecraftLevel checkSessionLockAtPath:levelPath value:sessionLockValue]) {
		NSBeginCriticalAlertSheet(@"Error loading world.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
															@"Inside Job was unable obtain the session lock.");
		return NO;
	}
	
	NSData *fileData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[IJMinecraftLevel levelDataPathForWorld:levelPath]]];	
	if (!fileData) {
		// Error loading 
		NSBeginCriticalAlertSheet(@"Error loading world.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
															@"InsideJob was unable to load the level.dat file at:/n%@", levelPath);
		return NO;
	}
	
	// Add to recent files, if the world isn't in the 'minecraft/saves' folder
	if ([self worldFolderContainsPath:levelPath]) {
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:levelPath]];
	}
  	
	[self unloadWorld];
	
  [self willChangeValueForKey:@"level"];
  [self willChangeValueForKey:@"player"];
	
	level = [[IJMinecraftLevel nbtContainerWithData:fileData] retain];
  player = [[IJMinecraftPlayer alloc] initWithContainer:[[level childNamed:@"Data"] childNamed:@"Player"]];
	inventory = [[level inventory] retain];
  	
  [self didChangeValueForKey:@"level"];
  [self didChangeValueForKey:@"player"];

  [level addObserver:self forKeyPath:@"worldName" options:0 context:@"KVO_WORLD_EDITED"];
  [level addObserver:self forKeyPath:@"time" options:0 context:@"KVO_WORLD_EDITED"];
  [level addObserver:self forKeyPath:@"gameMode" options:0 context:@"KVO_WORLD_EDITED"];
  [level addObserver:self forKeyPath:@"spawnX" options:0 context:@"KVO_WORLD_EDITED"];
  [level addObserver:self forKeyPath:@"spawnY" options:0 context:@"KVO_WORLD_EDITED"];
  [level addObserver:self forKeyPath:@"spawnZ" options:0 context:@"KVO_WORLD_EDITED"];
  
  [player addObserver:self forKeyPath:@"xpLevel" options:0 context:@"KVO_WORLD_EDITED"];
  [player addObserver:self forKeyPath:@"health" options:0 context:@"KVO_WORLD_EDITED"];
  [player addObserver:self forKeyPath:@"foodLevel" options:0 context:@"KVO_WORLD_EDITED"];

	// Overwrite the placeholders with actual inventory:
	for (IJInventoryItem *item in inventory) {
		// Add a KVO so that we can set the document as edited when the count or damage values are changed.
		[item addObserver:self forKeyPath:@"count" options:0 context:@"KVO_ITEM_CHANGED"];
		[item addObserver:self forKeyPath:@"damage" options:0 context:@"KVO_ITEM_CHANGED"];
		
		if (IJInventorySlotQuickFirst <= item.slot && item.slot <= IJInventorySlotQuickLast) {
			[quickInventory replaceObjectAtIndex:item.slot - IJInventorySlotQuickFirst withObject:item];
		}
		else if (IJInventorySlotNormalFirst <= item.slot && item.slot <= IJInventorySlotNormalLast) {
			[normalInventory replaceObjectAtIndex:item.slot - IJInventorySlotNormalFirst withObject:item];
		}
		else if (IJInventorySlotArmorFirst <= item.slot && item.slot <= IJInventorySlotArmorLast) {
			[armorInventory replaceObjectAtIndex:item.slot - IJInventorySlotArmorFirst withObject:item];
		}
	}
	
	[inventoryView setItems:normalInventory];
	[quickView setItems:quickInventory];
	[armorView setItems:armorInventory];
		
	[self setDocumentEdited:NO];
	[self setStatusMessage:@""];

	[loadedWorldPath release];
	loadedWorldPath = [levelPath copy];
	[self setStatusMessage:[NSString stringWithFormat:@"Loaded world: %@",[loadedWorldPath lastPathComponent]]];
  [toolbar setVisible:YES];
	[contentView selectTabViewItemAtIndex:[editModeSelector selectedSegment]];
	return YES;
}

- (void)saveWorld
{
	NSString *levelPath = loadedWorldPath;
	if (inventory == nil)
		return; // no world loaded, nothing to save
	
	if (![IJMinecraftLevel checkSessionLockAtPath:levelPath value:sessionLockValue]) {
		NSBeginCriticalAlertSheet(@"Another application has modified this world.", @"Reload", nil, nil, self.window, self, @selector(sessionLockAlertSheetDidEnd:returnCode:contextInfo:), nil, nil, 
															@"The session lock was changed by another application.");
		return;
	}
		
	NSMutableArray *newInventory = [NSMutableArray array];
	for (NSArray *items in [NSArray arrayWithObjects:armorInventory, quickInventory, normalInventory, nil]) {
		for (IJInventoryItem *item in items) {
			// Validate item count
			if (item.count < -1)
				[item setCount:-1];
			if (item.count > 64)
				[item setCount:64];

			// Add item if it's valid
			if ((item.count > 0 || item.count == -1) && item.itemId > 0)
				[newInventory addObject:item];
		}
	}
  
	[level setInventory:newInventory];
	
	NSString *dataPath = [IJMinecraftLevel levelDataPathForWorld:levelPath];
	NSString *backupPath = [dataPath stringByAppendingPathExtension:@"insidejobbackup"];
	
	BOOL success = NO;
	NSError *error = nil;
	
	// Remove a previously-created .insidejobbackup, if it exists:
	if ([[NSFileManager defaultManager] fileExistsAtPath:backupPath]) {
		success = [[NSFileManager defaultManager] removeItemAtPath:backupPath error:&error];
		if (success != YES) {
			NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [error localizedDescription]);
			NSBeginCriticalAlertSheet(@"An error occurred while saving.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
																@"Inside Job was unable to remove the prior backup of this level file.", [error localizedDescription]);
			return;
		}
	}
	
	// Create the backup:
	success = [[NSFileManager defaultManager] copyItemAtPath:dataPath toPath:backupPath error:&error];
	if (success != YES) {
		NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [error localizedDescription]);
		NSBeginCriticalAlertSheet(@"An error occurred while saving.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
															@"Inside Job was unable to create a backup of the existing level file.", [error localizedDescription]);
		return;
	}
	
	
	// Write the new level.dat out:
	success = [[level writeData] writeToURL:[NSURL fileURLWithPath:dataPath] options:0 error:&error];
	if (success != YES) {
		NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [error localizedDescription]);
		
		NSError *restoreError = nil;
		success = [[NSFileManager defaultManager] copyItemAtPath:backupPath toPath:dataPath error:&restoreError];
		if (success != YES) {
			NSLog(@"%s:%d %@", __PRETTY_FUNCTION__, __LINE__, [restoreError localizedDescription]);
			NSBeginCriticalAlertSheet(@"An error occurred while saving.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
																@"Inside Job was unable to save to the existing level file, and the backup could not be restored.", [error localizedDescription], [restoreError localizedDescription]);
		} else {
			NSBeginCriticalAlertSheet(@"An error occurred while saving.", @"Dismiss", nil, nil, self.window, nil, nil, nil, nil, 
																@"Inside Job was unable to save to the existing level file, and the backup was successfully restored.", [error localizedDescription]);
		}
		return;
	}
	
	[self setDocumentEdited:NO];
  [self setStatusMessage:@"World saved."];
}

- (void)dirtyOpenSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{	
	if (returnCode == NSAlertDefaultReturn) // Save
	{
		if ([(NSString *)contextInfo isEqualToString:@"Load"]) {
			[self saveWorld];
			[self loadWorldAtPath:attemptedLoadWorldPath];
		}
		else {
			[self saveWorld];
			[self unloadWorld];
      [toolbar setVisible:NO];
    			[contentView selectTabViewItemAtIndex:2];
		}		
	}
	else if (returnCode == NSAlertAlternateReturn) // Don't save
	{
		[self setDocumentEdited:NO]; // Slightly hacky -- prevent the alert from being put up again.
		if ([(NSString *)contextInfo isEqualToString:@"Load"]) {
			[self loadWorldAtPath:attemptedLoadWorldPath];
		}
		else {
			[self unloadWorld];
      [toolbar setVisible:NO];
    			[contentView selectTabViewItemAtIndex:2];
		}
	}
	
}

- (void)sessionLockAlertSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{	
	[self setDocumentEdited:NO];
	[self loadWorldAtPath:loadedWorldPath];
}

- (void)setDocumentEdited:(BOOL)edited
{
	[super setDocumentEdited:edited];
	if (edited)
    [self setStatusMessage:@"World has unsaved changes."];
}

- (BOOL)isDocumentEdited
{
	return [self.window isDocumentEdited];
}


#pragma mark -
#pragma mark Actions

- (IBAction)openWorld:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	 
	 // Set up the panel
	 [openPanel setCanChooseDirectories:YES];
	 [openPanel setCanChooseFiles:NO];
	 [openPanel setAllowsMultipleSelection:NO];
	 
	 // Display the NSOpenPanel
	 [openPanel beginWithCompletionHandler:^(NSInteger runResult){
		 if (runResult == NSFileHandlingPanelOKButton) {
			 NSString *filePath = [[[openPanel URLs] objectAtIndex:0] path]; 
			 [self loadWorldAtPath:filePath];
		 }
	 }];
}

- (IBAction)reloadWorldInformation:(id)sender
{	
	if (loadedWorldPath != nil && ![loadedWorldPath isEqualToString:@""])
		[self loadWorldAtPath:loadedWorldPath];
}

- (IBAction)showWorldSelector:(id)sender
{
  if (propertiesWindow) {
    [propertiesWindow orderOut:nil];
  }
  
	if ([self isDocumentEdited]) {
		// Note: We use the didDismiss selector so that any subsequent alert sheets don't bugger up
		NSBeginAlertSheet(@"Do you want to save the changes you made in this world?", @"Save", @"Don't Save", @"Cancel", self.window, self, nil, @selector(dirtyOpenSheetDidEnd:returnCode:contextInfo:), @"Select", 
																	 @"Your changes will be lost if you do not save them.");
		return;
	}
	
	// Clear inventory and unload world
	[self unloadWorld];
	
	// Show world selector
	[worldCollectionController reloadWorldData];
  [toolbar setVisible:NO];
	[contentView selectTabViewItemAtIndex:2];
}

- (IBAction)addItem:(id)sender
{
	if ([newItemField intValue] <= 0 || [newItemField intValue] >= 32767) {
		[newItemSheetController setSheetErrorMessage:@"Invalid item id."];
		return;
	}
  int16_t itemID = [newItemField intValue];
	
	[newItemSheetController closeSheet:self];
	[newItemSheetController setSheetErrorMessage:@""];
	[self addInventoryItemID:itemID damage:0 selectItem:YES];
}

- (IBAction)clearInventoryItems:(id)sender
{
	[self clearInventory];
  [self setDocumentEdited:YES];
}

- (IBAction)copyWorldSeed:(id)sender
{
	NSString *worldSeed = [NSString stringWithFormat:@"%@",[level seed]];
	
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSArray *types = [NSArray arrayWithObjects:NSStringPboardType, nil];
	[pb declareTypes:types owner:self];
	[pb setString:worldSeed forType:NSStringPboardType];
}

- (IBAction)incrementTime:(id)sender
{
	if ([sender selectedSegment] == 0) {		
		int wTime = [[level time] intValue];
		int result = wTime - (24000 - (wTime % 24000));
		[level setTime:[NSNumber numberWithInt:result]];
	}
	else if ([sender selectedSegment] == 1) {
		int wTime = [[level time] intValue];
		int result = wTime + (24000 - (wTime % 24000));
		[level setTime:[NSNumber numberWithInt:result]];
	}
}

- (void)saveDocument:(id)sender
{
	[self saveWorld];
}

- (BOOL)worldFolderContainsPath:(NSString *)path
{
	NSString *filePath = [path stringByStandardizingPath];
	NSString *worldFolder = [[@"~/library/application support/minecraft/saves/" stringByExpandingTildeInPath] stringByStandardizingPath];
		
	if (![[filePath stringByDeletingLastPathComponent] isEqualToString:worldFolder]) {
		return YES;
	}
	return NO;
}

- (IBAction)makeSearchFieldFirstResponder:(id)sender
{
	[itemSearchField becomeFirstResponder];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	if (anItem.action == @selector(saveDocument:)) {
		return inventory != nil;
	}
	if (anItem.action == @selector(reloadWorldInformation:)) {
		return inventory != nil;
	}
	if (anItem.action == @selector(showWorldSelector:)) {
		return inventory != nil;
	}
	if (anItem.action == @selector(copyWorldSeed:)) {
		return inventory != nil;
	}
	if (anItem.action == @selector(clearInventoryItems:)) {
		return inventory != nil;
	}
	return YES;
}


#pragma mark -
#pragma mark IJInventoryViewDelegate

- (IJInventoryView *)inventoryViewForItemArray:(NSMutableArray *)theItemArray
{
	if (theItemArray == normalInventory) {
		return inventoryView;
	}
	if (theItemArray == quickInventory) {
		return quickView;
	}
	if (theItemArray == armorInventory) {
		return armorView;
	}
	return nil;
}

- (NSMutableArray *)itemArrayForInventoryView:(IJInventoryView *)theInventoryView slotOffset:(int*)slotOffset
{
	if (theInventoryView == inventoryView) {
		if (slotOffset) *slotOffset = IJInventorySlotNormalFirst;
		return normalInventory;
	}
	else if (theInventoryView == quickView) {
		if (slotOffset) *slotOffset = IJInventorySlotQuickFirst;
		return quickInventory;
	}
	else if (theInventoryView == armorView) {
		if (slotOffset) *slotOffset = IJInventorySlotArmorFirst;
		return armorInventory;
	}
	return nil;
}

- (void)inventoryView:(IJInventoryView *)theInventoryView removeItemAtIndex:(int)itemIndex
{
	int slotOffset = 0;
	NSMutableArray *itemArray = [self itemArrayForInventoryView:theInventoryView slotOffset:&slotOffset];
	
	if (itemArray) {
		IJInventoryItem *item = [IJInventoryItem emptyItemWithSlot:slotOffset + itemIndex];
		[itemArray replaceObjectAtIndex:itemIndex withObject:item];
		[theInventoryView setItems:itemArray];
	}
	[self setDocumentEdited:YES];
}

- (void)inventoryView:(IJInventoryView *)theInventoryView setItem:(IJInventoryItem *)item atIndex:(int)itemIndex
{
	int slotOffset = 0;
	NSMutableArray *itemArray = [self itemArrayForInventoryView:theInventoryView slotOffset:&slotOffset];
	
	if (itemArray) {
		[itemArray replaceObjectAtIndex:itemIndex withObject:item];
		item.slot = slotOffset + itemIndex;
		[theInventoryView setItems:itemArray];
	}
	[self setDocumentEdited:YES];
}

- (void)inventoryView:(IJInventoryView *)theInventoryView selectedItemAtIndex:(int)itemIndex
{
	// Show the properties window for this item.
	IJInventoryItem *lastItem = propertiesViewController.item;
	
	NSPoint itemLocationInView = [theInventoryView pointForItemAtIndex:itemIndex];
	NSPoint point = [theInventoryView convertPoint:itemLocationInView toView:nil];
	point.x += 16 + 8;
	point.y -= 16;
	
	NSArray *items = [self itemArrayForInventoryView:theInventoryView slotOffset:nil];
	IJInventoryItem *selectedItem = [items objectAtIndex:itemIndex];
  
	if (selectedItem.itemId == 0 || lastItem == selectedItem) {
		// The window may not be invisible at this point,
		[propertiesWindow setAlphaValue:0.0];
		[propertiesViewController setItem:nil];
		return; // can't show info for anything
	}
	
	if (!propertiesViewController) {
		propertiesViewController = [[IJItemPropertiesViewController alloc] initWithNibName:@"ItemPropertiesView" bundle:nil];
		
		propertiesWindow = [[MAAttachedWindow alloc] initWithView:propertiesViewController.view
												  attachedToPoint:point
														 inWindow:self.window
														   onSide:MAPositionRight
													   atDistance:0];
		[propertiesWindow setBackgroundColor:[NSColor windowBackgroundColor]];
    [propertiesWindow setBorderColor:[NSColor whiteColor]];
    [propertiesWindow setBorderWidth:1];
		[propertiesWindow setViewMargin:4.0];
		[propertiesWindow setAlphaValue:0.99];
		[propertiesWindow setArrowHeight:10];
		[[self window] addChildWindow:propertiesWindow ordered:NSWindowAbove];
	}
	if (observerObject) {
		[[NSNotificationCenter defaultCenter] removeObserver:observerObject];
	}
	observerObject = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResignKeyNotification
																	   object:propertiesWindow
																		queue:[NSOperationQueue mainQueue]
																   usingBlock:^(NSNotification *notification) {
																	   [propertiesViewController commitEditing];
																		 // Validate item
																	   if (selectedItem.count == 0)
																		   selectedItem.itemId = 0;
																		 if (selectedItem.count < -1)
																			 selectedItem.count = -1;
																		 if (selectedItem.count > 64)
																			 selectedItem.count = 64;
																		 if (selectedItem.damage < 0)
																			 selectedItem.damage = 0;
																		 
																	   [theInventoryView reloadItemAtIndex:itemIndex];
																	   [propertiesWindow setAlphaValue:0.0];
																   }];
	[propertiesViewController setItem:selectedItem];
	[propertiesWindow setPoint:point side:MAPositionRight];
	[propertiesWindow makeKeyAndOrderFront:nil];
	[propertiesWindow setAlphaValue:0.9];
}

#pragma mark -
#pragma mark IJInventoryItemDelegate

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context;
{
	if (context == @"KVO_ITEM_CHANGED") {
		[self setDocumentEdited:YES];
	}	
  if (context == @"KVO_WORLD_EDITED") {
    [self setDocumentEdited:YES];
  }
}
	

#pragma mark -
#pragma mark Inventory

- (void)clearInventory
{	
	[armorInventory removeAllObjects];
	[quickInventory removeAllObjects];
	[normalInventory removeAllObjects];
	
	// Add placeholder inventory items:
	for (int i = 0; i < IJInventorySlotQuickLast + 1 - IJInventorySlotQuickFirst; i++) {
		[quickInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotQuickFirst + i]];
	}
	
	for (int i = 0; i < IJInventorySlotNormalLast + 1 - IJInventorySlotNormalFirst; i++) {
		[normalInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotNormalFirst + i]];
	}
	
	for (int i = 0; i < IJInventorySlotArmorLast + 1 - IJInventorySlotArmorFirst; i++) {
		[armorInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotArmorFirst + i]];
	}	
	
	[inventoryView setItems:normalInventory];
	[quickView setItems:quickInventory];
	[armorView setItems:armorInventory];	
}

- (void)unloadWorld
{
	[self clearInventory];
	
  [level removeObserver:self forKeyPath:@"worldName"];
  [level removeObserver:self forKeyPath:@"time"];
  [level removeObserver:self forKeyPath:@"gameMode"];
  [level removeObserver:self forKeyPath:@"spawnX"];
  [level removeObserver:self forKeyPath:@"spawnY"];
  [level removeObserver:self forKeyPath:@"spawnZ"];
  
  [player removeObserver:self forKeyPath:@"xpLevel"];
  [player removeObserver:self forKeyPath:@"health"];
  [player removeObserver:self forKeyPath:@"foodLevel"];
  
  [self willChangeValueForKey:@"level"];
  [self willChangeValueForKey:@"player"];
	
	[level release];
	level = nil;
  [player release];
  player = nil;
	
	for (IJInventoryItem *item in inventory) {
		[item removeObserver:self forKeyPath:@"count"];
		[item removeObserver:self forKeyPath:@"damage"];
	}	
	
	[inventory release];
	inventory = nil;
  [self didChangeValueForKey:@"level"];
  [self didChangeValueForKey:@"player"];
	
  [self setStatusMessage:@"No world loaded."];
}

- (void)loadInventory:(NSArray *)newInventory
{
	[armorInventory removeAllObjects];
	[quickInventory removeAllObjects];
	[normalInventory removeAllObjects];
	
	[inventoryView setItems:normalInventory];
	[quickView setItems:quickInventory];
	[armorView setItems:armorInventory];

	for (IJInventoryItem *item in inventory) {
		[item removeObserver:self forKeyPath:@"count"];
		[item removeObserver:self forKeyPath:@"damage"];
	}	
	
	[inventory release];
	inventory = nil;
	
	inventory = [newInventory retain];
	
	// Add placeholder inventory items:
	for (int i = 0; i < IJInventorySlotQuickLast + 1 - IJInventorySlotQuickFirst; i++)
		[quickInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotQuickFirst + i]];
	
	for (int i = 0; i < IJInventorySlotNormalLast + 1 - IJInventorySlotNormalFirst; i++)
		[normalInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotNormalFirst + i]];
	
	for (int i = 0; i < IJInventorySlotArmorLast + 1 - IJInventorySlotArmorFirst; i++)
		[armorInventory addObject:[IJInventoryItem emptyItemWithSlot:IJInventorySlotArmorFirst + i]];
	
	
	// Overwrite the placeholders with actual inventory:
	for (IJInventoryItem *item in inventory) {
		// Add a KVO so that we can set the document as edited when the count or damage values are changed.
		[item addObserver:self forKeyPath:@"count" options:0 context:@"KVO_ITEM_CHANGED"];
		[item addObserver:self forKeyPath:@"damage" options:0 context:@"KVO_ITEM_CHANGED"];

		if (IJInventorySlotQuickFirst <= item.slot && item.slot <= IJInventorySlotQuickLast) {
			[quickInventory replaceObjectAtIndex:item.slot - IJInventorySlotQuickFirst withObject:item];
		}
		else if (IJInventorySlotNormalFirst <= item.slot && item.slot <= IJInventorySlotNormalLast) {
			[normalInventory replaceObjectAtIndex:item.slot - IJInventorySlotNormalFirst withObject:item];
		}
		else if (IJInventorySlotArmorFirst <= item.slot && item.slot <= IJInventorySlotArmorLast) {
			[armorInventory replaceObjectAtIndex:item.slot - IJInventorySlotArmorFirst withObject:item];
		}
	}
	
	[inventoryView setItems:normalInventory];
	[quickView setItems:quickInventory];
	[armorView setItems:armorInventory];
		
	[self setDocumentEdited:YES];	
}

- (NSMutableArray *)inventoryArrayWithEmptySlot:(NSUInteger *)slot
{
	for (NSMutableArray *inventoryArray in [NSArray arrayWithObjects:quickInventory, normalInventory, nil]) {
		__block BOOL found = NO;
		
		[inventoryArray enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
			IJInventoryItem *item = obj;
			if (item.count == 0) {
				*slot = index;
				*stop = YES;
				found = YES;
			}
		}];
		
		if (found) {
			return inventoryArray;
		}
	}
	return nil;
}

- (NSArray *)currentInventory
{
	NSMutableArray *inventoryArray = [[[NSMutableArray alloc] init] autorelease];
	
	[inventoryArray addObjectsFromArray:armorInventory];
	[inventoryArray addObjectsFromArray:quickInventory];
	[inventoryArray addObjectsFromArray:normalInventory];

	return inventoryArray;
}

- (void)addInventoryItemID:(short)item damage:(short)damage selectItem:(BOOL)flag
{
	NSUInteger slot;
	NSMutableArray *inventoryArray = [self inventoryArrayWithEmptySlot:&slot];
	if (!inventoryArray)
		return;
	
	IJInventoryItem *inventoryItem = [inventoryArray objectAtIndex:slot];
	inventoryItem.itemId = item;
	inventoryItem.count = 1;
  inventoryItem.damage = damage;
	[self setDocumentEdited:YES];
	
	IJInventoryView *invView = [self inventoryViewForItemArray:inventoryArray];
	[invView reloadItemAtIndex:slot];
	if (flag) {
		[self inventoryView:invView selectedItemAtIndex:slot];
	}
}


#pragma mark -
#pragma mark Item Picker

- (IBAction)updateItemSearchFilter:(id)sender
{
	NSString *filterString = [[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (filterString.length == 0 || [filterString isEqualToString:@"~"]) {
		[filteredItemKeys autorelease];
		filteredItemKeys = [allItemKeys retain];
		[itemTableView reloadData];
		return;
	}
	
	NSMutableArray *results = [NSMutableArray array];
	
	for (NSString *itemKey in allItemKeys) {
		NSDictionary *itemData = [[IJInventoryItem itemIdLookup] objectForKey:itemKey];
		NSString *name = [itemData objectForKey:@"Name"];
    NSString *type = [itemData objectForKey:@"Type"];
    short itemId = [[itemData objectForKey:@"ID"] shortValue];
    
    // Keyword filtering
    if ([filterString hasPrefix:@"~"]) {
      NSString *keyword = [[[filterString componentsSeparatedByString:@" "] objectAtIndex:0] substringFromIndex:1];
      NSRange keyRange = [type rangeOfString:keyword options:NSCaseInsensitiveSearch|NSAnchoredSearch];
      
      // Keyword has search term after it
      NSRange nameRange = NSMakeRange(0, 0);
      if (filterString.length > keyword.length+1) {
        NSString *filterString2 = [filterString substringFromIndex:keyword.length+2];
        nameRange = [name rangeOfString:filterString2 options:NSCaseInsensitiveSearch];
      }

      if (keyRange.location != NSNotFound && nameRange.location != NSNotFound) {
        [results addObject:itemKey];
        continue;
      }
    }
    
		NSRange range = [name rangeOfString:filterString options:NSCaseInsensitiveSearch];
		if (range.location != NSNotFound) {
			[results addObject:itemKey];
			continue;
		}
		
		// Also search the item id:
		range = [[NSString stringWithFormat:@"%hi",itemId] rangeOfString:filterString];
		if (range.location != NSNotFound) {
			[results addObject:itemKey];
			continue;
		}
	}
	
	[filteredItemKeys autorelease];
	filteredItemKeys = [results retain];
	[itemTableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView
{
	return filteredItemKeys.count;
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{  
  NSString *itemKey = [filteredItemKeys objectAtIndex:row];
	NSDictionary *itemData = [[IJInventoryItem itemIdLookup] objectForKey:itemKey];
	short itemId = [[itemData objectForKey:@"ID"] shortValue];
  short itemDamage = [[itemData objectForKey:@"Damage"] shortValue];

	
	if ([tableColumn.identifier isEqual:@"itemId"]) {
		return [NSNumber numberWithShort:itemId];
	}
	else if ([tableColumn.identifier isEqual:@"image"]) {
		return [IJInventoryItem imageForItemId:itemId withDamage:itemDamage];
	}
	else {
		NSString *name = [itemData objectForKey:@"Name"];
		return name;
	}
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	[pboard declareTypes:[NSArray arrayWithObjects:IJPasteboardTypeInventoryItem, nil] owner:nil];
  
  NSString *itemKey = [filteredItemKeys objectAtIndex:[rowIndexes firstIndex]];
	NSDictionary *itemData = [[IJInventoryItem itemIdLookup] objectForKey:itemKey];
	short itemId = [[itemData objectForKey:@"ID"] shortValue];
  short itemDamage = [[itemData objectForKey:@"Damage"] shortValue];
	
	IJInventoryItem *item = [[IJInventoryItem alloc] init];
	item.itemId = itemId;
	item.count = 1;
	item.damage = itemDamage;
	item.slot = 0;
	
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:item]
			forType:IJPasteboardTypeInventoryItem];
	
	[item release];

	return YES;
}

- (void)itemTableViewDoubleClicked:(id)sender
{  
  NSString *itemKey = [filteredItemKeys objectAtIndex:[itemTableView selectedRow]];
	NSDictionary *itemData = [[IJInventoryItem itemIdLookup] objectForKey:itemKey];
	short itemID = [[itemData objectForKey:@"ID"] shortValue];
  short itemDamage = [[itemData objectForKey:@"Damage"] shortValue];

	[self addInventoryItemID:itemID damage:itemDamage selectItem:YES];
}

#pragma mark -
#pragma mark NSWindowDelegate

- (void)dirtyCloseSheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if (returnCode == NSAlertOtherReturn) { // Cancel
		return;
	}
	
	if (returnCode == NSAlertDefaultReturn){ // Save
		[self saveWorld];
		[self.window performClose:nil];
	}
	else if (returnCode == NSAlertAlternateReturn) { // Don't save
		[self setDocumentEdited:NO]; // Slightly hacky -- prevent the alert from being put up again.
		[self unloadWorld];
		[self.window performClose:nil];
	}
}


- (BOOL)windowShouldClose:(id)sender
{
	if ([self isDocumentEdited]) {
		// Note: We use the didDismiss selector because the sheet needs to be closed in order for performClose: to work.
		NSBeginAlertSheet(@"Do you want to save the changes you made in this world?", @"Save", @"Don't Save", @"Cancel", self.window, self, nil, @selector(dirtyCloseSheetDidDismiss:returnCode:contextInfo:), nil, 
																	 @"Your changes will be lost if you do not save them.");
		return NO;
	}
	  
	return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
  if ([notification object] == self.window)
    [NSApp terminate:nil];
}


#pragma mark -
#pragma mark NSControlTextEditingDelegate

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	if (command == @selector(moveDown:)) {
		if ([itemTableView numberOfRows] > 0) {
			[self.window makeFirstResponder:itemTableView];
			[itemTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		}
		return YES;
	}
	return NO;
}


#pragma mark -
#pragma mark Cleanup

- (void)dealloc
{
	[loadedWorldPath release];
	[attemptedLoadWorldPath release];
	[propertiesViewController release];
	[armorInventory release];
	[quickInventory release];
	[normalInventory release];
	[inventory release];
  [player release];
	[level release];
	[super dealloc];
}

@end
