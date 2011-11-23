//
//  IJMinecraftLevel.m
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJMinecraftLevel.h"
#import "IJInventoryItem.h"

@implementation IJMinecraftLevel

- (NBTContainer *)containerWithName:(NSString *)theName inArray:(NSArray *)array
{
	for (NBTContainer *container in array)
	{
		if ([container.name isEqual:theName])
			return container;
	}
	return nil;
}

- (NBTContainer *)inventoryList
{
	// Inventory is found in:
	// - compound "Data"
	//   - compound "Player"
	//     - list "Inventory"
	//       *
	NBTContainer *dataCompound = [self childNamed:@"Data"];
	NBTContainer *playerCompound = [dataCompound childNamed:@"Player"];
	NBTContainer *inventoryList = [playerCompound childNamed:@"Inventory"];
	// TODO: Check for error conditions here.
	return inventoryList;
}

- (NSArray *)inventory
{
	NSMutableArray *output = [NSMutableArray array];
	for (NSArray *listItems in [self inventoryList].children)
	{
		IJInventoryItem *invItem = [[IJInventoryItem alloc] init];
		
		invItem.itemId = [[self containerWithName:@"id" inArray:listItems].numberValue shortValue];
		invItem.count = [[self containerWithName:@"Count" inArray:listItems].numberValue unsignedCharValue];
		invItem.damage = [[self containerWithName:@"Damage" inArray:listItems].numberValue shortValue];
		invItem.slot = [[self containerWithName:@"Slot" inArray:listItems].numberValue unsignedCharValue];
    
    NBTContainer *dataTagContainer = [self containerWithName:@"tag" inArray:listItems];
    for (NSArray *tagItems in [dataTagContainer childNamed:@"ench"].children)
    {
      NSNumber *enchId = [self containerWithName:@"id" inArray:tagItems].numberValue;
      NSNumber *enchLvl = [self containerWithName:@"lvl" inArray:tagItems].numberValue;
      [invItem.dataTag setObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects: enchId, enchLvl, nil]
                                                             forKeys:[NSArray arrayWithObjects: @"id", @"lvl", nil]]
                          forKey:@"ench"];
    }
		[output addObject:invItem];
		[invItem release];
	}
	return output;
}

- (void)setInventory:(NSArray *)newInventory
{
	NSMutableArray *newChildren = [NSMutableArray array];
	NBTContainer *inventoryList = [self inventoryList];
	
	if (inventoryList.listType != NBTTypeCompound) {
		// There appears to be a bug in the way Minecraft writes empty inventory lists; it appears to
		// set the list type to 'byte', so we will correct it here.
		NSLog(@"%s Fixing inventory list type; was %d.", __PRETTY_FUNCTION__, inventoryList.listType);
		inventoryList.listType = NBTTypeCompound;
	}
  
  // TODO - finish enchantment saving.
	for (IJInventoryItem *invItem in newInventory) {
    NSArray *listItems = [NSArray arrayWithObjects:
                          [NBTContainer containerWithName:@"id" type:NBTTypeShort numberValue:[NSNumber numberWithShort:invItem.itemId]],
                          [NBTContainer containerWithName:@"Damage" type:NBTTypeShort numberValue:[NSNumber numberWithShort:invItem.damage]],
                          [NBTContainer containerWithName:@"Count" type:NBTTypeByte numberValue:[NSNumber numberWithShort:invItem.count]],
                          [NBTContainer containerWithName:@"Slot" type:NBTTypeByte numberValue:[NSNumber numberWithShort:invItem.slot]],
                          nil];
    
    
    if ([invItem.dataTag count] != 0) {
      NBTContainer *dataTagContainer = [NBTContainer compoundWithName:@"tag"];
      NBTContainer *enchListContainer = [NBTContainer listWithName:@"ench" type:NBTTypeCompound];
      NSDictionary *itemEnchantment = [invItem.dataTag objectForKey:@"ench"];
      
      enchListContainer.children = [NSMutableArray arrayWithObjects:
                                    [NBTContainer containerWithName:@"id" type:NBTTypeShort numberValue:[itemEnchantment objectForKey:@"id"]],
                                    [NBTContainer containerWithName:@"lvl" type:NBTTypeShort numberValue:[itemEnchantment objectForKey:@"lvl"]],
                                    nil];
      
      dataTagContainer.children = [NSMutableArray arrayWithObject:enchListContainer];
      listItems = [listItems arrayByAddingObject:dataTagContainer];
    }
    
    [newChildren addObject:listItems];
	}
	inventoryList.children = newChildren;
}


- (NSNumber *)time
{
	return [[self childNamed:@"Data"] childNamed:@"Time"].numberValue;
}

- (void)setTime:(NSNumber *)number
{
	[[self childNamed:@"Data"] childNamed:@"Time"].numberValue = number;
}

- (NSString *)worldName
{
	return [[self childNamed:@"Data"] childNamed:@"LevelName"].stringValue;
}

- (void)setWorldName:(NSString *)string
{
	[[self childNamed:@"Data"] childNamed:@"LevelName"].stringValue = string;
}

- (NSNumber *)seed
{
	return [[self childNamed:@"Data"] childNamed:@"RandomSeed"].numberValue;
}

- (NSNumber *)spawnX
{
	return [[self childNamed:@"Data"] childNamed:@"SpawnX"].numberValue;
}

- (void)setSpawnX:(NSNumber *)number
{
	[[self childNamed:@"Data"] childNamed:@"SpawnX"].numberValue = number;
}

- (NSNumber *)spawnY
{
	return [[self childNamed:@"Data"] childNamed:@"SpawnY"].numberValue;
}

- (void)setSpawnY:(NSNumber *)number
{
	[[self childNamed:@"Data"] childNamed:@"SpawnY"].numberValue = number;
}

- (NSNumber *)spawnZ
{
	return [[self childNamed:@"Data"] childNamed:@"SpawnZ"].numberValue;
}

- (void)setSpawnZ:(NSNumber *)number
{
	[[self childNamed:@"Data"] childNamed:@"SpawnZ"].numberValue = number;
}

- (int)gameMode
{
  int gameType = [[[self childNamed:@"Data"] childNamed:@"GameType"].numberValue unsignedIntValue];
  int hardcore = [[[self childNamed:@"Data"] childNamed:@"hardcore"].numberValue unsignedCharValue];
  
  if (hardcore == 1 && gameType == 0)
    return 2;
  return gameType;
}

- (void)setGameMode:(int)number
{
  if (number == 0 || number == 1) {
    [[self childNamed:@"Data"] childNamed:@"GameType"].numberValue = [NSNumber numberWithInt:number];
    [[self childNamed:@"Data"] childNamed:@"hardcore"].numberValue = [NSNumber numberWithInt:0];
  }
  else if (number == 2) {
    [[self childNamed:@"Data"] childNamed:@"GameType"].numberValue = [NSNumber numberWithInt:0];
    [[self childNamed:@"Data"] childNamed:@"hardcore"].numberValue = [NSNumber numberWithInt:1];
  }
}


#pragma mark -
#pragma mark Helpers

+ (BOOL)worldExistsAtPath:(NSString *)worldPath
{
	return [[NSFileManager defaultManager] fileExistsAtPath:[self levelDataPathForWorld:worldPath]];
}

+ (NSString *)levelDataPathForWorld:(NSString *)worldPath
{
	return [worldPath stringByAppendingPathComponent:@"level.dat"];
}

+ (NSData *)dataWithInt64:(int64_t)v
{
	NSMutableData *data = [NSMutableData data];
	uint32_t v0 = htonl(v >> 32);
	uint32_t v1 = htonl(v);
	[data appendBytes:&v0 length:4];
	[data appendBytes:&v1 length:4];
	return data;
}
+ (int64_t)int64FromData:(NSData *)data
{
	uint8_t *bytes = (uint8_t *)[data bytes];
	uint64_t n = ntohl(*((uint32_t *)(bytes + 0)));
	n <<= 32;
	n += ntohl(*((uint32_t *)(bytes + 4)));
	return n;
}

+ (int64_t)writeToSessionLockAtPath:(NSString *)worldPath
{
	NSString *path = [worldPath stringByAppendingPathComponent:@"session.lock"];
	NSDate *now = [NSDate date];
	NSTimeInterval interval = [now timeIntervalSince1970];
	int64_t milliseconds = (int64_t)(interval * 1000.0);
	// write as number of milliseconds
	
	NSData *data = [self dataWithInt64:milliseconds];
	[data writeToFile:path atomically:YES];
	
	return milliseconds;
}

+ (BOOL)checkSessionLockAtPath:(NSString *)worldPath value:(int64_t)checkValue
{
	NSString *path = [worldPath stringByAppendingPathComponent:@"session.lock"];
	NSData *data = [NSData dataWithContentsOfFile:path];

	if (!data)
	{
		NSLog(@"Failed to read session lock at %@", path);
		return NO;
	}
	
	int64_t milliseconds = [self int64FromData:data];
	return checkValue == milliseconds;
}


@end
