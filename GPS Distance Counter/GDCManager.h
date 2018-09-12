//
//  GDCManager.h
//  GPS Distance Counter
//
//  Created by Martin1248 on 27.08.18.
//  Copyright © 2018 Martin1248. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


static NSString *const GDCNewDataNotification = @"GDCNewDataNotification";


@interface GDCManager : NSObject <CLLocationManagerDelegate>

+ (GDCManager *)sharedManager;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property BOOL distanceCountInProgress;
@property (strong, nonatomic) CLLocation *lastLocation;
@property (nonatomic) CLLocationDistance currentDistance;
@property (nonatomic) CLLocationAccuracy accuracy;
@property (strong, nonatomic) NSDate *startDate;

- (void)startAllUpdates;
- (void)stopAllUpdates;
- (void)startCount;
- (void)stopCount;
- (NSTimeInterval)currentDuration;

@end
