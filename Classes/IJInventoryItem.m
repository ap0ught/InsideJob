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
  return [NSString stringWithFormat:@"<%@ %p itemId=%hi name=%@ count=%d slot=%d damage=%hi",
          NSStringFromClass([self class]), self, itemId, self.humanReadableName, self.count, self.slot, self.damage];
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
    return [NSString stringWithFormat:@"Unknown Item (%hi)", self.itemId];
}


- (void)setItemId:(int16_t)newItemId
{
  [self willChangeValueForKey:@"humanReadableName"];
  itemId = newItemId;
  [self didChangeValueForKey:@"humanReadableName"];
}

- (void)setNilValueForKey:(NSString*)key 
{
  if ([key isEqualToString:@"itemId"]) {
    [self setItemId:1];
    return;
  }
  else if ([key isEqualToString:@"damage"]) {
    [self setDamage:0];
    return;
  }
  else if ([key isEqualToString:@"count"]) {
    [self setCount:1];
    return;
  }
  
  [super setNilValueForKey:key];
}


- (void)addValuesObserver:(id)observer
{
  [self addObserver:observer forKeyPath:@"itemId" options:0 context:@"KVO_ITEM_CHANGED"];
  [self addObserver:observer forKeyPath:@"count" options:0 context:@"KVO_ITEM_CHANGED"];
  [self addObserver:observer forKeyPath:@"damage" options:0 context:@"KVO_ITEM_CHANGED"];
}

- (void)removeValuesObserver:(id)observer
{
  [self removeObserver:observer forKeyPath:@"itemId"];
  [self removeObserver:observer forKeyPath:@"count"];
  [self removeObserver:observer forKeyPath:@"damage"];
}


+ (NSString *)enchantmentNameForId:(NSNumber *)aId
{
  NSDictionary *enchantment = [[IJInventoryItem enchantmentLookup] objectForKey:aId];
  return [enchantment objectForKey:@"Name"];
}

+ (NSImage *)imageForItemId:(uint16_t)itemId withDamage:(uint16_t)damage
{
  if (itemId == 0)
    return nil;
  
  NSString *fileName = [NSString stringWithFormat:@"%hi",itemId];
  NSString *filePath;
  NSString *outputPath = nil;
  
  filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"png" inDirectory:@"Sprites"];
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    outputPath = filePath;
  }
  
  if (damage != 0)
    fileName = [fileName stringByAppendingFormat:@"-%hi",damage];
  
  filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"png" inDirectory:@"Sprites"];
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    outputPath = filePath;
  }

  if (!outputPath)
    outputPath = [[NSBundle mainBundle] pathForResource:@"blockNotFound" ofType:@"png"];

  return [[[NSImage alloc] initWithContentsOfFile:outputPath] autorelease];
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
