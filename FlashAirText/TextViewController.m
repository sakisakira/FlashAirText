//
//  TextViewController.m
//  FlashAirText
//
//  Created by sakira on 2014/04/26.
//  Copyright (c) 2014年 sakira. All rights reserved.
//

#import "TextViewController.h"
#import "FileListViewController.h"

@interface TextViewController ()
<UITextViewDelegate>

@end

@implementation TextViewController {
  __weak IBOutlet UITextView *textView;
  __weak IBOutlet UILabel *fileNameLabel;
  __weak IBOutlet UIButton *closeButton;
  __weak IBOutlet UIButton *uploadButton;
  __weak IBOutlet UIButton *hideKeyboardButton;
  
  CGRect originalTextViewRect, originalCloseButtonRect, originalUploadButtonRect;
  NSString *originalText;
  CGRect originalViewRect;
  NSString *_filePath;
}
@dynamic fileName, fileDirectory, filePath;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setFilePath:(NSString *)filePath {
  _filePath = [filePath copy];
  [self setFileNameLabel];
  
  if (self.isNewFile)
    textView.text = @"";
  else
    [self loadTextFile];
}

- (NSString*)filePath {
  return [_filePath copy];
}

- (NSString*)fileName {
  return [[self.filePath pathComponents] lastObject];
}

- (NSString*)fileDirectory {
  NSMutableArray *path_comps = [self.filePath pathComponents].mutableCopy;
  [path_comps removeLastObject];
  return [NSString pathWithComponents:path_comps];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  originalTextViewRect = textView.frame;
  originalViewRect = self.view.frame;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [self setFileNameLabel];
  [self loadTextFile];
 
  hideKeyboardButton.enabled = NO;
  uploadButton.enabled = NO;
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(keyboardWillShow:)
   name:UIKeyboardWillShowNotification
   object:nil];
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(keyboardWillHide:)
   name:UIKeyboardWillHideNotification
   object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [[NSNotificationCenter defaultCenter]
   removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  originalTextViewRect = textView.frame;
  originalViewRect = self.view.frame;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  
  [textView resignFirstResponder];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  
  originalViewRect = self.view.frame;
  originalTextViewRect = textView.frame;
  
  NSLog(@"original view rect changed to %@", [NSValue valueWithCGRect:originalViewRect]);
}

#pragma mark - Communication

- (void)loadTextFile {
  if (!self.filePath) {
    NSLog(@"TextViewController#filePath has not been initialized.");
    textView.text = originalText = @"";
    return;
  }
  
  NSURL *cmd_url =
  [NSURL URLWithString:
   [baseURLString() stringByAppendingString:self.filePath]];
  NSError *error = nil;
  NSString *str =
  [NSString stringWithContentsOfURL:cmd_url
                           encoding:NSShiftJISStringEncoding
                              error:&error];
  if (error) {
    NSLog(@"get file list error %@", error);
    textView.text = originalText = @"";
    return;
  }
  textView.text = originalText = [str stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
}

- (void)setFileNameLabel {
  fileNameLabel.text = self.fileName;
}

- (NSString*)dateString {
  NSDate *systemdate = [NSDate date];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *dateCompnents;
  dateCompnents =[calendar components:NSYearCalendarUnit
                  | NSMonthCalendarUnit
                  | NSDayCalendarUnit
                  | NSHourCalendarUnit
                  | NSMinuteCalendarUnit
                  | NSSecondCalendarUnit fromDate:systemdate];
  NSInteger year = ([dateCompnents year] - 1980) << 9;
  NSInteger month = ([dateCompnents month]) << 5;
  NSInteger day = [dateCompnents day];
  NSInteger hour = [dateCompnents hour] << 11;
  NSInteger minute = [dateCompnents minute]<< 5;
  NSInteger second = floor([dateCompnents second]/2);
  NSString *datePart = [@"0x" stringByAppendingString:
                        [NSString stringWithFormat:@"%04x%04x" ,
                         (unsigned int)(year+month+day),
                         (unsigned int)(hour+minute+second)]];
  return datePart;
}

- (void)prepareForUpload {
  NSURL *url =
  [NSURL URLWithString:
   [baseURLString() stringByAppendingFormat:
    @"upload.cgi?WRITEPROTECT=ON&UPDIR=%@&FTIME=%@",
    self.fileDirectory, [self dateString]]];
  // Run cgi
  NSError *error;
  NSString *rtnStr =[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
  if ([error.domain isEqualToString:NSCocoaErrorDomain]) {
    NSLog(@"upload.cgi %@\n",error);
    return;
  } else {
    if(![rtnStr isEqualToString:@"SUCCESS"]){
      [[[UIAlertView alloc]
       initWithTitle:self.title
       message:@"upload.cgi:setup failed"
       delegate:nil
       cancelButtonTitle:nil
        otherButtonTitles:@"OK", nil] show];
      return;
    }
  }
}

- (void)uploadData {
  NSString *text = [textView.text stringByReplacingOccurrencesOfString:@"\n" withString:@"\r\n"];
  NSData *textData = [text dataUsingEncoding:NSShiftJISStringEncoding];
  //url
  NSURL *url = [NSURL URLWithString:
                [baseURLString() stringByAppendingString:@"upload.cgi"]];
  //boundary
  CFUUIDRef uuid = CFUUIDCreate(nil);
  CFStringRef uuidString = CFUUIDCreateString(nil, uuid);
  CFRelease(uuid);
  NSString *boundary = [NSString stringWithFormat:@"flashair-%@",uuidString];
  //header
  NSString *header = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
  //body
  NSMutableData *body = [NSMutableData data];
  [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary]
                    dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:
                     @"Content-Disposition: form-data; name=\"file\";filename=\"%@\"\r\n",
                     self.fileName]
          dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"Content-Type: text/plain\r\n\r\n"]
                    dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:textData];
  [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary]
                    dataUsingEncoding:NSUTF8StringEncoding]];
  //Request
  NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"POST"];
  [request addValue:header forHTTPHeaderField:@"Content-Type"];
  [request setHTTPBody:body];
  NSError *error = nil;
  NSURLResponse *response;
  NSData *result = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
  NSString *rtnStr = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
  if ([error.domain isEqualToString:NSCocoaErrorDomain]){
    NSLog(@"upload.cgi %@\n",error);
    return;
  } else {
    if([rtnStr rangeOfString:@"Success"].location == NSNotFound){     //v2.0
      [[[UIAlertView alloc]
        initWithTitle:self.title
        message:@"upload.cgi: POST failed" delegate:nil
        cancelButtonTitle:nil otherButtonTitles:@"OK", nil]
       show];
      return;
    }
  }
  originalText = textView.text;
  uploadButton.enabled = NO;
}

#pragma mark - User Interface

- (IBAction)closeButtonPressed:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)uploadButtonPressed:(id)sender {
  [self prepareForUpload];
  [self uploadData];
  
  if (self.parentViewController) {
    // iPad series
    FileListViewController *vc = self.parentViewController.childViewControllers[0];
    [vc fetchFileList];
  }
}

- (IBAction)hideKeyboardButtonPressed:(id)sender {
  [textView resignFirstResponder];
}

- (void)keyboardWillShow:(NSNotification*)noti {
  CGRect kb_rect = [[noti.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  
  UIInterfaceOrientation orientation =
  [UIApplication sharedApplication].statusBarOrientation;
  CGRect rect = originalViewRect;
  CGRect tvrect = originalTextViewRect;
  
  if (UIDeviceOrientationIsPortrait(orientation)) {
    rect.size.height -= kb_rect.size.height;
    tvrect.size.height -= kb_rect.size.height;
  } else {
    rect.size.width -= kb_rect.size.width;
    if (kb_rect.origin.x == 0)
      rect.origin.x = kb_rect.size.width;
    tvrect.size.height -= kb_rect.size.width;
  }
  
  NSLog(@"original view rect %@", [NSValue valueWithCGRect:originalViewRect]);
  NSLog(@"keyboard rect %@, view rect %@", [NSValue valueWithCGRect:kb_rect], [NSValue valueWithCGRect:rect]);
  NSLog(@"textView.rect %@, orig %@, tvrect %@", [NSValue valueWithCGRect:textView.frame], [NSValue valueWithCGRect:originalTextViewRect], [NSValue valueWithCGRect:tvrect]);

  if (self.parentViewController) {
    // iPad series
    [UIView animateWithDuration:0.3 animations:^{textView.frame = tvrect;}];
  } else {
    // iPhone series
    [UIView animateWithDuration:0.3 animations:^{self.view.frame = rect;}];
  }
  hideKeyboardButton.enabled = YES;

  NSLog(@"textView.rect %@, orig %@, tvrect %@", [NSValue valueWithCGRect:textView.frame], [NSValue valueWithCGRect:originalTextViewRect], [NSValue valueWithCGRect:tvrect]);

}

- (void)keyboardWillHide:(NSNotification*)noti {
  [UIView animateWithDuration:0.5
                   animations:
   ^{
     self.view.frame = originalViewRect;
     textView.frame = originalTextViewRect;
   }];
  hideKeyboardButton.enabled = NO;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView_ {
  uploadButton.enabled = (self.filePath && ![textView_.text isEqualToString:originalText]);
}

@end
