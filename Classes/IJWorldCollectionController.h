//
//  IJWorldCollectionController.h
//  InsideJob
//
//  Created by Ben K on 2011/03/14.
//  Copyright 2011 Ben K. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IJInventoryWindowController;

@interface IJWorldCollectionController : NSObject {
  IBOutlet NSCollectionView *worldCollectionView;
  IBOutlet NSButton *chooseButton;
  IBOutlet NSTextField *noWorldsLabel;
  IBOutlet IJInventoryWindowController *InventoryWindowController;
  
  NSMutableArray *worldArray;
}

@property (nonatomic, retain) NSMutableArray *worldArray;

- (void)openWorldAtPath:(NSString *)path;
- (IBAction)openSelectedWorld:(id)sender;

- (void)reloadWorldData;
- (void)loadWorldData;

- (void)addPathToCollection:(NSString *)path withImage:(NSImage *)icon;


@end
