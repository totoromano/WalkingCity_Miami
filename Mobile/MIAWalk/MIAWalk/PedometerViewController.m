//
//  PedometerViewController.m
//  MIAWalk
//
//  Created by cromano on 3/7/15.
//  Copyright (c) 2015 MIAWalk. All rights reserved.
//

#import "PedometerViewController.h"
#import "SOMotionDetector.h"
#import <Parse/Parse.h>


@interface PedometerViewController ()<SOMotionDetectorDelegate>{
   
    NSDate *startingDate;
    int steps;
    int distances;
    NSOperationQueue *_stepQueue;
    BOOL moving;
    NSTimer *timer;
}
@property (weak, nonatomic) IBOutlet UIImageView *guy;
- (IBAction)finish:(id)sender;
@property CMPedometer *pedometer;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (nonatomic,strong) CMMotionActivityManager *motionActivityManager;
@property (weak, nonatomic) IBOutlet UILabel *stepsLabel;
- (IBAction)goBack:(UIButton *)sender;

@end

@implementation PedometerViewController

-(void)viewDidAppear:(BOOL)animated{
    [[SOMotionDetector sharedInstance] startDetection];
    //NSLog(@"HI\n");
    self.guy.alpha = 0.0f;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    startingDate = [NSDate dateWithTimeIntervalSinceNow:0];

    self.motionActivityManager=[[CMMotionActivityManager alloc]init];
    [self.motionActivityManager startActivityUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMMotionActivity *activity)
     {
//         self.stepsLabel.text = @"Got a core motion update";
//         NSLog(@"Current activity date is %f",activity.timestamp);
//         NSLog(@"Current activity confidence from a scale of 0 to 2 - 2 being best- is: %ld",activity.confidence);
//         NSLog(@"Current activity type is unknown: %i",activity.unknown);
//         NSLog(@"Current activity type is stationary: %i",activity.stationary);
//         NSLog(@"Current activity type is walking: %i",activity.walking);
//         NSLog(@"Current activity type is running: %i",activity.running);
//         NSLog(@"Current activity type is automotive: %i",activity.automotive);
         
//         self.textLabel.text = @"Got a core motion update";
         
     }];
    
    [SOMotionDetector sharedInstance].delegate = self;
    self.stepsLabel.text = @"";
    
 
}
- (void)motionDetector:(SOMotionDetector *)motionDetector motionTypeChanged:(SOMotionType)motionType
{
    NSString *type = @"";
    switch (motionType) {
        case MotionTypeNotMoving:
            type = @"Not moving";
            //[self stopCounting];
            break;
        case MotionTypeWalking:
            type = @"Walking";
            [self countSteps];
            NSLog(@"%d",steps);
            self.guy.alpha = 1.0f;
            break;
        case MotionTypeRunning:
            type = @"Running";
            break;
        case MotionTypeAutomotive:
            type = @"Automotive";
            break;
    }
    
    self.textLabel.text = type;
}

- (void)motionDetector:(SOMotionDetector *)motionDetector locationChanged:(CLLocation *)location
{
    
}

- (void)motionDetector:(SOMotionDetector *)motionDetector accelerationChanged:(CMAcceleration)acceleration
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)countSteps{
    steps ++;
    _pedometer = [[CMPedometer alloc]init];
    [_pedometer startPedometerUpdatesFromDate:startingDate withHandler:^(CMPedometerData *pedometerData, NSError *error) {
       // NSLog(@"%s", [[pedometerData description]UTF8String]);
//        self.textLabel.text = [self.textLabel.text stringByAppendingString:[NSString stringWithFormat:@" - %ld",(long)[pedometerData.numberOfSteps integerValue]]];
//        
    }];
    moving = YES;
    timer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                     target:self
                                   selector:@selector(getData)
                                   userInfo:nil
                                    repeats:YES];

   // NSLog(@"%d",steps);
}
-(void)getData{
    if(moving){
        [_pedometer queryPedometerDataFromDate:startingDate toDate:[NSDate dateWithTimeIntervalSinceNow:0] withHandler:^(CMPedometerData *pedometerData, NSError *error) {
            int stepsCompleted, distanceTraveled;
            if(!error){
                stepsCompleted = (int)[pedometerData.numberOfSteps integerValue];
                distanceTraveled = (int) [pedometerData.distance integerValue];
                //[self updateLabels:stepsCompleted withDistance:distanceTraveled];
                //NSLog(@"Done %d",stepsCompleted);
                steps = stepsCompleted;
                distances = distanceTraveled;
            }
        }];
    }else{
     //self.view.alpha = 1;
    }
   
}

-(void)stopCounting{
 //  __block int stepsCompleted, distanceTraveled;
    moving = NO;
    [timer invalidate];
    self.view.alpha = 0.2;
    //[self getData];
    self.stepsLabel.text = [NSString stringWithFormat:@"%d steps completed",steps];
    self.view.alpha = 1;
    PFObject *testTrip = [PFObject objectWithClassName:@"Trip"];
    NSString *stepsInString = [NSString stringWithFormat:@"%d",steps];
    testTrip[@"StepsCompleted"] = [NSNumber numberWithInt:steps];
    testTrip[@"distanceTraveled"] = [NSNumber numberWithFloat:distances*0.00062137];
    testTrip[@"user"] = @"tester";
    [testTrip saveInBackground];
}

-(void)updateLabels:(int)numberOfSteps withDistance:(int)distance{
    self.stepsLabel.text = [NSString stringWithFormat:@"%d steps completed",numberOfSteps];
}

- (IBAction)goBack:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
    
    [[SOMotionDetector sharedInstance] stopDetection];
}
- (IBAction)finish:(id)sender {
    NSLog(@"Finish Pressed");
    [self stopCounting];
    [[SOMotionDetector sharedInstance] stopDetection];
}
@end
