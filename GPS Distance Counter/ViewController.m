//
//  ViewController.m
//  GPS Distance Counter
//
//  Created by Martin1248 on 24.08.18.
//  Copyright © 2018 Martin1248. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"
#import "GDCManager.h"

static NSString *const userDefaultsDistance = @"GDC-Distance";
static NSString *const userDefaultsDarkMode = @"GDC-DarkMode";

@interface ViewController ()

@property (strong, nonatomic) NSTimer *viewRefreshTimer;

@end


@implementation ViewController{
    NSArray *trainLengths;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self.startStopButton.layer setCornerRadius:4.0];
    [self setNeedsStatusBarAppearanceUpdate];
    
    UITapGestureRecognizer* tapBackground = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    [tapBackground setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:tapBackground];
    
    //The next task is to configure the instance of the CLLocationManager class and to make sure that the application requests permission from the user to track the current location of the device. Since this needs to occur when the view loads, an ideal location is in the view controller’s viewDidLoad method in the ViewController.m file:
    NSLog(@"Initialized locationManager %@",[GDCManager sharedManager].locationManager);
    
    [self addGestureRecognizers];
    
    [self applyDarkMode:[self isDarkMode]];
    
    
    trainLengths = @[@"100", @"150", @"200", @"250", @"300", @"350", @"400", @"450", @"500", @"550", @"600", @"650", @"700", @"750" , @"800" , @"850", @"900", @"950", @"1000", @"1050", @"1100", @"1150", @"1200", @"1250", @"1300", @"1350", @"1400"];
    UIPickerView *pickerView = [[UIPickerView alloc] init];
    pickerView.delegate = self;
    self.distanceTextBox.inputView = pickerView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"didReceiveMemoryWarning");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateDistanceCount];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDistanceCount)
                                                 name:GDCNewDataNotification
                                               object:nil];

    self.viewRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                             target:self
                                                           selector:@selector(updateDistanceCount)
                                                           userInfo:nil
                                                            repeats:YES];
    
    [self loadConfig];
}

- (void)loadConfig {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    long distance = [defaults integerForKey:userDefaultsDistance];
    if (distance != 0) {
        self.distanceTextBox.text = [NSString stringWithFormat:@"%ld", distance];
    }
}

- (void)saveConfig {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[self.distanceTextBox.text integerValue] forKey:userDefaultsDistance];
    [defaults synchronize];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.viewRefreshTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillUnload {
    [self.viewRefreshTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)startStopWasTapped:(id)sender {
    if([self.distanceTextBox.text integerValue] == 0) {
        return; // Do nothing if a)a zero, b) no number at all or c) a text was entered
    }
    if([GDCManager sharedManager].distanceCountInProgress) {
        [[GDCManager sharedManager] stopCount];
        self.distanceTextBox.userInteractionEnabled = YES;
    } else {
        self.distanceTextBox.userInteractionEnabled = NO;
        [self saveConfig];
        [[GDCManager sharedManager] startCount];
    }
    [self updateDistanceCount];
}

- (void)updateDistanceCount {
    if([GDCManager sharedManager].distanceCountInProgress) {
        double distance = [self.distanceTextBox.text integerValue] - [GDCManager sharedManager].currentDistance;
        
        if(distance <= 0) {
            distance = 0;
            [[GDCManager sharedManager] stopCount];
            self.distanceTextBox.userInteractionEnabled = YES;
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            AudioServicesPlaySystemSound(1010);
        }
        
        [self.startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
        self.startStopButton.backgroundColor = [UIColor colorWithRed:252.f/255.f green:109.f/255.f blue:111.f/255.f alpha:1];
        
        self.distanceLabel.text = [NSString stringWithFormat:@"%0.0f", distance];
        self.durationLabel.text = [ViewController timeFormatted:[GDCManager sharedManager].currentDuration];
        self.accuracyLabel.text = [NSString stringWithFormat:@"%0.0f", [GDCManager sharedManager].accuracy];
        
        float fractionalProgress = ([self.distanceTextBox.text integerValue]-distance)/[self.distanceTextBox.text integerValue];
        self.progressView.progress = fractionalProgress;
    } else {
        [self.startStopButton setTitle:@"Start" forState:UIControlStateNormal];
        self.startStopButton.backgroundColor = [UIColor colorWithRed:106.f/255.f green:212.f/255.f blue:150.f/255.f alpha:1];
        self.distanceLabel.text = @" ";
        self.durationLabel.text = @" ";
        self.accuracyLabel.text = @" ";
        self.progressView.progress = 0;
    }
}

-(void) dismissKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

+ (NSString *)timeFormatted:(int)totalSeconds {
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;

    if(hours == 0) {
        return [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
    } else {
        return [NSString stringWithFormat:@"%d:%02d", hours, minutes];
    }
}

- (void) addGestureRecognizers {
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panRecognized:)];
    [self.view addGestureRecognizer:panRecognizer];
}

- (void) panRecognized:(UIPanGestureRecognizer*) recognizer {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [GDCManager sharedManager].locationsLog;
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Information"
                                                                   message:@"Ihre GPS Daten sind nun im Zwischenspeicher. Diese können Sie nun in andere Apps einfügen."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)lightDarkModeButtonPressed:(id)sender {
    BOOL isDarkMode = [self isDarkMode];
    isDarkMode = !isDarkMode;
    [self setDarkMode:isDarkMode];
    
    [self applyDarkMode:isDarkMode];
}

- (BOOL)isDarkMode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:userDefaultsDarkMode];
}

- (void)setDarkMode:(BOOL) isDarkMode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:isDarkMode forKey:userDefaultsDarkMode];
    [defaults synchronize];
}

- (void) applyDarkMode:(BOOL) isDarkMode {
    UIColor *background;
    UIColor *box;
    UIColor *textColor;
    if (isDarkMode) {
        [self.switchLightDarkModeButton setTitle:@"Light mode" forState:UIControlStateNormal];
        background = UIColor.blackColor;
        box = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
        textColor = UIColor.whiteColor;
    } else {
        [self.switchLightDarkModeButton setTitle:@"Dark mode" forState:UIControlStateNormal];
        background = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
        box = UIColor.whiteColor;
        textColor = UIColor.blackColor;
    }
    self.rootView.backgroundColor = background;
    self.dataView.backgroundColor = box;
    self.firstHiddenLabel.textColor = background;
    self.firstLabel.textColor = textColor;
    self.distanceTextBox.backgroundColor = box;
    self.distanceTextBox.textColor = textColor;
    self.secondLabel.textColor = textColor;
    self.secondHiddenLabel.textColor = background;
    
    self.labelA.textColor = textColor;
    self.distanceLabel.textColor = textColor;
    self.labelB.textColor = textColor;
    self.labelC.textColor = textColor;
    self.durationLabel.textColor = textColor;
    self.labelD.textColor = textColor;
    self.labelE.textColor = textColor;
    self.accuracyLabel.textColor = textColor;
    self.labelF.textColor = textColor;
}

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return trainLengths.count;
}

- (NSInteger)numberOfComponents:(nonnull UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)thePickerView
             titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return trainLengths[row];
}

- (void)pickerView:(UIPickerView *)thePickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
    self.distanceTextBox.text = trainLengths[row];
}

@end
