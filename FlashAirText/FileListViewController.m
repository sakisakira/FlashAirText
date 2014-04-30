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

//NSString *BaseURLString = @"http://flashair/";
NSString *BaseURLString = @"http://192.168.0.1/";
NSURL *BaseURL = nil;
NSString *CurrentDirectoryKey = @"CurrentDirectory";

@interface FileListViewController ()
<UITableViewDelegate, UITableViewDataSource,
 UIAlertViewDelegate>

@end

@implementation FileListViewController {
  __weak IBOutlet UILabel *directoryNameLabel;
  __weak IBOutlet UITableView *fileListTableView;
  
  NSArray *fileProperties;
  NSString *selectedFilename;
  
  NSString *currentDirectory;
}

@dynamic directory, isRootDirectory;

- (NSString*)directory {
  return directoryNameLabel.text;
}

- (void)setDirectory:(NSString *)directory_ {
  directoryNameLabel.text = directory_;
}

- (BOOL)isRootDirectory {
  return ([self.directory length] == 0);
}

- (void)viewDidLoad {
  [super viewDidLoad];

  BaseURL = [NSURL URLWithString:BaseURLString];

}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
  currentDirectory = [defs stringForKey:CurrentDirectoryKey];
  if (currentDirectory)
    self.directory = currentDirectory;
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
  
  [self getListButtonPressed:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  TextViewController *vc = [segue destinationViewController];
  vc.filePath = [self.directory stringByAppendingPathComponent:selectedFilename];
  selectedFilename = nil;
}

#pragma mark - Communication

- (void)fetchFileList {
  NSURL *cmd_url =
  [NSURL URLWithString:
   [[BaseURLString stringByAppendingString:@"command.cgi?op=100&DIR=/"]
    stringByAppendingString:self.directory]];
  NSError *error = nil;
  NSString *files_str =
  [NSString stringWithContentsOfURL:cmd_url
                           encoding:NSShiftJISStringEncoding
                              error:&error];
  if (error) {
    NSLog(@"get file list error %@", error);
    currentDirectory = nil;
    
    if (self.directory.length) {
      NSMutableArray *comps = [self.directory pathComponents].mutableCopy;
      [comps removeLastObject];
      self.directory = [NSString pathWithComponents:comps];
      [self fetchFileList];
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
  [fileListTableView reloadData];
  [fileListTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                           atScrollPosition:UITableViewScrollPositionTop
                                   animated:NO];
  
  currentDirectory = self.directory;
}


#pragma mark - User Interface

- (IBAction)getListButtonPressed:(id)sender {
  [self fetchFileList];
}

- (IBAction)newFileButtonPressed:(id)sender {
  UIAlertView *dlg =
  [[UIAlertView alloc]
   initWithTitle:@"Filename."
   message:@"Input a new filename."
   delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
  [dlg setAlertViewStyle:UIAlertViewStylePlainTextInput];
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
  cell.textLabel.text = [prop.filename stringByAppendingString:prop.isDirectory ? @"/" : @""];
 
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  FileProperty *prop = fileProperties[indexPath.row];
  selectedFilename = prop.filename;
  if ([prop.filename isEqualToString:@".."]) {
    NSMutableArray *comp = [self.directory pathComponents].mutableCopy;
    [comp removeLastObject];
    self.directory = [comp componentsJoinedByString:@"/"];
    [self fetchFileList];
  } else if (prop.isDirectory) {
    self.directory = [self.directory stringByAppendingPathComponent:prop.filename];
    [self fetchFileList];
  } else {
    [self performSegueWithIdentifier:@"TextViewController" sender:nil];
  }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 1) {
    selectedFilename = [[alertView textFieldAtIndex:0] text];
    [self performSegueWithIdentifier:@"TextViewController" sender:nil];
  }
}

@end
