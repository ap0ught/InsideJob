//
//  BWSheetController.h
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

#import <Cocoa/Cocoa.h>
#import "IJInventoryWindowController.h"

@interface BWSheetController : NSObject
{
	IBOutlet IJInventoryWindowController *inventoryController;
	NSWindow *sheet;
	NSWindow *parentWindow;
	NSTextField *errorMessage;
	id delegate;
}

@property (nonatomic, retain) IBOutlet NSWindow *sheet, *parentWindow;
@property (nonatomic, retain) IBOutlet id delegate;
@property (nonatomic, retain) IBOutlet NSTextField *errorMessage;

- (IBAction)openSheet:(id)sender;
- (IBAction)closeSheet:(id)sender;
- (IBAction)messageDelegateAndCloseSheet:(id)sender;
- (void)setSheetErrorMessage:(NSString *)msg;

// The optional delegate should implement the method:
// - (BOOL)shouldCloseSheet:(id)sender
// Return YES if you want the sheet to close after the button click, NO if it shouldn't close. The sender
// object is the button that requested the close. This is helpful because in the event that there are multiple buttons
// hooked up to the messageDelegateAndCloseSheet: method, you can distinguish which button called the method. 

@end
