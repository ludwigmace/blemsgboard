//
//  CBCentralManagerViewController.m
//  SubContext
//
//  Created by Mason Schoolfield and Robert Sandoval on 4/27/14.
//  Copyright (c) 2014 UT. All rights reserved.
//

#import "CBSubContext.h"
#import "AppDelegate.h"
#import "MessagePost.h"
#import "DataToSend.h"
#import <QuartzCore/QuartzCore.h>


@implementation CBSubContext

@synthesize messageArray;

NSString *localAuthor;

NSString *msgContext;
NSInteger contextCounter;

NSInteger localContextTimeOffset;
NSInteger remoteContextTimeOffset;

NSString *currentRemoteContextString;
NSString *currentRemotePartner;

NSMutableArray *msgsToSend;
NSMutableArray *periphsDiscovered;
NSMutableArray *periphs;

CBCharacteristic *nameChar;

NSInteger periphNotFoundCount;
NSInteger periphNoActivityCount;

NSTimer *t;
NSTimer *t2;

BOOL isCentral;

// Initializes the view
// Starts CentralManager
// Creates the Post button and calls actionDoPost when selected


- (void)viewDidLoad {
    
    periphNotFoundCount = 0;
    periphNoActivityCount = 0;
    
    
    periphsDiscovered = [[NSMutableArray alloc] init];
    
    _incomingDataToCentral = [[NSMutableDictionary alloc] init];
                              
    [super viewDidLoad];

    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    msgsToSend = [[NSMutableArray alloc] init];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    //To make the border look very close to a UITextField
    [_textStatus.layer setBorderColor:[[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor]];
    [_textStatus.layer setBorderWidth:2.0];
    
    //The rounded corner part, where you specify your view's corner radius:
    _textStatus.layer.cornerRadius = 5;
    _textStatus.clipsToBounds = YES;
    
    //To make the border look very close to a UITextField
    [_textview.layer setBorderColor:[[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor]];
    [_textview.layer setBorderWidth:2.0];
    
    //The rounded corner part, where you specify your view's corner radius:
    _textview.layer.cornerRadius = 5;
    _textview.clipsToBounds = YES;
    
    UIBarButtonItem *postButton = [[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStylePlain target:self action:@selector(actionDoPost:)];
    self.navigationItem.rightBarButtonItem = postButton;
    
    // make an instance of app delegate
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    
    // we're going to make our managedOBjectContext point to appDelegate's
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    _bleButtonSwitch.selectedSegmentIndex = 0;
    isCentral = YES;
    
    // initialize the context and its counter
    msgContext = @"XYZ";
    //contextCounter = 0;
    
    [_stringContext setText:msgContext];
    
    // to begin with, we want to know the last x seconds of messages
    localContextTimeOffset = 600;

    localAuthor = [[UIDevice currentDevice] name];
    localAuthor = [localAuthor stringByReplacingOccurrencesOfString:@"'s iPad" withString:@""];
    localAuthor = [localAuthor stringByReplacingOccurrencesOfString:@"'s iPhone" withString:@""];
    
    NSString *localIDString = [[[[UIDevice currentDevice] identifierForVendor] UUIDString] substringToIndex:3];
                
    localAuthor = [localAuthor stringByAppendingString:localIDString];
    
    [self refreshTextField];
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
  
    
}

- (void)StartCentralTimer {
    [self writeDebug:@"S: Start the central timer"];
    // after 5 seconds, start calling CentralTransfer every 15 seconds
    NSDate *d = [NSDate dateWithTimeIntervalSinceNow: 2.0];
    t = [[NSTimer alloc] initWithFireDate: d
                                          interval: 10
                                            target: self
                                          selector:@selector(CentralTransfer)
                                          userInfo:nil repeats:YES];
    
    NSRunLoop *runner = [NSRunLoop currentRunLoop];
    [runner addTimer:t forMode: NSDefaultRunLoopMode];
}

- (void)StartPeripheralTimer {
    [self writeDebug:@"S: start the peripheral timer"];
    

    NSTimer *t2 = [NSTimer scheduledTimerWithTimeInterval: 60
                                                  target: self
                                                selector:@selector(CheckPeripheralActivity)
                                                userInfo: nil repeats:NO];

    
    
    NSRunLoop *runner = [NSRunLoop currentRunLoop];
    [runner addTimer:t2 forMode: NSDefaultRunLoopMode];
}

- (void)CheckPeripheralActivity {
    [self writeDebug:@"S: Peripheral time has expired!"];
    // nobody has checked me in 60 seconds; switch to Central
    [self ChangeBLEmode];
    

}

- (void)CentralTransfer {
    
    if (isCentral == YES) {
    
        if (periphNotFoundCount >= 3) {
            [self writeDebug:@"C: No peripherals found, three scans in a row; change to periph mode"];
            
            periphNotFoundCount = 0;
            [self ChangeBLEmode];
            return;
        }
        
        [self writeDebug:@"C: CentralTransfer engaged; check discovered peripherals"];
 
        // get the peripherals
        NSArray *periphs = [_centralManager retrievePeripheralsWithIdentifiers:periphsDiscovered];
        
        // if the central manager has some peripherals, get them and loop over 'em
        if ([periphs count] > 0) {
            
            for (CBPeripheral *p in periphs) {
            
                [self writeDebug:[NSString stringWithFormat:@"C: pulled one - %@", p.name]];
                
                // now remove this peripheral from our list of discovered
                [periphsDiscovered removeObject:p.identifier];
                
                [self writeDebug:[NSString stringWithFormat:@"C: attempting connect to %@", p.name]];
                
                [_centralManager connectPeripheral:p options:nil];
                
            }
        } else {
            
            periphNotFoundCount++;
            
            // if the peripherals array is empty then there are none; so scan and get some
            [self writeDebug:[NSString stringWithFormat:@"C: no periph's found; start scanning"]];
            
            [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];
            
        }
        
    }
}


- (IBAction)changedContext:(id)sender {
    
    msgContext = _stringContext.text;
    
    [self refreshTextField];
    
}

- (void)ClearForContext {
    // put in code to remove all the entities that have the current context as theirs; then clear out the "context" box or change it to default
    [self writeDebug:@"*: clear button pressed"];

    // Construct a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MessagePost" inManagedObjectContext:self.managedObjectContext];
    
    // get all the messages
    [fetchRequest setEntity:entity];
    
    // only show from selected context
    NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"sContext = %@", msgContext];
    
    [fetchRequest setPredicate:searchFilter];
    
    NSError *error;
    NSArray *toDelete = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *item in toDelete) {
        [self.managedObjectContext deleteObject:item];
    }
    
    [self.managedObjectContext save:&error];
    
    [self refreshTextField];
    
    [_textStatus setText:@""];
   // [_stringContext setText:@"default"];
    
}

- (void)ChangeBLEmode {
    if (isCentral == YES) {
        [self writeDebug:@"S: switched to peripheral mode"];
        
        isCentral = NO;
        [_centralManager stopScan];
        
        // turn off the timer
        [t invalidate];
        t = nil;
        
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        [_peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey : @"SubContext", CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] }];
        
        
        
    } else {
        [self writeDebug:@"S: switched to central mode"];
        [_peripheralManager stopAdvertising];
        isCentral = YES;
        // turn off the timer
        [t2 invalidate];
        t2 = nil;
        
        [self StartCentralTimer];
    }
}


// Generates the alertView pop up to handle the post message

- (void)actionDoPost:(id)sender {
    NSLog(@"actionDoPost()");
    _alert =[[UIAlertView alloc ] initWithTitle:@"SubContext" message:@"Send Message" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
    _alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    [_alert addButtonWithTitle:@"Post"];
    [_alert show];
}

// This captures the message from the Post button push in the AlertView, and calls the appropriate method to send out the message
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    MessagePost *msg = [NSEntityDescription insertNewObjectForEntityForName:@"MessagePost" inManagedObjectContext:self.managedObjectContext];

    if (buttonIndex == 0)
    {
        [self writeDebug:@"*: message canceled"];
    }
    else if(buttonIndex == 1)
    {
        //textfield is the textbox from the alert
        UITextField *textField = [_alert textFieldAtIndex:0];
        textField.placeholder = @"your text";

        
        // get the message from the previous alert box
        msg.messageText = textField.text;
        
        // get the context from the text box
        msg.sContext = msgContext;
        
        // get the date
        msg.ts = [NSDate date];
        
        // you're the author
        msg.author = localAuthor;
        
        contextCounter += 1;
        
        // counter
        msg.counter = [NSNumber numberWithInteger:contextCounter];
        
        NSError *error;
        
        if (![self.managedObjectContext save:&error]) {
            [self writeDebug:[NSString stringWithFormat:@"DataModel: couldn't save: %@", [error localizedDescription]]];
        }
        
        [self refreshTextField];
    }
}

// the central will send its messages to the peripheral
- (void)sendSubscribedMessages:(CBPeripheral *)peripheral {
    NSString *payload;
    
    // Construct a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MessagePost" inManagedObjectContext:self.managedObjectContext];
    
    // get all the messages
    [fetchRequest setEntity:entity];
    
    // find the earliest message date
    NSDate *earliestMessageDate = [[NSDate date] dateByAddingTimeInterval:-remoteContextTimeOffset];
    
    // only show from selected context, more current than the earliest desired message date
    NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"sContext = %@ AND ts >= %@", currentRemoteContextString, earliestMessageDate];
    
    [fetchRequest setPredicate:searchFilter];
    
    NSError *error;
    self.messageArray = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    //NSInteger maxcount;
    NSInteger timediff;
    
    [self writeDebug:@"C: sending requested messages to peripheral"];
    for (MessagePost* mpost in self.messageArray)
    {
        // how many seconds since this message was posted?
        timediff = [[NSDate date] timeIntervalSinceDate: mpost.ts];
        
        if (mpost.messageText != nil) {
            // send counter|author|context|text|timediff
            payload = [NSString stringWithFormat:@"%@|%@|%@|%@|%ld", mpost.counter, mpost.author, mpost.sContext, mpost.messageText,(long)timediff];
            
            [self sendToPeripheral:peripheral targetMessage:[payload dataUsingEncoding:NSUTF8StringEncoding] targetCharacteristic:WRITE_POST_CHARACTERISTIC_UUID];
        }
    
    }
    
    // now that we've sent the messages we've been asked for, request messages from the peripheral by writing to the WRITE_CONTEXTREQ_CHARACTERISTIC_UUID characteristic
    [self writeDebug:[NSString stringWithFormat:@"C: sending Context and offset to peripheral: %@|%ld", msgContext, (long)localContextTimeOffset]];
    
    // get our desired context and how far back we wanna go
    payload = [NSString stringWithFormat:@"%@|%ld", msgContext, (long)localContextTimeOffset];
    
    [self sendToPeripheral:peripheral targetMessage:[payload dataUsingEncoding:NSUTF8StringEncoding] targetCharacteristic:WRITE_CONTEXTREQ_CHARACTERISTIC_UUID];
    

}
- (IBAction)clearContextData:(id)sender {
    [self ClearForContext];
}

// METHOD - CENTRAL SENDING TO PERIPHERAL USING THE WRITE CHARACTERISTIC (program running in Central Mode)
// This gets the peripheral object and scans for services and looks for the WRITE_POST_CHARACTERISTIC_UUID
// It updates the characteristic by doing the writeValue:data
- (void)sendToPeripheral:(CBPeripheral *)peripheral targetMessage:(NSData *)msg targetCharacteristic:(NSString *)targetchar {
    [self writeDebug:@"C: Beginning to Write Characteristic to Peripheral"];

    
    for(CBService *service in peripheral.services)
    {
        if([service.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]])
        {
            for(CBCharacteristic *charac in service.characteristics)
            {
                if([charac.UUID isEqual:[CBUUID UUIDWithString:targetchar]])
                {
                    [self writeDebug:[NSString stringWithFormat:@"C: write %@ for %@", msg, targetchar]];
                    
                    [peripheral writeValue:msg forCharacteristic:charac type:CBCharacteristicWriteWithoutResponse];
                    
                } else {
                    //[self writeDebug:[NSString stringWithFormat:@"C: looking for %@ and found %@", targetchar, [charac.UUID UUIDString]]];
                }
            }
        }
    }


    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_centralManager stopScan];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    [self writeDebug:@"C: checking CMPowerState and bleMode"];
    // if central isn't powered on, or bleMode was selected as peripheral, just exit out
    if (central.state != CBCentralManagerStatePoweredOn || isCentral == NO) {
         [self writeDebug:@"C: central wasn't powered on"];
        return;
    } else {
        [self writeDebug:@"C: central is powered on, call CentralTransfer via timer"];
        
        // start the central timer!
        [self StartCentralTimer];
    }

}



- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
   
    // so we have to add the peripherals to this array or else iOS drops' em
    if (!periphs) {
        periphs = [[NSMutableArray alloc] initWithObjects:peripheral, nil];
    } else {
        periphNotFoundCount = 0;
        [periphs addObject:peripheral];
    }
    
    
    // the previous added the peripherals to the "periphs" array - this one is just adding
    // the identifiers
    if (![periphsDiscovered containsObject:peripheral.identifier]) {
        [self writeDebug:[NSString stringWithFormat:@"C: Adding peripheral %@", peripheral.name]];

        [periphsDiscovered addObject:peripheral.identifier];
        
        [self CentralTransfer];
        
    }

}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self writeDebug:@"C: connect failed, call 'cleanup'"];
    [self cleanup:peripheral];
}

- (void)cleanup:(CBPeripheral *)peripheral {
    
    // See if we are subscribed to a characteristic on the peripheral
    if (peripheral.services != nil) {
        for (CBService *service in peripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SEND_POST_CHARACTERISTIC_UUID]]) {
                        NSLog(@"C: CLEANUP - found SEND_POST_CHAR so unsub");
                        if (characteristic.isNotifying) {
                            [peripheral setNotifyValue:NO forCharacteristic:characteristic];
                            return;
                        }
                    }
                }
            }
        }
    }
    
    [_centralManager cancelPeripheralConnection:peripheral];
}

// we've connected to the peripheral if this gets called
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self writeDebug:[NSString stringWithFormat:@"C: successfully connected to %@", peripheral.name]];
    
    peripheral.delegate = self;
    
    [self writeDebug:@"C: call discoverServices"];
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}

// This sets up the central to look for the characteristics.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        [self writeDebug:@"C: error discovering services, call cleanup"];
        [self cleanup:peripheral];
        return;
    }
    
    NSArray *characters = [NSArray arrayWithObjects:
                           [CBUUID UUIDWithString:SEND_POST_CHARACTERISTIC_UUID],
                           [CBUUID UUIDWithString:WRITE_POST_CHARACTERISTIC_UUID],
                           [CBUUID UUIDWithString:READ_CONTEXT_CHARACTERISTIC_UUID],
                           [CBUUID UUIDWithString:READ_NAME_CHARACTERISTIC_UUID],
                           [CBUUID UUIDWithString:WRITE_CONTEXTREQ_CHARACTERISTIC_UUID],
                           nil];
    
    // this discovers characteristics that we identified earlier
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:characters forService:service];

    }

}

// anything in here needs to be idempotent, because this can be run bunches and bunches of times
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        [self writeDebug:@"C: error discovering characteristics"];
        [self cleanup:peripheral];
        return;
    }
    
     [self writeDebug:[NSString stringWithFormat:@"C: discovered characteristics for %@", peripheral.name]];
    
    for (CBCharacteristic *characteristic in service.characteristics) {
/*        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:READ_NAME_CHARACTERISTIC_UUID]]) {
            nameChar = characteristic;
        }*/
        //[self processCharacteristic:characteristic];
        
        // this is what the peripheral uses to send msgpost data to the central
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SEND_POST_CHARACTERISTIC_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            //[self writeDebug:@"C: found and subscribing to SEND_POST"];
        }
        // this is what the central uses to send msgpost data to the peripheral
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:WRITE_POST_CHARACTERISTIC_UUID]]) {
            //[self writeDebug:@"C: found WRITE_POST"];
        }
        // this is what the central uses to read the peripheral's name
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:READ_NAME_CHARACTERISTIC_UUID]]) {
            //[self writeDebug:@"C: found READ_NAME; attempting read"];
            
            [peripheral readValueForCharacteristic:characteristic];
            
        }
        // this is what the central uses to determine what the peripheral wants
        else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:READ_CONTEXT_CHARACTERISTIC_UUID]]) {
            //[self writeDebug:@"C: found READ_CONTEXT; attempting read"];
            
            [peripheral readValueForCharacteristic:characteristic];
            
        }
        
    }
    

}


//- (void) processCharacteristic:(CBCharacteristic *)characteristic {
//}

// utility function to write out the status
- (void)writeDebug:(NSString *)debugtxt {
    
    NSMutableString* theText = [NSMutableString new];
    
    [theText appendFormat: @"%@\n%@", debugtxt, _textStatus.text];
    
    [_textStatus setText:theText];

    NSLog(debugtxt);
}

// METHOD - C <- P
// RECEIVE DATA FROM PERIPHERAL SENT TO CENTRAL (program running in Central Mode); run on the Central
// this is called every time a message from a subscribed notification is received by the Central from the Peripheral
// if it's "EOM" then that means the message is finished
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error");
        return;
    }
    
    // get the characteristic value coming from the peripheral
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
   
    // if the characteristic we're getting is an incoming subcontext post, tweet, whatever
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SEND_POST_CHARACTERISTIC_UUID]]) {
    
        [self writeDebug:[NSString stringWithFormat:@"C: incoming NOTIFY from %@", peripheral.name]];
    
        // Have we got everything we need?
        if ([stringFromData isEqualToString:@"EOM"]) {
            
            // take the data we've accrued thus far and stick it into a string
            NSString *receivedMsg = [[NSString alloc] initWithData:[_incomingDataToCentral valueForKey:[peripheral.identifier UUIDString]] encoding:NSUTF8StringEncoding];
            
            [self writeDebug:[NSString stringWithFormat:@"C: raw final: %@", receivedMsg]];
       
            NSArray *strings = [[[NSString alloc] initWithData:[_incomingDataToCentral valueForKey:[peripheral.identifier UUIDString]] encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"|"];
        
            // now that we're done with this message, get rid of the key
            [_incomingDataToCentral removeObjectForKey:[peripheral.identifier UUIDString]];
            
            
            NSNumber *ctr;
            NSString *dbauthor;
            NSString *dbcontext;
            NSString *dbmsg;
            NSDate *dbts;
            
            @try {
            
                ctr = [NSNumber numberWithInteger:[[strings objectAtIndex:0] intValue]];
                dbauthor = [strings objectAtIndex:1];
                dbcontext = [strings objectAtIndex:2];
                dbmsg = [strings objectAtIndex:3];
                dbts = [[NSDate date] dateByAddingTimeInterval:-[[strings objectAtIndex:4] intValue]];
            
            }
            @catch (NSException *exception) {
                [self writeDebug:[NSString stringWithFormat:@"C: can't parse incoming array"]];
            }
            
            // look for anything in this context with the same author and message counter
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"MessagePost" inManagedObjectContext:self.managedObjectContext];
            
            // get all the messages
            [fetchRequest setEntity:entity];
            
            // only show from selected context
            NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"author = %@ AND counter = %@ AND sContext = %@", dbauthor, ctr, dbcontext];
            
            [fetchRequest setPredicate:searchFilter];
            
            NSError *error;
            
            NSArray *found = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
                
            if ([found count] == 0) {
                
                MessagePost *msg = [NSEntityDescription insertNewObjectForEntityForName:@"MessagePost" inManagedObjectContext:self.managedObjectContext];
                
                msg.counter = ctr;
                msg.author = dbauthor;
                msg.sContext = dbcontext;
                msg.messageText = dbmsg;
                msg.ts = dbts;
                
                // store the message in the database
                if (![self.managedObjectContext save:&error]) {
                    NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                } else {
                    [self writeDebug:@"C: final receive from NOTIFY; writing to DB"];
                }
                
                // we received a new msg; we'll need to send it to others
            }
            
            // stop receiving notifications after all messages are sent
            // CHANGE - in order to receive multiple messages - keep listening!
            // [peripheral setNotifyValue:NO forCharacteristic:characteristic];
            
            
            
            // don't disconnect from the peripheral yet
            //[_centralManager cancelPeripheralConnection:peripheral];
            
            // now refresh the display
            [self refreshTextField];
            
        } else {
        // if the message isn't EOM, it's content, so append it
            [self writeDebug:[NSString stringWithFormat:@"C: building msg from CHAR: %@", characteristic.value]];
            //[_data appendData:characteristic.value];
            NSMutableData *incomingBytes = [[NSMutableData alloc] init];
            
            // if there's already data for the sender, read it in
            if ([_incomingDataToCentral valueForKey:[peripheral.identifier UUIDString]] != nil) {
                incomingBytes = [_incomingDataToCentral valueForKey:[peripheral.identifier UUIDString]];
            }
            
            // append the incoming data
            [incomingBytes appendData:characteristic.value];
            
            // now we should have a peripheral's stuff in our incoming dictionary
            [_incomingDataToCentral setObject:incomingBytes forKey:[peripheral.identifier UUIDString]];
        }
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString: READ_NAME_CHARACTERISTIC_UUID]]) {
        // this is if we're receiving the name of the remote user
        [self writeDebug:[NSString stringWithFormat:@"C: received remote name: %@", stringFromData]];
        
        currentRemotePartner = stringFromData;
        
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString: READ_CONTEXT_CHARACTERISTIC_UUID]]) {
        // this is if we're receiving the context and time offset

        [self writeDebug:[NSString stringWithFormat:@"C: received remote context: %@", stringFromData]];
        NSArray *strings = [stringFromData componentsSeparatedByString:@"|"];
        
        // the peripheral i'm talking to has given me its context it's interested in as well as time offset
        currentRemoteContextString  = [strings objectAtIndex:0];
        remoteContextTimeOffset = [[strings objectAtIndex:1] intValue];
        
        [self writeDebug:@"C: now call 'sendSubscribedMessages'"];
        [self sendSubscribedMessages:peripheral];
        
        // we (the central) need to now find all the messages for this context with a counter higher
        // than the remote's, and then SEND all these to the peripheral using the WRITE attribute - WRITE_POST_CHARACTERISTIC_UUID

        
    }
}

- (void)refreshTextField {
    // Construct a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MessagePost" inManagedObjectContext:self.managedObjectContext];
    
    
    // get all the messages
    [fetchRequest setEntity:entity];

    // only show from selected context
    NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"sContext = %@", msgContext];
    
    [fetchRequest setPredicate:searchFilter];
    
    NSError *error;
    self.messageArray = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    NSMutableString* theText = [NSMutableString new];
   
    NSString *dateAndTime;
    NSUInteger componentFlags =  NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
    
    
    for (MessagePost* mpost in self.messageArray)
    {

        NSDateComponents *components = [[NSCalendar currentCalendar] components:componentFlags fromDate:mpost.ts];
        
        NSInteger month = [components month];
        NSInteger day = [components day];
        NSInteger hour = [components hour];
        NSInteger minute = [components minute];
        
        dateAndTime = [NSString stringWithFormat: @"%d/%d %d:%d", (int)month, (int)day, (int)hour, (int)minute];
        
        if (mpost.messageText != nil) {
            [theText appendFormat: @"%@ (%@): %@\n", mpost.author, dateAndTime, mpost.messageText];
        }
        
    }
 
    [_textview setText:theText];
}

// we've successfully updated the notification state for a characteristic
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:SEND_POST_CHARACTERISTIC_UUID]]) {
        [self writeDebug:@"C: notify state wasn't for SEND_POST_CHARACTERISTIC"];
        return;
    }
    
    if (characteristic.isNotifying) {
        [self writeDebug:[NSString stringWithFormat:@"C: subscribed to SEND_POST on %@", peripheral.name]];

    }
}

// once you've disconnected from the peripheral
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
   
    [self writeDebug:[NSString stringWithFormat:@"C: disconnected from %@", peripheral.name]];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    // if the peripheral manager isn't working OR you're in Central mode, just stop.  Seriously just stop right now.
    [self writeDebug:@"P: checking PMPowerState and bleMode"];
    
    if (peripheral.state != CBPeripheralManagerStatePoweredOn || isCentral == YES) {
        [self writeDebug:[NSString stringWithFormat:@"P: peripheral wasn't powered on OR Central was selected (%hhd)", isCentral]];
        return;
    }
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        
        
        [self writeDebug:@"P: set up WRITE_CONTEXTREQ so central can request msgs"];
        self.receiveContextReqCharacteristic = [[CBMutableCharacteristic alloc]
                                          initWithType:[CBUUID UUIDWithString:WRITE_CONTEXTREQ_CHARACTERISTIC_UUID]
                                          properties:CBCharacteristicPropertyWriteWithoutResponse
                                          value:nil
                                          permissions:CBAttributePermissionsWriteable
                                          ];
        
        
        [self writeDebug:@"P: set up SEND_POST_CHAR"];
        self.sendPostCharacteristic = [[CBMutableCharacteristic alloc]
                                        initWithType:[CBUUID UUIDWithString:SEND_POST_CHARACTERISTIC_UUID]
                                        properties:CBCharacteristicPropertyNotify
                                        value:nil
                                        permissions:CBAttributePermissionsReadable
                                       ];
        
       
        [self writeDebug:@"P: set up READ_NAME_CHAR so folks can get your name"];
        self.receivePostCharacteristic = [[CBMutableCharacteristic alloc]
                                            initWithType:[CBUUID UUIDWithString:WRITE_POST_CHARACTERISTIC_UUID]
                                            properties:CBCharacteristicPropertyWriteWithoutResponse
                                            value:nil
                                            permissions:CBAttributePermissionsWriteable
                                          ];
        
        [self writeDebug:@"P: set up READ_CONTEXT_CHAR so folks can get your interested context"];
        self.nameReadCharacteristic = [[CBMutableCharacteristic alloc]
                                          initWithType:[CBUUID UUIDWithString:READ_NAME_CHARACTERISTIC_UUID]
                                          properties:CBCharacteristicPropertyRead
                                          value:nil
                                          permissions:CBAttributePermissionsReadable
                                          ];
        
        [self writeDebug:@"P: set up WRITE_POST_CHAR"];
        self.contextReadCharacteristic = [[CBMutableCharacteristic alloc]
                                       initWithType:[CBUUID UUIDWithString:READ_CONTEXT_CHARACTERISTIC_UUID]
                                       properties:CBCharacteristicPropertyRead
                                       value:nil
                                       permissions:CBAttributePermissionsReadable
                                       ];
        
        
        [self writeDebug:@"P: set up TRANSFER_SERVICE"];
        CBMutableService *transferService = [[CBMutableService alloc]
                                             initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]
                                             primary:YES
                                            ];
        
        [self writeDebug:@"P: add CHARs to SERVICE"];
        
        transferService.characteristics = @[_sendPostCharacteristic,_receivePostCharacteristic,_nameReadCharacteristic,_contextReadCharacteristic,_receiveContextReqCharacteristic];
        
        [self writeDebug:@"P: add SERVICE"];
        [_peripheralManager addService:transferService];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    [self writeDebug:@"P: service successfully added - start our 60 second timer"];
    // gotta start the timeout deal
    [self StartPeripheralTimer];
    
}

// METHOD - P -> C
// Peripheral sends data to Central who is subscribed to its NOTIFY characteristc
// This takes whatever is in the dataToSend string and sends it to the central in a chunked fashion
- (void)sendToCentral {
    [self writeDebug:@"P: send to central called!"];
  
    
    // if there's nothing to send, then just exit
    if ([msgsToSend count] <= 0) {
        [self writeDebug:@"P: there was no data to send, so I'm exiting"];
        return;
    }
    
    // get the top item!
    DataToSend *sendMe = [msgsToSend objectAtIndex:0];
    
    //get the top message in "msgsToSend"
    
    
    // end of message; ie, if the message object exists and all of it has been sent
    // then you need to send an EOM and kill the object
    if ([sendMe.sendIndex intValue] >= sendMe.payload.length) {
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.sendPostCharacteristic onSubscribedCentrals:nil];
        
        if (didSend) {
            [self writeDebug:@"P: Sent EOM, removing Object (up top)"];
            // you've sent it, now get rid of it
            [msgsToSend removeObject:sendMe];
            
            [self writeDebug:@"P: Message was sent, so call sendCentral (this method) again"];
            [self sendToCentral];
        }
        
        // didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're sending data
    // Is there any left to send?
    if ([sendMe.sendIndex intValue] >= sendMe.payload.length) {
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    BOOL didSend = YES;
    
    while (didSend) {
        // Work out how big it should be
        NSInteger amountToSend = sendMe.payload.length - [sendMe.sendIndex intValue];
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:sendMe.payload.bytes+[sendMe.sendIndex intValue] length:amountToSend];
        
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.sendPostCharacteristic onSubscribedCentrals:nil];
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];

        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            [self writeDebug:@"P: chunk not sent; wait for next callback"];
            return;
        } else {
             [self writeDebug:[NSString stringWithFormat:@"P: chunk sent: %@", stringFromData]];
        }
        
        // It did send, so update our index
        sendMe.sendIndex = [NSNumber numberWithLong:[sendMe.sendIndex intValue] + amountToSend];
        
        // Was it the last one?
        if ([sendMe.sendIndex intValue] >= sendMe.payload.length) {
            
            [self writeDebug:@"P: previous chunk was final"];
            
          
             [self writeDebug:@"P: try to send EOM"];
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.sendPostCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
               [self writeDebug:@"P: Sent EOM, removing Object"];
                // you've sent it, now get rid of it
                [msgsToSend removeObject:sendMe];
                // It sent, we're all done
            } else {
                [self writeDebug:@"P: EOM not sent"];
            }
            
            return;
        }
    }
}

// if "updateValue:forCharacteristic:onSubscribedCentrals:" fails because there's no room, left in the buffer, this method is called when the peripheral is ready to send info to the subscribing central
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    [self sendToCentral];
}

// P <- C
// program running in Peripheral mode
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    
    CBATTRequest*       request = [requests  objectAtIndex: 0];
    NSData*             request_data = request.value;
    CBCharacteristic*   write_char = request.characteristic;
    
    
    
    if([ write_char.UUID isEqual: [CBUUID UUIDWithString: WRITE_POST_CHARACTERISTIC_UUID]] )
    {
        [self writeDebug:@"P: received WRITE_POST request"];
        NSString* newStr = [[NSString alloc] initWithData:request_data encoding:NSUTF8StringEncoding];
        
        [self writeDebug:[NSString stringWithFormat:@"P: raw msg: %@", newStr]];
        
        //counter|author|context|text|timediff
        NSArray *strings = [newStr componentsSeparatedByString:@"|"];
        
        NSInteger remoteCounter = [[strings objectAtIndex:0] intValue];
        
        // if the other party's counter is greater than ours, set ours to theirs and store msg
        //if (remoteCounter > contextCounter) {
        contextCounter = remoteCounter;
    
        NSNumber *ctr = [NSNumber numberWithInteger:[[strings objectAtIndex:0] intValue]];
        NSString *dbauthor = [strings objectAtIndex:1];
        NSString *dbcontext = [strings objectAtIndex:2];
        NSString *dbmsg = [strings objectAtIndex:3];
        NSDate *dbts = [[NSDate date] dateByAddingTimeInterval:-[[strings objectAtIndex:4] intValue]];
    
        // look for anything in this context with the same author and message counter
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"MessagePost" inManagedObjectContext:self.managedObjectContext];
        
        // get all the messages
        [fetchRequest setEntity:entity];
        
        // only show from selected context
        NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"author = %@ AND counter = %@ AND sContext = %@", dbauthor, ctr, dbcontext];
        
        [fetchRequest setPredicate:searchFilter];
        
        NSError *error;
     
        NSArray *found = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        // if nothing is found for that combo, add the message
        if ([found count] == 0) {
        
            MessagePost *msg = [NSEntityDescription insertNewObjectForEntityForName:@"MessagePost" inManagedObjectContext:self.managedObjectContext];
            
            msg.counter = ctr;
            msg.author = dbauthor;
            msg.sContext = dbcontext;
            msg.messageText = dbmsg;
            msg.ts = dbts;
                      
            // store the message in the database
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            }
            //}
            [self refreshTextField];
        }
    } else if([ write_char.UUID isEqual: [CBUUID UUIDWithString: WRITE_CONTEXTREQ_CHARACTERISTIC_UUID]] ) {
        [self writeDebug:@"P: received WRITE_CONTEXTREQ request"];
    
        NSString* stringFromData = [[NSString alloc] initWithData:request_data encoding:NSUTF8StringEncoding];
        
        [self writeDebug:[NSString stringWithFormat:@"P: raw WRITE msg: %@", stringFromData]];
        
        NSArray *strings = [stringFromData componentsSeparatedByString:@"|"];
        
        // the peripheral i'm talking to has given me its context it's interested in as well as time offset
        currentRemoteContextString  = [strings objectAtIndex:0];
        remoteContextTimeOffset = [[strings objectAtIndex:1] intValue];
        
        // our global variables are now flush with the info we need to send the Central back some messages that he's interested in
        // now build a query and send those messages with the sendToCentral method
        NSString *payload;
        
        // Construct a fetch request
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"MessagePost" inManagedObjectContext:self.managedObjectContext];
        
        // get all the messages
        [fetchRequest setEntity:entity];
        
        // find the earliest message date
        NSDate *earliestMessageDate = [[NSDate date] dateByAddingTimeInterval:-remoteContextTimeOffset];
        
        // only show from selected context, more current than the earliest desired message date
        NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"sContext = %@ AND ts >= %@", currentRemoteContextString, earliestMessageDate];
        
        [fetchRequest setPredicate:searchFilter];
        
        NSError *error;
        self.messageArray = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        //NSInteger maxcount;
        NSInteger timediff;
        
        for (MessagePost* mpost in self.messageArray)
        {
            // how many seconds since this message was posted?
            timediff = [[NSDate date] timeIntervalSinceDate: mpost.ts];
            
            if (mpost.messageText != nil) {
                // send counter|author|context|text|timediff
                payload = [NSString stringWithFormat:@"%@|%@|%@|%@|%ld", mpost.counter, mpost.author, mpost.sContext, mpost.messageText,(long)timediff];
                
                [self writeDebug:@"P: create object to send"];
                
                // make some data to send
                DataToSend *ds = [[DataToSend alloc] init];
                ds.payload = [payload dataUsingEncoding:NSUTF8StringEncoding];
                ds.sendIndex = [NSNumber numberWithInteger:0];
                ds.eomStatus = @"notsent";
                
                // add this message to send
                [msgsToSend addObject:ds];
                
            }
            
        }
        
        [self writeDebug:@"P: objects ready; call sendToCentral"];
        // send messages built up in array
        [self sendToCentral];
        
    }
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {

    
    // being asked for your READ_NAME_CHARACTERISTIC
    if ([request.characteristic.UUID isEqual: [CBUUID UUIDWithString: READ_NAME_CHARACTERISTIC_UUID]]) {
        
        _nameReadCharacteristic.value = [localAuthor dataUsingEncoding:NSUTF8StringEncoding];
        
        // if too much info is being requested, send the Central an Invalid offset message
        if (request.offset > _nameReadCharacteristic.value.length) {
            [self.peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
            return;
        }
        
        request.value = [_nameReadCharacteristic.value
                         subdataWithRange:NSMakeRange(request.offset, _nameReadCharacteristic.value.length - request.offset)];
        
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
    
    // being asked for your READ_CONTEXT_CHARACTERISTIC
    if ([request.characteristic.UUID isEqual: [CBUUID UUIDWithString: READ_CONTEXT_CHARACTERISTIC_UUID]]) {

        // the value won't be long; just the current context the peripheral wants and the time offset
        _nameReadCharacteristic.value = [[NSString stringWithFormat:@"%@|%ld", msgContext, (long)localContextTimeOffset] dataUsingEncoding:NSUTF8StringEncoding];
        
        // if too much info is being requested, send the Central an Invalid offset message
        if (request.offset > _nameReadCharacteristic.value.length) {
            [self.peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
            return;
        }
        
        request.value = [_nameReadCharacteristic.value
                         subdataWithRange:NSMakeRange(request.offset, _nameReadCharacteristic.value.length - request.offset)];
        
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

@end
