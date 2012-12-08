//
//  PingController.h
//  Ping
//
//  Created by Yatin Sarbalia on 08/12/12.
//  Copyright (c) 2012 Yatin Sarbalia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimplePing.h"

@protocol PingControllerDelegate;

@interface PingController : NSObject <SimplePingDelegate>

@property (nonatomic, strong, readwrite) SimplePing *pinger;
@property (nonatomic, strong, readwrite) NSTimer *sendTimer;
@property (nonatomic, assign) id<PingControllerDelegate> delegate;

- (void)runWithHostName:(NSString *)hostName;

@end

@protocol PingControllerDelegate <NSObject>

- (void)pingController:(PingController *)pingController addLog:(NSString *)log;

@end
