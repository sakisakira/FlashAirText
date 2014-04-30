//
//  TextViewController.h
//  FlashAirText
//
//  Created by sakira on 2014/04/26.
//  Copyright (c) 2014年 sakira. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextViewController : UIViewController

@property NSString *filePath;
@property (readonly) NSString *fileName, *fileDirectory;

@end
