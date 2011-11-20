//
//  IJMinecraftPlayer.m
//  InsideJob
//
//  Created by Ben K on 11/10/27.
//  Copyright 2011 Ben K. All rights reserved.
//

#import "IJMinecraftPlayer.h"
#import "IJInventoryItem.h"


@implementation IJMinecraftPlayer

- (NBTContainer *)containerWithName:(NSString *)theName inArray:(NSArray *)array
{
	for (NBTContainer *container in array) {
		if ([container.name isEqual:theName])
			return container;
	}
	return nil;
}


- (NSArray *)inventory
{
	NSMutableArray *output = [NSMutableArray array];
	for (NSArray *listItems in [self childNamed:@"Inventory"].children)
	{
		IJInventoryItem *invItem = [[IJInventoryItem alloc] init];
		
		invItem.itemId = [[self containerWithName:@"id" inArray:listItems].numberValue shortValue];
		invItem.count = [[self containerWithName:@"Count" inArray:listItems].numberValue unsignedCharValue];
		invItem.damage = [[self containerWithName:@"Damage" inArray:listItems].numberValue shortValue];
		invItem.slot = [[self containerWithName:@"Slot" inArray:listItems].numberValue unsignedCharValue];
		[output addObject:invItem];
		[invItem release];
	}
	return output;
}

- (void)setInventory:(NSArray *)newInventory
{
	NSMutableArray *newChildren = [NSMutableArray array];
	NBTContainer *inventoryList = [self childNamed:@"Inventory"];
	
	if (inventoryList.listType != NBTTypeCompound)
	{
		// There appears to be a bug in the way Minecraft writes empty inventory lists; it appears to
		// set the list type to 'byte', so we will correct it here.
		NSLog(@"%s Fixing inventory list type; was %d.", __PRETTY_FUNCTION__, inventoryList.listType);
		inventoryList.listType = NBTTypeCompound;
	}
	
	for (IJInventoryItem *invItem in newInventory)
	{
		NSArray *listItems = [NSArray arrayWithObjects:
                          [NBTContainer containerWithName:@"id" type:NBTTypeShort numberValue:[NSNumber numberWithShort:invItem.itemId]],
                          [NBTContainer containerWithName:@"Damage" type:NBTTypeShort numberValue:[NSNumber numberWithShort:invItem.damage]],
                          [NBTContainer containerWithName:@"Count" type:NBTTypeByte numberValue:[NSNumber numberWithShort:invItem.count]],
                          [NBTContainer containerWithName:@"Slot" type:NBTTypeByte numberValue:[NSNumber numberWithShort:invItem.slot]],
                          nil];
		[newChildren addObject:listItems];
	}
	[inventoryList setChildren:newChildren];
}

- (NSNumber *)xpLevel
{
	return [self childNamed:@"XpLevel"].numberValue;
}

- (void)setXpLevel:(NSNumber *)number
{
	[self childNamed:@"XpLevel"].numberValue = number;
}

- (NSNumber *)health
{  
	return [self childNamed:@"Health"].numberValue;
}

- (void)setHealth:(NSNumber *)number
{
	[self childNamed:@"Health"].numberValue = number;
}

- (NSNumber *)hunger
{
	return [self childNamed:@"Hunger"].numberValue;
}

- (void)setHunger:(NSNumber *)number
{
	[self childNamed:@"Hunger"].numberValue = number;
}

@end
