//
//  GDCManager.m
//  GPS Distance Counter
//
//  Created by Martin1248 on 27.08.18.
//  Copyright © 2018 Martin1248. All rights reserved.
//

#import "GDCManager.h"

@implementation GDCManager


+ (GDCManager *)sharedManager {
    static GDCManager *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}


- (void)startAllUpdates {
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
}

- (void)stopAllUpdates {
    [self.locationManager stopUpdatingLocation];
}

- (void)startCount {
    self.distanceCountInProgress = YES;
    self.startDate = [NSDate date];
}

- (void)stopCount {
    self.distanceCountInProgress = NO;
    self.startDate = nil;
    self.currentDistance = 0;
    self.lastLocation = nil;
    self.accuracy = 0;
}

- (void)updateCurrentDistanceAndLastLocationWithLocation: (CLLocation*) currentLocation {
    CLLocationDistance d = [self.lastLocation distanceFromLocation:currentLocation];
    self.currentDistance = self.currentDistance + d;
    self.lastLocation = currentLocation;
    if(currentLocation.horizontalAccuracy > self.accuracy){
        self.accuracy = currentLocation.horizontalAccuracy;
    }
    if(currentLocation.verticalAccuracy > self.accuracy){
        self.accuracy = currentLocation.verticalAccuracy;
    }
}

- (NSTimeInterval)currentDuration {
    NSDate *startDate = self.startDate;
    return [startDate timeIntervalSinceNow] * -1.0;
}

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _locationManager.pausesLocationUpdatesAutomatically = NO;
    }

    return _locationManager;
}

#pragma mark - CLLocationManager Delegate Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if(!self.distanceCountInProgress) {
        return;
    }
    
    CLLocation *current = (CLLocation *)locations[locations.count-1];
    
    [self updateCurrentDistanceAndLastLocationWithLocation:current];
    [[NSNotificationCenter defaultCenter] postNotificationName:GDCNewDataNotification object:self];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(nonnull NSError *)error {
    NSLog(@"%@", error.localizedFailureReason);
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"Error: Location updates paused");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"Location updates resumed");
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(nullable NSError *)error {
    NSLog(@"Deferred updates finished");
}

@end
