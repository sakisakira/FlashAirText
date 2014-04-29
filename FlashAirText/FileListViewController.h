//
//  FileListViewController.h
//  FlashAirText
//
//  Created by sakira on 2014/04/25.
//  Copyright (c) 2014年 sakira. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *BaseURLString;

@interface FileListViewController : UIViewController

@property NSString* directory;
@property (readonly) BOOL isRootDirectory;

@end
