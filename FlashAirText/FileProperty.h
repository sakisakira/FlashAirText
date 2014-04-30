//
//  FileProperty.h
//  FlashAirText
//
//  Created by sakira on 2014/04/26.
//  Copyright (c) 2014年 sakira. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileProperty : NSObject

@property NSString *directory;
@property NSString *filename;
@property NSInteger size, attribute, date, time;

@property (readonly) BOOL isDirectory;

@end
