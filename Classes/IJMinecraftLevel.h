//
//  IJMinecraftLevel.h
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NBTContainer.h"

@interface IJMinecraftLevel : NBTContainer {
  NSString *worldName;
  int gameMode;
}

@property (nonatomic, copy) NSArray *inventory; // Array of IJInventoryItem objects.

@property (nonatomic, copy) NSString *worldName;
@property (nonatomic, copy) NSNumber *time;
@property int gameMode;
@property (readonly, copy) NSNumber *seed;
@property (nonatomic, copy) NSNumber *spawnX;
@property (nonatomic, copy) NSNumber *spawnY;
@property (nonatomic, copy) NSNumber *spawnZ;
@property BOOL weather;
@property BOOL cheats;


+ (NSString *)levelDataPathForWorld:(NSString *)worldPath;

+ (BOOL)worldExistsAtPath:(NSString *)worldPath;
+ (BOOL)isMultiplayerWorld:(NSString *)worldPath;

+ (int64_t)writeToSessionLockAtPath:(NSString *)worldPath;
+ (BOOL)checkSessionLockAtPath:(NSString *)worldPath value:(int64_t)checkValue;


@end
