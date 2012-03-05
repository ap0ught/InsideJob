//
//  IJInspectorWindowController.h
//  InsideJob
//
//  Created by Ben K on 2011/03/15.
//  Copyright 2011 Ben K. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IJInventoryWindowController;
@class IJItemPropertiesViewController;
@class BWSheetController;

@interface IJInspectorWindowController : NSWindowController {
	
	IBOutlet IJInventoryWindowController *inventoryController;
	
	IBOutlet NSTableView *presetTableView;
  IBOutlet NSButton *removePresetButton;
  IBOutlet NSTableView *enchantmentTableView;
  IBOutlet NSButton *removeEnchantmentButton;
	NSMutableArray *presetArray;
	
	NSMutableArray *armorInventory;
	NSMutableArray *quickInventory;
	NSMutableArray *normalInventory;	
	
  NSString *newPresetName;
}

@property (copy) NSArray *presetArray;
@property (nonatomic, retain) NSString *newPresetName;
@property (readonly) IBOutlet IJInventoryWindowController *inventoryController;


- (IBAction)newPreset:(id)sender;
- (IBAction)loadPreset:(id)sender;
- (IBAction)deletePreset:(id)sender;

- (IBAction)newEnchantment:(id)sender;
- (IBAction)removeEnchantment:(id)sender;


- (void)reloadPresetList;

- (void)presetTableViewDoubleClicked:(id)sender;

@end
