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
    self.trackingEnabled = YES;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
}

- (void)stopAllUpdates {
    self.trackingEnabled = NO;
    [self.locationManager stopUpdatingLocation];
}

- (void)startCount {
    if(self.distanceCountInProgress) {
        return;
    }

    self.distanceCountInProgress = YES;
    self.startDate = [NSDate date];
}

- (void)stopCount {
    if(!self.distanceCountInProgress) {
        return;
    }
                                                 
    [self myLog2:[NSString stringWithFormat:@"\nDistance count result is\n%d meters\n\n Duration is\n %d seconds\n\n The best accuracy was\n %d meters\n\n The worst accuracy was\n%d meters\n\nCalculation is based on\n%d GPS locations", (int)round(self.currentDistance), (int)round([self currentDuration]), (int)round(self.minAccuracy), (int)round(self.maxAccuracy), self.locationUpdateCount]];
    
    //[self myLog:[NSString stringWithFormat:@"%dm(%dm) +/- %dm/%dm for %d sec. (%d loc.)", (int)round(self.currentDistance), (int)round(self.currentDistanceSimple), (int)round(self.minAccuracy), (int)round(self.maxAccuracy), (int)round([self currentDuration]), self.locationUpdateCount]];

    //[self myLog:[NSString stringWithFormat:@"%dm/%dm %dsec %dkm/h +/-%dm(max%d) %dUpd.", (int)round(self.currentDistanceSimple), (int)round(self.currentDistance), (int)round([self currentDuration]), (int)round(self.lastLocation.speed*3.6), (int)round(self.lastLocation.horizontalAccuracy), (int)round(self.maxAccuracy), self.locationUpdateCount]];

    self.distanceCountInProgress = NO;
    self.currentDistance = 0;
    self.currentDistanceSimple = 0;
    self.startLocation = nil;
    self.lastLocation = nil;
    self.startDate = nil;
    self.minAccuracy = 0;
    self.maxAccuracy = 0;
    self.locationUpdateCount = 0;
    self.startDate = nil;
}

- (void)updateCurrentDistanceAndLastLocationWithLocation: (CLLocation*) currentLocation{
    if(!self.distanceCountInProgress) {
        return;
    }

    if(!self.startLocation) {
        self.startLocation = currentLocation;
        self.lastLocation = currentLocation;
    } else {
        CLLocationDistance d = [self.lastLocation distanceFromLocation:currentLocation];
        self.currentDistance = self.currentDistance + d;
        self.currentDistanceSimple = [self.startLocation distanceFromLocation:currentLocation];
        self.lastLocation = currentLocation;
        if(currentLocation.horizontalAccuracy > self.maxAccuracy){
            self.maxAccuracy = currentLocation.horizontalAccuracy;
        }
        if(currentLocation.horizontalAccuracy < self.minAccuracy){
            self.minAccuracy = currentLocation.horizontalAccuracy;
        }
    }
}

- (NSTimeInterval)currentDuration {
    if(!self.distanceCountInProgress) {
        return -1;
    }

    NSDate *startDate = self.startDate;
    return [startDate timeIntervalSinceNow] * -1.0;
}


- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        //_locationManager.distanceFilter = 1;
        //_locationManager.allowsBackgroundLocationUpdates = YES;
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        //_locationManager.activityType = CLActivityTypeOther;
        [self myLog:@"Initialized GPS"];
    }

    return _locationManager;
}


#pragma mark - CLLocationManager Delegate Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *current = (CLLocation *)locations[locations.count-1];

    self.locationUpdateCount = self.locationUpdateCount + 1;

    if(current.horizontalAccuracy > 100) { // only if the location is accurate enough
        [self myLog:@"Error: GPS is NOT accurate enough (+/- 100 meters)!!!"];
    }

    [self updateCurrentDistanceAndLastLocationWithLocation:current];
    [[NSNotificationCenter defaultCenter] postNotificationName:GDCNewDataNotification object:self];
    // NSLog(@"GDC-Info: Received %d locations", (int)locations.count);
    // NSLog(@"GDC-Info: %@", locations);
    //[self myLog:@"!! Received locations"];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(nonnull NSError *)error {
    [self myLog:error.localizedFailureReason];
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    [self myLog:@"Error: Location updates paused"];
    
    // If a distance count was in progress, stop it now
    if(self.distanceCountInProgress) {
        [self myLog:@"Stopping distance count because location manager paused location updates"];
        self.distanceCountInProgress = NO;
    }
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    [self myLog:@"Location updates resumed"];
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(nullable NSError *)error {
    [self myLog:@"Deferred updates finished"];
}



- (void)myLog:(NSString *)message
{
    //if(!self.quickLog){
    //    self.quickLog = [NSMutableString new];
    //}
    NSLog(@"GDC: %@ at %@",message, self.lastLocation);
    //[self.quickLog appendString:message]; // Uhhhh
    //[self.quickLog appendString:@"\n"];
}

- (void)myLog2:(NSString *)message
{
    NSLog(@"GDC: %@ at %@",message, self.lastLocation);
    self.quickLog = message;
}


+ (NSString *)iso8601DateStringFromDate:(NSDate *)date {
    struct tm *timeinfo;
    char buffer[80];

    time_t rawtime = (time_t)[date timeIntervalSince1970];
    timeinfo = gmtime(&rawtime);

    strftime(buffer, 80, "%Y-%m-%dT%H:%M:%SZ", timeinfo);

    return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
}


@end
