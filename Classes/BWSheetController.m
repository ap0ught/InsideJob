//
//  BWSheetController.m
//  BWToolkit
//
//  Created by Brandon Walkin (www.brandonwalkin.com)
//  All code is provided under the New BSD license.
/*
 
 Copyright (c) 2010, Brandon Walkin
 All rights reserved.
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 •	Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 •	Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the distribution.
 •	Neither the name of the Brandon Walkin nor the names of its contributors may be used to endorse or
 promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */
//

#import "BWSheetController.h"
//#import "NSWindow-NSTimeMachineSupport.h"

@implementation BWSheetController

@synthesize parentWindow, sheet, delegate, errorMessage;

- (void)awakeFromNib
{
	// Hack so the sheet doesn't appear at launch in Cocoa Simulator (or in the actual app if "Visible at Launch" is checked)
	[sheet setAlphaValue:0];
	[sheet performSelector:@selector(orderOut:) withObject:nil afterDelay:0];
	
	// If the sheet has a toolbar or a bottom bar, make sure those elements can't move the window
	if ([sheet respondsToSelector:@selector(setMovable:)])
		[sheet setMovable:NO];
}

- (id)initWithCoder:(NSCoder *)decoder;
{
    if ((self = [super init]) != nil)
	{
		NSWindowController *tempSheetController = [decoder decodeObjectForKey:@"BWSCSheet"];
		NSWindowController *tempParentWindowController = [decoder decodeObjectForKey:@"BWSCParentWindow"];
		
		sheet = [tempSheetController window];
		parentWindow = [tempParentWindowController window];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{	
	NSWindowController *tempSheetController = [[[NSWindowController alloc] initWithWindow:sheet] autorelease];
	NSWindowController *tempParentWindowController = [[[NSWindowController alloc] initWithWindow:parentWindow] autorelease];
	
	[coder encodeObject:tempSheetController forKey:@"BWSCSheet"];
	[coder encodeObject:tempParentWindowController forKey:@"BWSCParentWindow"];
}

- (IBAction)openSheet:(id)sender
{
	[sheet setAlphaValue:1];
	[NSApp beginSheet:sheet modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)closeSheet:(id)sender
{
	[errorMessage setStringValue:@""];
	[sheet orderOut:nil];
	[NSApp endSheet:sheet];
}

- (IBAction)messageDelegateAndCloseSheet:(id)sender
{
	if (delegate != nil && [delegate respondsToSelector:@selector(shouldCloseSheet:)])
	{	
		if ([delegate performSelector:@selector(shouldCloseSheet:) withObject:sender])	
			[self closeSheet:self];
	}
	else
	{
		[self closeSheet:self];
	}
}

- (void)setSheetErrorMessage:(NSString *)msg
{
	[errorMessage setStringValue:msg];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	if (anItem.action == @selector(openSheet:))
		return inventoryController.inventory != nil;
	
	return YES;
}

@end
