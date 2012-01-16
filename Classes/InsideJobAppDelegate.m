//
//  InsideJobAppDelegate.m
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "InsideJobAppDelegate.h"
#import "IJInventoryWindowController.h"

@implementation InsideJobAppDelegate
@synthesize bundleVersionNumber;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	BOOL shouldClose = [inventoryWindowController windowShouldClose:inventoryWindowController.window];
	if (shouldClose)
		return NSTerminateNow;
	else
		return NSTerminateCancel;
}

- (NSString *)bundleVersionNumber
{
  return [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
}

@end
