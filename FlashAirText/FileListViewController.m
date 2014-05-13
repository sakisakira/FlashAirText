//
//  FileListViewController.m
//  FlashAirText
//
//  Created by sakira on 2014/04/25.
//  Copyright (c) 2014年 sakira. All rights reserved.
//

#import "FileListViewController.h"
#import "FileProperty.h"
#import "TextViewController.h"

static NSString *BaseURLKey = @"BaseURLKey";
static NSString *CurrentDirectoryKey = @"CurrentDirectoryKey";

static const NSInteger NewFileAlertViewTag = 100;
static const NSInteger NotAliveAlertViewTag = 101;

NSString* baseURLString(void) {
  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
  NSString *url_str = [defs stringForKey:BaseURLKey];
  if (!url_str) url_str = @"http://flashair/";
  return url_str;
}

@interface FileListViewController ()
<UITableViewDelegate, UITableViewDataSource,
UIAlertViewDelegate>

@property BOOL flashAirIsAlive;

@end

@implementation FileListViewController {
  __weak IBOutlet UILabel *directoryNameLabel;
  __weak IBOutlet UITableView *fileListTableView;
  __weak IBOutlet UIButton *newFileButton;
  
  NSArray *fileProperties;
  NSString *selectedFilename;
  NSString *_directory;
  
  NSString *currentDirectory;
  BOOL isNewFile;
}

@dynamic directory, isRootDirectory, flashAirIsAlive;

- (NSString*)directory {
  return _directory.copy;
}

- (void)setDirectory:(NSString *)directory_ {
  _directory = directory_;
  dispatch_async(dispatch_get_main_queue(), ^{
    directoryNameLabel.text = directory_;
  });
}

- (BOOL)isRootDirectory {
  return ([self.directory length] == 0);
}

- (BOOL)flashAirIsAlive {
  return newFileButton.enabled;
}

- (void)setFlashAirIsAlive:(BOOL)alive {
  newFileButton.enabled = alive;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.directory = @"";
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
  currentDirectory = [defs stringForKey:CurrentDirectoryKey];
  if (currentDirectory)
    self.directory = currentDirectory;
  self.flashAirIsAlive = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  if (currentDirectory) {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs setObject:currentDirectory forKey:CurrentDirectoryKey];
    [defs synchronize];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    [self fetchFileList];
  });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  TextViewController *vc = [segue destinationViewController];
  vc.isNewFile = isNewFile;
  vc.filePath = [self.directory stringByAppendingPathComponent:selectedFilename];
  selectedFilename = nil;
  isNewFile = NO;
}

- (void)openTextViewController {
  if (!self.parentViewController) {
    // iPhone series
    [self performSegueWithIdentifier:@"TextViewController" sender:nil];
  } else {
    // iPad series
    TextViewController *vc = self.parentViewController.childViewControllers[1];
    vc.isNewFile = isNewFile;
    vc.filePath = [self.directory stringByAppendingPathComponent:selectedFilename];
    selectedFilename = nil;
    isNewFile = NO;
  }
}


#pragma mark - Communication

- (void)fetchFileList {
  selectedFilename = nil;
  
  NSURL *cmd_url =
  [NSURL URLWithString:
   [[baseURLString() stringByAppendingString:@"command.cgi?op=100&DIR=/"]
    stringByAppendingString:self.directory]];
  NSError *error = nil;
  NSString *files_str =
  [NSString stringWithContentsOfURL:cmd_url
                           encoding:NSShiftJISStringEncoding
                              error:&error];
  if (error) {
    NSLog(@"get file list error %@", error);
    currentDirectory = nil;
    self.flashAirIsAlive = NO;
    
    if (self.directory.length) {
      NSMutableArray *comps = [self.directory pathComponents].mutableCopy;
      [comps removeLastObject];
      self.directory = [NSString pathWithComponents:comps];
      [self fetchFileList];
    } else {
      [self showNotAliveAlertView];
    }
    return;
  }
  
  NSArray *files = [files_str componentsSeparatedByString:@"\n"];
  NSMutableArray *file_props = @[].mutableCopy;
  [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *str = (NSString*)obj;
    NSArray *comps = [str componentsSeparatedByString:@","];
    if (comps.count >= 6) {
      FileProperty *prop = [[FileProperty alloc] init];
      prop.time = [comps[comps.count - 1] integerValue];
      prop.date = [comps[comps.count - 2] integerValue];
      prop.attribute = [comps[comps.count - 3] integerValue];
      prop.size = [comps[comps.count - 4] integerValue];
      prop.filename = [[comps subarrayWithRange:NSMakeRange(1, comps.count - 5)] componentsJoinedByString:@","];
      prop.directory = self.directory;
      [file_props addObject:prop];
    }
  }];
  
  [file_props sortUsingComparator:
   ^NSComparisonResult(id obj1, id obj2) {
     FileProperty *p1 = (FileProperty*)obj1;
     FileProperty *p2 = (FileProperty*)obj2;
     if (p1.date < p2.date)
       return 1;
     else if (p1.date > p2.date)
       return -1;
     else
       return (p2.time - p1.time);
   }];
  
  if (!self.isRootDirectory) {
    FileProperty *prop = [[FileProperty alloc] init];
    prop.filename = @"..";
    prop.directory = self.directory;
    [file_props insertObject:prop atIndex:0];
  }
  
  fileProperties = file_props;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [fileListTableView reloadData];
    [fileListTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                             atScrollPosition:UITableViewScrollPositionTop
                                     animated:NO];
  });
  
  currentDirectory = self.directory;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    self.flashAirIsAlive = YES;
  });
}


#pragma mark - User Interface

- (IBAction)getListButtonPressed:(id)sender {
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    [self fetchFileList];
  });
}

- (IBAction)newFileButtonPressed:(id)sender {
  UIAlertView *dlg =
  [[UIAlertView alloc]
   initWithTitle:@"Filename."
   message:@"Input a new filename."
   delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
  dlg.tag = NewFileAlertViewTag;
  [dlg setAlertViewStyle:UIAlertViewStylePlainTextInput];
  UITextField *tf = [dlg textFieldAtIndex:0];
  tf.returnKeyType = UIReturnKeyDone;
  tf.keyboardType = UIKeyboardTypeASCIICapable;
  [dlg show];
}

- (void)showNotAliveAlertView {
  UIAlertView *dlg = [[UIAlertView alloc]
                      initWithTitle:@"Connection Error"
                      message:@"Cannot connect to a FlashAir."
                      delegate:self
                      cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
  dlg.tag = NotAliveAlertViewTag;
  [dlg show];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return fileProperties.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileListCell"
                                                          forIndexPath:indexPath];

  FileProperty *prop = fileProperties[indexPath.row];
  cell.textLabel.text = [prop.filename stringByAppendingString:
                         (prop.isDirectory ? @"/" : @"")];
 
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  FileProperty *prop = fileProperties[indexPath.row];
  selectedFilename = prop.filename;
  if ([prop.filename isEqualToString:@".."]) {
    NSMutableArray *comp = [self.directory pathComponents].mutableCopy;
    [comp removeLastObject];
    self.directory = [NSString pathWithComponents:comp];
    [self fetchFileList];
  } else if (prop.isDirectory) {
    self.directory = [self.directory stringByAppendingPathComponent:prop.filename];
    [self fetchFileList];
  } else {
    [self openTextViewController];
  }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (alertView.tag == NewFileAlertViewTag) {
    if (buttonIndex == 1) {
      NSMutableString *fn = [[alertView textFieldAtIndex:0] text].mutableCopy;
      // todo: 必要に応じて.txtを付けるなど
      selectedFilename = fn;
      isNewFile = YES;
      [self openTextViewController];
    }
  } else if (alertView.tag == NotAliveAlertViewTag) {
    [self performSelector:@selector(fetchFileList)
               withObject:nil
               afterDelay:5];
  }
}

@end
