//
//  FileListViewController.h
//  FlashAirText
//
//  Created by sakira on 2014/04/25.
//  Copyright (c) 2014年 sakira. All rights reserved.
//

#import <UIKit/UIKit.h>

NSString* baseURLString(void);

@interface FileListViewController : UIViewController

- (void)fetchFileList;

@property NSString* directory;
@property (readonly) BOOL isRootDirectory;

@end
