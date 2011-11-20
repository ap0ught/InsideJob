//
//  IJWorldCollectionController.m
//  InsideJob
//
//  Created by Ben K on 2011/03/14.
//  Copyright 2011 Ben K. All rights reserved.
//

#import "IJWorldCollectionController.h"
#import "IJInventoryWindowController.h"


@implementation IJWorldCollectionController
@synthesize worldArray;


- (void)awakeFromNib
{
  worldArray = [[NSMutableArray alloc] init];
  //Add a new observer to the array controller of the collection view
  [worldCollectionView addObserver:self forKeyPath:@"selectionIndexes" options:NSKeyValueObservingOptionNew context:nil];
  
  [self loadWorldData];
}

// Observe the worldArray controller selection and change enabled state of the choose button accordingly.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualTo:@"selectionIndexes"]) {
    if ([[worldCollectionView selectionIndexes] count] > 0) {
      [chooseButton setEnabled:YES];
    }
    else {
      [chooseButton setEnabled:NO];
    }
  }
}

- (void)openWorldAtPath:(NSString *)path
{
  [InventoryWindowController loadWorldAtPath:path];
}

- (IBAction)openSelectedWorld:(id)sender
{
  int index = [[worldCollectionView selectionIndexes] firstIndex];
  NSString *path = [[worldArray objectAtIndex:index] valueForKey:@"Path"];
  [InventoryWindowController loadWorldAtPath:path];
}


- (void)reloadWorldData
{
  [worldArray removeAllObjects];
  [self loadWorldData];
}

- (void)loadWorldData
{
  NSString *path = [@"~/library/application support/minecraft/saves/" stringByExpandingTildeInPath];
  NSArray *folderArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
  int index;
  
  // Worlds in 'application support/minecraft/saves/'
  for (index = 0; index < [folderArray count]; index++) {
    NSString *fileName = [folderArray objectAtIndex:index];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    
    [self addPathToCollection:filePath withImage:[NSImage imageNamed:@"World"]];		
  }
  
  // Recently opened worlds
  NSArray *recentWorlds = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
  
  for (index = 0; index < [recentWorlds count]; index++) {
    NSString *filePath = [[recentWorlds objectAtIndex:index] path];
    [self addPathToCollection:filePath withImage:[NSImage imageNamed:@"World_Recent"]];		
  }
  
  [worldCollectionView setContent:worldArray];
  [worldCollectionView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
  
  if ([worldArray count] == 0) {
    [noWorldsLabel setHidden:NO];
    [chooseButton setEnabled:NO];
  }
  else {
    [noWorldsLabel setHidden:YES];
    [chooseButton setEnabled:YES];
  }
}

- (void)addPathToCollection:(NSString *)path withImage:(NSImage *)icon
{	
  NSError *error = nil;
  NSString *fileName = [path lastPathComponent];
  NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
  
  if ([fileName hasPrefix:@"."]) {
    return;
  }
  else if (![[fileAttr valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
    return;
  }
  else if (![[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"level.dat"]]) {
    return;
  }
  
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"'Created:' MMM d yyyy 'at' h a"];
  NSString *fileMeta = [formatter stringFromDate:[fileAttr valueForKey:NSFileCreationDate]];
  [formatter release];
  
  [worldArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                         fileName, @"Name",
                         fileMeta, @"Meta",
                         icon, @"Icon",
                         self, @"Delegate",
                         path, @"Path",
                         nil]];
  
}

- (void)dealloc
{
  //Remove the collection view selectionIndexes observer
  [worldCollectionView removeObserver:self forKeyPath:@"selectionIndexes"];
  [worldArray release];
  [super dealloc];
}

@end
