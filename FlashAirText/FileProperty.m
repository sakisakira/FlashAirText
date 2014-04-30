//
//  FileProperty.m
//  FlashAirText
//
//  Created by sakira on 2014/04/26.
//  Copyright (c) 2014年 sakira. All rights reserved.
//

#import "FileProperty.h"

@implementation FileProperty
@dynamic isDirectory;

- (BOOL)isDirectory {
  return ((self.attribute & 0x10) != 0);
}

@end
