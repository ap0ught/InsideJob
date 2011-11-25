//
//  IJInventoryPresetController.h
//  InsideJob
//
//  Created by Ben K on 2011/03/15.
//  Copyright 2011 Ben K. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IJInventoryWindowController;
@class IJItemPropertiesViewController;
@class BWSheetController;

@interface IJInventoryPresetController : NSObject {
	
	IBOutlet IJInventoryWindowController *inventoryController;
	
	IBOutlet NSTableView *presetTableView;
  IBOutlet NSTableView *dataTagTableView;
	NSMutableArray *presetArray;
	
	NSMutableArray *armorInventory;
	NSMutableArray *quickInventory;
	NSMutableArray *normalInventory;	
	
  NSString *newPresetName;
}

@property (copy) NSArray *presetArray;
@property (nonatomic, retain) NSString *newPresetName;


- (IBAction)newPreset:(id)sender;
- (IBAction)loadPreset:(id)sender;
- (IBAction)deletePreset:(id)sender;

- (void)reloadPresetList;

- (void)presetTableViewDoubleClicked:(id)sender;

@end
