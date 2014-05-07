//
//  CBCentralManagerViewController.h
//  SubContext
//
//  Created by Mason Schoolfield and Robert Sandoval on 4/27/14.
//  Copyright (c) 2014 UT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "SERVICES.h"

@interface CBSubContext : UIViewController < CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UITextView *textview;

@property (weak, nonatomic) IBOutlet UISegmentedControl *bleButtonSwitch;

@property (weak, nonatomic) IBOutlet UITextField *stringContext;
@property (weak, nonatomic) IBOutlet UIButton *clearContext;
@property (strong, nonatomic) CBCentralManager *centralManager;

//@property (strong, nonatomic) NSMutableData *data;
@property (nonatomic, readwrite) UIAlertView *alert;
@property (weak, nonatomic) IBOutlet UIButton *transferButton;


@property (strong, nonatomic) CBPeripheralManager *peripheralManager;

@property (strong, nonatomic) CBMutableCharacteristic *sendPostCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *receivePostCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *nameReadCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *contextReadCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic *receiveContextReqCharacteristic;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSMutableDictionary *incomingDataToCentral;

// An array to house all of our fetched MessagePost objects
@property (strong, nonatomic) NSArray *messageArray;

@property (weak, nonatomic) IBOutlet UITextView *textStatus;


@end
