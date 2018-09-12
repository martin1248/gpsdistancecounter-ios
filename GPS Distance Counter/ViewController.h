//
//  ViewController.h
//  GPS Distance Counter
//
//  Created by Martin1248 on 24.08.18.
//  Copyright © 2018 Martin1248. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *startStopButton;
- (IBAction)startStopWasTapped:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
@property (strong, nonatomic) IBOutlet UILabel *accuracyLabel;
@property (strong, nonatomic) IBOutlet UITextField *distanceTextBox;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;



@end

