//
//  IJInventoryItem.m
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import "IJInventoryItem.h"


@implementation IJInventoryItem

@synthesize itemId, slot, damage, count, dataTag;

+ (id)emptyItemWithSlot:(uint8_t)slot
{
  IJInventoryItem *obj = [[[[self class] alloc] init] autorelease];
  obj.slot = slot;
  return obj;
}

- (id)init
{
  if ((self = [super init])) {
    dataTag = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)dealloc
{
  [dataTag release];
  [super dealloc];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  if ((self = [super init]))
  {
    itemId = [decoder decodeIntForKey:@"itemId"];
    slot = [decoder decodeIntForKey:@"slot"];
    damage = [decoder decodeIntForKey:@"damage"];
    count = [decoder decodeIntForKey:@"count"];
    dataTag = [[decoder decodeObjectForKey:@"dataTag"] retain];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeInt:itemId forKey:@"itemId"];
  [coder encodeInt:slot forKey:@"slot"];
  [coder encodeInt:damage forKey:@"damage"];
  [coder encodeInt:count forKey:@"count"];
  [coder encodeObject:dataTag forKey:@"dataTag"];
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@ %p itemId=%d name=%@ count=%d slot=%d damage=%d",
          NSStringFromClass([self class]), self, itemId, self.humanReadableName, count, slot, damage];
}

- (NSString *)humanReadableName
{
  NSString *itemKey = [NSString stringWithFormat:@"%hi:%hi",self.itemId, self.damage];
  NSDictionary *itemData = [[IJInventoryItem itemIdLookup] objectForKey:itemKey];
  if (itemData == nil) {
    itemKey = [NSString stringWithFormat:@"%hi:%hi",self.itemId, 0];
    itemData = [[IJInventoryItem itemIdLookup] objectForKey:itemKey];
  }
  
  NSString *name = [itemData objectForKey:@"Name"];
  if (name) {
    name = [name stringByAppendingString:[NSString stringWithFormat:@" (%hi)", self.itemId]];
    return name;
  }
  else
    return [NSString stringWithFormat:@"%hi", self.itemId];
}

+ (NSString *)enchantmentNameForId:(NSNumber *)aId
{
  NSDictionary *enchantment = [[IJInventoryItem enchantmentLookup] objectForKey:aId];
  return [enchantment objectForKey:@"Name"];
}

+ (NSImage *)imageForItemId:(uint16_t)itemId withDamage:(uint16_t)damage
{
  NSSize itemImageSize = NSMakeSize(32, 32);
  NSPoint atlasOffset;
  NSUInteger itemsPerRow = 9;
  NSUInteger pixelsPerColumn = 36;
  NSUInteger pixelsPerRow = 56;
  NSImage *atlas;
  BOOL notFound = FALSE; 
  
  int index = 0;
  
  // Blocks
  if ((itemId <= 25 || (itemId >= 27 && itemId <= 33) || (itemId >= 35 && itemId <= 116 && itemId != 115) || (itemId == 96) || (itemId == 122)) &&
      (itemId != 36 || itemId != 95))
  {
    if (itemId <= 5) {
      index = itemId - 1;
    }
    else if (itemId == 6) {
      if (damage > 2)
        damage = 0;
      index = itemId - 1 + damage;			
    }
    else if (itemId <= 16) {
      index = itemId + 1;
    }
    else if (itemId == 17) {
      if (damage > 2)
        damage = 0;
      index = itemId + 1 + damage;
    }
    else if (itemId <= 34) {
      index = itemId + 3;		
    }
    else if (itemId == 35) {
      if (damage > 15)
        damage = 0;
      index = itemId + 10 + damage;
    }
    else if (itemId <= 43) {
      index = itemId + 24;
    }
    else if (itemId == 44) {
      if (damage > 5)
        damage = 0;
      index = itemId + 24 + damage;
    }
    else if (itemId <= 122) {
      index = itemId + 36;
    }
    
    atlasOffset = NSMakePoint(36, 75);
  }
  // Items
  else if (itemId >= 256 && itemId <= 383)
  {
    index = itemId - 256;
    if (itemId >= 352 && itemId <= 382)
      index = itemId - 241;
    if (itemId == 351) {
      if (damage > 15)
        damage = 0;
      index = itemId - 256 + damage;
    }
    if (itemId == 383) {
      int offset = 0;
      if (damage == 50) offset = 3;
      if (damage == 51) offset = 2;
      if (damage == 52) offset = 6;
      if (damage == 54) offset = 5;
      if (damage == 55) offset = 4;
      
      if (damage == 56) offset = 14;
      if (damage == 57) offset = 12;
      if (damage == 58) offset = 10;
      if (damage == 59) offset = 8;
      if (damage == 60) offset = 19;
      if (damage == 61) offset = 17;
      if (damage == 62) offset = 15;
      if (damage == 90) offset = 20;
      if (damage == 91) offset = 16;
      if (damage == 92) offset = 9;
      if (damage == 93) offset = 7;
      if (damage == 94) offset = 13;
      if (damage == 95) offset = 11;
      if (damage == 96) offset = 1;
      if (damage == 120) offset = 18;
      
      index = itemId - 241 + offset;
    }
    
    atlasOffset = NSMakePoint(445, 75);
  }
  // Records
  else if (itemId >= 2256 && itemId <= 2266 )
  {
    index = itemId - 2204;
    atlasOffset = NSMakePoint(445, pixelsPerRow*14+18);
  }
  else
  {
    NSLog(@"%s error: unrecognized item id %d", __PRETTY_FUNCTION__, itemId);
    index = 0;
    atlasOffset = NSMakePoint(0, 32);
    notFound = TRUE;
  }
  
  atlasOffset.x += pixelsPerColumn * (index % itemsPerRow);
  atlasOffset.y += pixelsPerRow    * (index / itemsPerRow);
  
  NSRect atlasRect = NSMakeRect(atlasOffset.x, atlasOffset.y, itemImageSize.width, itemImageSize.height);
  
  if (notFound != TRUE) {
    atlas = [NSImage imageNamed:@"DataValuesV110Transparent.png"];
  }else {
    atlas = [NSImage imageNamed:@"blockNotFound.png"];
  }
  
  NSImage *output = [[NSImage alloc] initWithSize:itemImageSize];
  atlasRect.origin.y = atlas.size.height - atlasRect.origin.y;
  
  [NSGraphicsContext saveGraphicsState];
  
  [output lockFocus];
  [atlas drawInRect:NSMakeRect(0, 0, itemImageSize.width, itemImageSize.height)
           fromRect:atlasRect
          operation:NSCompositeCopy
           fraction:1.0];
  [output unlockFocus];
  
  [NSGraphicsContext restoreGraphicsState];
  
  return [output autorelease];
}

- (NSImage *)image
{
  NSImage *itemImage = [IJInventoryItem imageForItemId:itemId withDamage:damage];  
  
  // Is the item enchanted or does it have a special data value?
  // ex: golden apples, bottles with damage over 1
  if ([self.dataTag objectForKey:@"ench"] || self.itemId == 322 || (self.itemId == 373 && self.damage >= 1)) {
    NSImage *tempImage = [itemImage copy];
    [tempImage lockFocus];    
    [[NSColor purpleColor] set];
    NSRectFillUsingOperation(NSMakeRect(0, 0, itemImage.size.width, itemImage.size.height), NSCompositeSourceIn);
    [tempImage unlockFocus];
    
    [itemImage lockFocus];
    [tempImage drawInRect:NSMakeRect(0, 0, itemImage.size.width, itemImage.size.height) fromRect:NSZeroRect operation:NSCompositePlusLighter fraction:0.7];
    [itemImage unlockFocus];
    [tempImage release];
  }
  
  return itemImage;
}

+ (NSDictionary *)itemIdLookup
{
  static NSDictionary *lookup = nil;
  if (!lookup)
  {
    NSError *error = nil;
    NSString *lines = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Items" withExtension:@"csv"]
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
    NSMutableDictionary *building = [NSMutableDictionary dictionary];
    [lines enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
      if ([line hasPrefix:@"#"] || [line length] == 0) // ignore lines with a # prefix or empty ones
        return;
      NSArray *components = [line componentsSeparatedByString:@","];
      if ([components count] == 0)
        return;
      NSNumber *itemId = [NSNumber numberWithShort:[[components objectAtIndex:0] intValue]];
      
      NSNumber *itemDamage = [NSNumber numberWithShort:0];
      if ([components count] > 2) {
        itemDamage = [NSNumber numberWithShort:[[components objectAtIndex:2] intValue]];
      }
      NSString *itemName = [components objectAtIndex:1];
      NSString *itemType = [components objectAtIndex:3];
      
      NSArray *objects = [NSArray arrayWithObjects:itemId, itemName, itemDamage, itemType, nil];
      NSArray *keys = [NSArray arrayWithObjects:@"ID", @"Name", @"Damage", @"Type",nil];
      NSDictionary *itemData = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
      
      NSString *itemKey = [NSString stringWithFormat:@"%@:%@",itemId,itemDamage];
      [building setObject:itemData forKey:itemKey];
    }];
    lookup = [[NSDictionary alloc] initWithDictionary:building];
  }
  return lookup;
}

+ (NSDictionary *)enchantmentLookup
{
  static NSDictionary *lookup = nil;
  if (!lookup)
  {
    NSError *error = nil;
    NSString *lines = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Enchantments" withExtension:@"csv"]
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
    NSMutableDictionary *building = [NSMutableDictionary dictionary];
    [lines enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
      if ([line hasPrefix:@"#"] || [line length] == 0) // ignore lines with a # prefix or empty ones
        return;
      NSArray *components = [line componentsSeparatedByString:@","];
      if ([components count] == 0)
        return;
      NSNumber *enchID = [NSNumber numberWithShort:[[components objectAtIndex:0] intValue]];
      
      NSString *enchName = [components objectAtIndex:1];
      NSNumber *enchMax = [NSNumber numberWithShort:[[components objectAtIndex:2] intValue]];
      NSString *enchType = [components objectAtIndex:2];
      
      NSArray *objects = [NSArray arrayWithObjects:enchID, enchName, enchMax, enchType, nil];
      NSArray *keys = [NSArray arrayWithObjects:@"ID", @"Name", @"Max", @"Type",nil];
      NSDictionary *itemData = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
      
      [building setObject:itemData forKey:enchID];
    }];
    lookup = [[NSDictionary alloc] initWithDictionary:building];
  }
  return lookup;
}


@end
