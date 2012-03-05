//
//  IJInventoryWindowController.h
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IJInventoryView.h"

@class IJInventoryView;
@class IJMinecraftLevel;
@class IJMinecraftPlayer;
@class MAAttachedWindow;
@class IJItemPropertiesViewController;
@class IJWorldCollectionController;
@class BWSheetController;

@interface IJInventoryWindowController : NSWindowController <NSWindowDelegate, IJInventoryViewDelegate> {
  
  IBOutlet BWSheetController *newItemSheetController;
  IBOutlet NSTextField *newItemField;
  
  IJMinecraftLevel *level;
  IJMinecraftPlayer *player;
  NSArray *inventory;
  
  NSString *statusMessage;
  IBOutlet NSToolbar *toolbar;
  IBOutlet NSSegmentedControl *editModeSelector;
  IBOutlet NSTabView *contentView;
  
  IJInventoryView *normalInvView;
  IJInventoryView *quickInvView;
  IJInventoryView *armorInvView;
  
  NSMutableArray *armorInventory;
  NSMutableArray *quickInventory;
  NSMutableArray *normalInventory;
  IJInventoryItem *selectedItem;
  
  // Search/Item List
  IBOutlet NSSearchField *itemSearchField;
  IBOutlet NSTableView *itemTableView;
  NSArray *allItemKeys;
  NSArray *filteredItemKeys;
  
  // 
  IJItemPropertiesViewController *propertiesViewController;
  IBOutlet IJWorldCollectionController *worldCollectionController;
  MAAttachedWindow *propertiesWindow;
  id observerObject;
  
  // Document
  int64_t sessionLockValue;
  NSString *loadedWorldPath;
  NSString *attemptedLoadWorldPath;
  NSString *loadedPlayerName;
}

@property (nonatomic, assign) NSString *statusMessage;
@property (nonatomic, readonly) NSTabView *contentView;
@property (nonatomic, retain) IBOutlet IJInventoryView *normalInvView;
@property (nonatomic, retain) IBOutlet IJInventoryView *quickInvView;
@property (nonatomic, retain) IBOutlet IJInventoryView *armorInvView;
@property (nonatomic, assign) IJInventoryItem *selectedItem;

@property (readonly) NSArray *inventory;
@property (nonatomic, readonly) IJMinecraftLevel *level;
@property (readonly) IJMinecraftPlayer *player;


- (IBAction)openWorld:(id)sender;
- (IBAction)showWorldSelector:(id)sender;
- (IBAction)reloadWorldInformation:(id)sender;
- (IBAction)updateItemSearchFilter:(id)sender;
- (IBAction)makeSearchFieldFirstResponder:(id)sender;
- (void)itemTableViewDoubleClicked:(id)sender;

- (IBAction)addItem:(id)sender;
- (IBAction)clearInventoryItems:(id)sender;
- (IBAction)copyWorldSeed:(id)sender;
- (IBAction)incrementTime:(id)sender;

- (void)saveWorld;
- (BOOL)loadWorldAtPath:(NSString *)path;
- (BOOL)isDocumentEdited;
- (BOOL)worldFolderContainsPath:(NSString *)path;

- (void)clearInventory;
- (void)unloadWorld;

- (void)loadInventory:(NSArray *)newInventory;
- (NSArray *)currentInventory;
- (void)addInventoryItemID:(short)item damage:(short)damage selectItem:(BOOL)flag;

@end
