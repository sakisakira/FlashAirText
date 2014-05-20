//
//  ADViewController.m
//  FlashAirText
//
//  Created by Akira Suzuki on 2014/05/20.
//  Copyright (c) 2014年 sakira. All rights reserved.
//

#import "ADViewController.h"
#import "BaseViewController.h"
@import iAd;

const CGFloat ADBannerHeight_iPad = 66;

@interface ADViewController ()
<ADBannerViewDelegate>

@end

@implementation ADViewController {
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView {
  [super loadView];
  
  UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
  BaseViewController *bvc = [sb instantiateViewControllerWithIdentifier:@"BaseViewController"];
  
  [self addChildViewController:bvc];
  bvc.view.frame = self.contentView.frame;
  [self.contentView addSubview:bvc.view];
  
  [bvc didMoveToParentViewController:self];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - ADBannerViewDelegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
  CGRect frame = banner.frame;
  if (frame.size.height == 0) {
    frame.size.height = ADBannerHeight_iPad;
    frame.origin.y -= ADBannerHeight_iPad;
  }
  [UIView animateWithDuration:0.3
                   animations:
   ^{
     banner.frame = frame;
     banner.alpha = 1;
   }];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
  CGRect frame = banner.frame;
  if (frame.size.height != 0) {
    frame.size.height = 0;
    frame.origin.y += ADBannerHeight_iPad;
  }
  [UIView animateWithDuration:0.3
                   animations:
   ^{
     banner.frame = frame;
     banner.alpha = 0;
   }];
}


@end
