//
//  IJMinecraftPlayer.h
//  InsideJob
//
//  Created by Ben K on 11/10/27.
//  Copyright 2011 Ben K. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NBTContainer.h"

@interface IJMinecraftPlayer : NBTContainer {

}

@property (nonatomic, copy) NSArray *inventory; // Array of IJInventoryItem objects.
@property (nonatomic, copy) NSNumber *xpLevel;
@property (nonatomic, copy) NSNumber *health;
@property (nonatomic, copy) NSNumber *hunger;


- (id)initWithContainer:(NBTContainer *)cont;


@end
