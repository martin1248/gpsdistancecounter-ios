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


@interface ViewController ()

@property (strong, nonatomic) NSTimer *viewRefreshTimer;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self.startStopButton.layer setCornerRadius:4.0];
    [self setNeedsStatusBarAppearanceUpdate];
    
    //The next task is to configure the instance of the CLLocationManager class and to make sure that the application requests permission from the user to track the current location of the device. Since this needs to occur when the view loads, an ideal location is in the view controller’s viewDidLoad method in the ViewController.m file:
    NSLog(@"Initialized locationManager %@",[GDCManager sharedManager].locationManager);
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

@end
