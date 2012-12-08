//
//  ConsoleViewController.m
//  Ping
//
//  Created by Yatin Sarbalia on 08/12/12.
//  Copyright (c) 2012 Yatin Sarbalia. All rights reserved.
//

#import "ConsoleViewController.h"
#import "PingController.h"

#define BUTTONTEXT_START @"START"
#define BUTTONTEXT_STOP @"STOP"

#define TEXT_FIELD_PADDING_TOP 20
#define TEXT_FIELD_PADDING_LEFT 20
#define TEXT_FIELD_PADDING_BOTTOM 20
#define TEXT_FIELD_SIZE_HEIGHT 30
#define TEXT_FIELD_FONT @"HelveticaNeue"
#define TEXT_FIELD_PLACEHOLDER_TEXT @"Type Hostname"
#define TEXT_FIELD_COLOR [UIColor blackColor]
#define TEXT_FIELD_FONT_SIZE 14

#define BUTTON_PADDING_TOP TEXT_FIELD_PADDING_TOP
#define BUTTON_SIZE_WIDTH 60
#define BUTTON_SIZE_HEIGHT TEXT_FIELD_SIZE_HEIGHT
#define PADDING_BW_BUTTON_AND_TEXT_FIELD 20
#define BUTTON_PADDING_RIGHT 20

#define CONSOLE_LOGS_PADDING_TOP (TEXT_FIELD_PADDING_TOP + TEXT_FIELD_PADDING_BOTTOM + TEXT_FIELD_SIZE_HEIGHT)
#define CONSOLE_LOGS_PADDING_BOTTOM 20
#define CONSOLE_LOGS_PADDING_SIDE 20

@interface ConsoleViewController () <PingControllerDelegate>

@property (nonatomic, retain) UITextField *hostNameField;
@property (nonatomic, retain) UITextView *consoleLogsView;
@property (nonatomic, retain) UIButton *controlButton;
@property (nonatomic, retain) PingController *pingController;

@end

@implementation ConsoleViewController

@synthesize hostNameField = hostNameField_;
@synthesize consoleLogsView = consoleLogsView_;
@synthesize controlButton = controlButton_;
@synthesize pingController = pingController_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
    self.title = @"Ping";
  }
  return self;
}

- (void)dealloc {
  self.hostNameField = nil;
  self.consoleLogsView = nil;
  self.controlButton = nil;
  [super dealloc];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor lightGrayColor];
  
  UITextField *textField = self.hostNameField = [[[UITextField alloc] init] autorelease];
  textField.frame = CGRectMake(TEXT_FIELD_PADDING_LEFT, TEXT_FIELD_PADDING_TOP, self.view.frame.size.width - (TEXT_FIELD_PADDING_LEFT + PADDING_BW_BUTTON_AND_TEXT_FIELD + BUTTON_SIZE_WIDTH + BUTTON_PADDING_RIGHT), TEXT_FIELD_SIZE_HEIGHT);
  textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  textField.backgroundColor = [UIColor whiteColor];
  textField.placeholder = TEXT_FIELD_PLACEHOLDER_TEXT;
  textField.font = [UIFont fontWithName:TEXT_FIELD_FONT size:TEXT_FIELD_FONT_SIZE];
  textField.textColor = TEXT_FIELD_COLOR;
  textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  [self.view addSubview:textField];
  
  UITextView *textView = self.consoleLogsView = [[[UITextView alloc] init] autorelease];
  textView.frame = CGRectMake(CONSOLE_LOGS_PADDING_SIDE, CONSOLE_LOGS_PADDING_TOP, self.view.frame.size.width - (2 * CONSOLE_LOGS_PADDING_SIDE), self.view.frame.size.height - CONSOLE_LOGS_PADDING_TOP - CONSOLE_LOGS_PADDING_BOTTOM);
  textView.editable = NO;
  textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  textView.backgroundColor = [UIColor whiteColor];
  [self.view addSubview:textView];
  
  UIButton *button = self.controlButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  button.frame = CGRectMake(textField.frame.origin.x + textField.frame.size.width + PADDING_BW_BUTTON_AND_TEXT_FIELD, BUTTON_PADDING_TOP, BUTTON_SIZE_WIDTH, BUTTON_SIZE_HEIGHT);
  button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
  [button setTitle:BUTTONTEXT_START forState:UIControlStateNormal];
  [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:button];
}

- (void)viewDidUnload {
  [super viewDidUnload];
  self.hostNameField = nil;
  self.consoleLogsView = nil;
  self.controlButton = nil;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)buttonTapped:(UIButton *)button {
  if ([button.titleLabel.text isEqualToString:BUTTONTEXT_START]) {
    [button setTitle:BUTTONTEXT_STOP forState:UIControlStateNormal];
    [self.hostNameField resignFirstResponder];
    [self startPinging];
  } else {
    [button setTitle:BUTTONTEXT_START forState:UIControlStateNormal];
    [self stopPinging];
  }
}

- (void)startPinging {
  self.consoleLogsView.text = @"";
  if ((self.hostNameField.text == nil) || [self.hostNameField.text isEqual:@""]) {
    [self appendTextToLogs:@"Error: Hostname not given"];
  } else {
    [self appendTextToLogs:@"Start pinging ..."];
    self.pingController = [[[PingController alloc] init] autorelease];
    self.pingController.delegate = self;
    [self.pingController runWithHostName:self.hostNameField.text];
  }
}

- (void)stopPinging {
  [self appendTextToLogs:@"Stop pinging ..."];
  self.pingController.delegate = nil;
  self.pingController = nil;
}

- (void)pingController:(PingController *)pingController addLog:(NSString *)log {
  [self appendTextToLogs:log];
}

- (void)appendTextToLogs:(NSString *)text {
  self.consoleLogsView.text = [NSString stringWithFormat:@"%@\n%@", self.consoleLogsView.text, text];
}


@end
