// --------------------------------------------------------------------------------
// The MIT License (MIT)
//
// Copyright (c) 2014 Shiny Development
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// --------------------------------------------------------------------------------

#import "ViewController.h"
#import "SDStatusBarManager.h"

@interface ViewController () 
@property (strong, nonatomic) IBOutlet UIButton *overrideButton;
@property (strong, nonatomic) IBOutlet UITextField *timeStringTextField;
@property (strong, nonatomic) IBOutlet UITextField *carrierNameTextField;
@property (strong, nonatomic) IBOutlet UISegmentedControl *bluetoothSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *networkSegmentedControl;
@property (strong, nonatomic) UITextField *selectedTextField;
@end

@implementation ViewController

#pragma mark View lifecycle
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // auto adjust button text font size.
  self.overrideButton.titleLabel.adjustsFontSizeToFitWidth = YES;
  self.overrideButton.titleLabel.minimumScaleFactor = 0.5;

  [self setOverrideButtonText];
  [self setBluetoothSegementedControlSelectedSegment];
  [self setNetworkSegementedControlSelectedSegment];
  [self setCarrierNameTextFieldText];
  [self setTimeStringTextFieldText];
  
  // add tap gesture to self.view, tap view to dimiss keyboard.
  UITapGestureRecognizer *tapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
  [self.view addGestureRecognizer:tapView];
  
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
  [nc addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
  
  NSDictionary *environment = [[NSProcessInfo processInfo] environment];
  if ([environment[@"SIMULATOR_STATUS_MAGIC_OVERRIDES"] isEqualToString:@"ENABLE"]) {
    [[SDStatusBarManager sharedInstance] enableOverrides];
    [self setOverrideButtonText];
  }
  if ([environment[@"SIMULATOR_STATUS_MAGIC_OVERRIDES"] isEqualToString:@"DISABLE"]) {
    [[SDStatusBarManager sharedInstance] disableOverrides];
    [self setOverrideButtonText];
  }}

#pragma mark Actions

- (IBAction)randomTimeButtonTapped:(UIButton *)sender {
  int hour = arc4random_uniform(3) + 1;
  int min = arc4random_uniform(60);
  NSString *formatString = @"%d:%d AM";
  if (min < 10) {
    formatString = @"%d:0%d AM";
  }
  NSString *text = [NSString stringWithFormat: formatString, hour, min];
  [self timeStringTextField].text = text;
  [SDStatusBarManager sharedInstance].timeString = text;
}

- (IBAction)overrideButtonTapped:(UIButton *)sender
{
  if ([SDStatusBarManager sharedInstance].usingOverrides) {
    [[SDStatusBarManager sharedInstance] disableOverrides];
    [self setOverrideButtonText];
  } else {
    [[SDStatusBarManager sharedInstance] enableOverrides];
    [self setOverrideButtonText];
  }
}

- (IBAction)carrierNameTextFieldEditingChanged:(UITextField *)textField
{
  [SDStatusBarManager sharedInstance].carrierName = textField.text;
}

- (IBAction)timeStringTextFieldEditingChanged:(UITextField *)textField
{
  [SDStatusBarManager sharedInstance].timeString = textField.text;
}

- (IBAction)bluetoothStatusChanged:(UISegmentedControl *)sender
{
  // Note: The order of the segments should match the definition of SDStatusBarManagerBluetoothState
  [[SDStatusBarManager sharedInstance] setBluetoothState:sender.selectedSegmentIndex];
}

- (IBAction)networkTypeChanged:(UISegmentedControl *)sender
{
  // Note: The order of the segments should match the definition of SDStatusBarManagerNetworkType
  [[SDStatusBarManager sharedInstance] setNetworkType:sender.selectedSegmentIndex];
}

#pragma mark Text field delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
  self.selectedTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  self.selectedTextField = NULL;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  return YES;
}

#pragma mark UI helpers
- (void)setOverrideButtonText
{
  if ([SDStatusBarManager sharedInstance].usingOverrides) {
    [self.overrideButton setTitle:NSLocalizedString(@"Restore Default Status Bar", @"Restore Default Status Bar")  forState:UIControlStateNormal];
  } else {
    [self.overrideButton setTitle:NSLocalizedString(@"Apply Clean Status Bar Overrides", "Apply Clean Status Bar Overrides") forState:UIControlStateNormal];
  }
}

- (void)setBluetoothSegementedControlSelectedSegment
{
  // Note: The order of the segments should match the definition of SDStatusBarManagerBluetoothState
  self.bluetoothSegmentedControl.selectedSegmentIndex = [SDStatusBarManager sharedInstance].bluetoothState;
}

- (void)setNetworkSegementedControlSelectedSegment
{
  // Note: The order of the segments should match the definition of SDStatusBarManagerNetworkType
  self.networkSegmentedControl.selectedSegmentIndex = [SDStatusBarManager sharedInstance].networkType;
}

- (void)setCarrierNameTextFieldText
{
  self.carrierNameTextField.placeholder = NSLocalizedString(@"Carrier", @"Carrier");
  self.carrierNameTextField.text = [SDStatusBarManager sharedInstance].carrierName;
}

- (void)setTimeStringTextFieldText
{
  self.timeStringTextField.text = [SDStatusBarManager sharedInstance].timeString;
}

#pragma mark User Interactions

- (void) viewTapped: (UITapGestureRecognizer *) gr {
  if (gr.state == UIGestureRecognizerStateEnded) {
    [self.view endEditing:YES];
  }
}

#pragma mark Event Observers

- (void) keyboardDidShow: (NSNotification *) notification {
  // ensure the view is loaded and showing on the top of the app window.
  if (!self.isViewLoaded || self.view.window == NULL) {
    NSLog(@"view is not visible");
    return;
  }
  
  if (self.selectedTextField) {
    CGRect adjustedFrame = self.selectedTextField.frame;
    UIView *parent = self.view;
    if (parent) {
      adjustedFrame = [self.view convertRect:self.selectedTextField.frame toView:parent];
    }
    
    CGFloat maxY = adjustedFrame.size.height + adjustedFrame.origin.y;
    
    NSValue *keyboardRectValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    
    if (keyboardRectValue == NULL) {
      return;
    }
    
    CGRect keyboardRect = keyboardRectValue.CGRectValue;
    
    // Set view origin back to zero.
    CGRect rect = self.view.frame;
    rect.origin.y = 0;
    self.view.frame = rect;
    
    CGFloat offset = maxY - keyboardRect.origin.y;
    
    if (offset < 0) {
      return;
    }
    
    rect.origin.y -= offset;
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
      self.view.frame = rect;
    } completion:NULL];
  }
}

- (void) keyboardDidHide: (NSNotification *) notification {
  // ensure the view is loaded and showing on the top of the app window.
  if (!self.isViewLoaded || self.view.window == NULL) {
    NSLog(@"view is not visible");
    return;
  }
  
  if (self.view.frame.origin.y < 0) {
    CGRect rect = self.view.frame;
    rect.origin.y = 0;
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
      self.view.frame = rect;
    } completion:NULL];
  }
}

#pragma mark Status bar settings
- (BOOL)prefersStatusBarHidden
{
  return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
  return UIStatusBarStyleDefault;
}

@end
