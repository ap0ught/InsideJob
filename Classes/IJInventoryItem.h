//
//  IJInventoryItem.h
//  InsideJob
//
//  Created by Adam Preble on 10/7/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// See: http://www.minecraftwiki.net/wiki/Data_values
#define IJInventorySlotQuickFirst   (0)
#define IJInventorySlotQuickLast    (8)
#define IJInventorySlotNormalFirst  (9)
#define IJInventorySlotNormalLast  (35)
#define IJInventorySlotArmorLast  (103) // head
#define IJInventorySlotArmorFirst (100) // feet


@interface IJInventoryItem : NSObject <NSCoding> {
	int16_t itemId;
	int16_t damage;
	int8_t count;
	int8_t slot;
  NSMutableDictionary *dataTag;
}
@property (nonatomic, assign) int16_t itemId;
@property (nonatomic, assign) int16_t damage;
@property (nonatomic, assign) int8_t count;
@property (nonatomic, assign) int8_t slot;
@property (nonatomic, assign) NSMutableDictionary *dataTag;

@property (nonatomic, readonly) NSString *humanReadableName;
@property (nonatomic, readonly) NSImage *image;

+ (id)emptyItemWithSlot:(uint8_t)slot;

+ (NSDictionary *)itemIdLookup;
+ (NSDictionary *)enchantmentLookup;
+ (NSString *)enchantmentNameForId:(NSNumber *)aId;

+ (NSImage *)imageForItemId:(uint16_t)itemId withDamage:(uint16_t)damage;

@end
