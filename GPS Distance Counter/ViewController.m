//
//  ViewController.m
//  GPS Distance Counter
//
//  Created by Martin1248 on 24.08.18.
//  Copyright © 2018 Martin1248. All rights reserved.
//

#import "ViewController.h"
#import "GDCManager.h"
#import <CoreLocation/CoreLocation.h>

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
    NSLog(@"GDC-Info: Initialized locationManager in viewDidLoad. %@",[GDCManager sharedManager].locationManager);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[GDCManager sharedManager] myLog:@"GDC-Error: didReceiveMemoryWarning"];
}


- (void)viewWillAppear:(BOOL)animated {
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
    if([GDCManager sharedManager].distanceCountInProgress) {
        [[GDCManager sharedManager] stopCount];
        [[GDCManager sharedManager] stopAllUpdates];
    } else {
        [[GDCManager sharedManager] startAllUpdates];
        [[GDCManager sharedManager] startCount];
    }
    [self updateDistanceCount];
}


- (void)updateDistanceCount {
    self.logLabel.text = [GDCManager sharedManager].quickLog; // Uhhhhhh
    if([GDCManager sharedManager].distanceCountInProgress) {
        [self.startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
        self.startStopButton.backgroundColor = [UIColor colorWithRed:252.f/255.f green:109.f/255.f blue:111.f/255.f alpha:1];
        self.durationLabel.text = [ViewController timeFormatted:[GDCManager sharedManager].currentDuration];
        double distance = [GDCManager sharedManager].currentDistance;
        double distanceSimple = [GDCManager sharedManager].currentDistanceSimple;
        NSString *format;
        if(distance >= 1000) {
            format = @"%0.0f";
        } else if(distance >= 100) {
            format = @"%0.1f";
        } else {
            format = @"%0.2f";
        }
        self.distanceLabel.text = [NSString stringWithFormat:format, distance];
        self.distanceLabelSimple.text = [NSString stringWithFormat:format, distanceSimple];
        self.accuracyLabel.text = [NSString stringWithFormat:@"+/- %d",(int)round([GDCManager sharedManager].lastLocation.horizontalAccuracy)];
        self.speedLabel.text = [NSString stringWithFormat:@"%d",(int)round([GDCManager sharedManager].lastLocation.speed*3.6)];
    } else {
        [self.startStopButton setTitle:@"Start" forState:UIControlStateNormal];
        self.startStopButton.backgroundColor = [UIColor colorWithRed:106.f/255.f green:212.f/255.f blue:150.f/255.f alpha:1];
        self.distanceLabel.text = @" ";
        self.distanceLabelSimple.text = @" ";
        self.durationLabel.text = @" ";
        self.accuracyLabel.text = @" ";
        self.speedLabel.text = @" ";
    }
}


#pragma mark -

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
