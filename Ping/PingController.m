//
//  PingController.m
//  Ping
//
//  Created by Yatin Sarbalia on 08/12/12.
//  Copyright (c) 2012 Yatin Sarbalia. All rights reserved.
//

#import "PingController.h"

#include <sys/socket.h>
#include <netdb.h>

#pragma mark * Utilities

static NSString * DisplayAddressForAddress(NSData * address)
// Returns a dotted decimal string for the specified address (a (struct sockaddr)
// within the address NSData).
{
  int         err;
  NSString *  result;
  char        hostStr[NI_MAXHOST];
  
  result = nil;
  
  if (address != nil) {
    err = getnameinfo([address bytes], (socklen_t) [address length], hostStr, sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
    if (err == 0) {
      result = [NSString stringWithCString:hostStr encoding:NSASCIIStringEncoding];
      assert(result != nil);
    }
  }
  
  return result;
}

@implementation PingController
@synthesize pinger    = _pinger;
@synthesize sendTimer = _sendTimer;

- (void)dealloc
{
  [self->_pinger stop];
  [self->_sendTimer invalidate];
}

- (NSString *)shortErrorFromError:(NSError *)error
// Given an NSError, returns a short error string that we can print, handling
// some special cases along the way.
{
  NSString *      result;
  NSNumber *      failureNum;
  int             failure;
  const char *    failureStr;
  
  assert(error != nil);
  
  result = nil;
  
  // Handle DNS errors as a special case.
  
  if ( [[error domain] isEqual:(NSString *)kCFErrorDomainCFNetwork] && ([error code] == kCFHostErrorUnknown) ) {
    failureNum = [[error userInfo] objectForKey:(id)kCFGetAddrInfoFailureKey];
    if ( [failureNum isKindOfClass:[NSNumber class]] ) {
      failure = [failureNum intValue];
      if (failure != 0) {
        failureStr = gai_strerror(failure);
        if (failureStr != NULL) {
          result = [NSString stringWithUTF8String:failureStr];
          assert(result != nil);
        }
      }
    }
  }
  
  // Otherwise try various properties of the error object.
  
  if (result == nil) {
    result = [error localizedFailureReason];
  }
  if (result == nil) {
    result = [error localizedDescription];
  }
  if (result == nil) {
    result = [error description];
  }
  assert(result != nil);
  return result;
}

- (void)runWithHostName:(NSString *)hostName
// The Objective-C 'main' for this program.  It creates a SimplePing object
// and runs the runloop sending pings and printing the results.
{
  assert(self.pinger == nil);
  
  self.pinger = [SimplePing simplePingWithHostName:hostName];
  assert(self.pinger != nil);
  
  self.pinger.delegate = self;
  [self.pinger start];
}

- (void)sendPing
// Called to send a ping, both directly (as soon as the SimplePing object starts up)
// and via a timer (to continue sending pings periodically).
{
  assert(self.pinger != nil);
  [self.pinger sendPingWithData:nil];
}

- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
// A SimplePing delegate callback method.  We respond to the startup by sending a
// ping immediately and starting a timer to continue sending them every second.
{
#pragma unused(pinger)
  assert(pinger == self.pinger);
  assert(address != nil);
  
  NSString *log = [NSString stringWithFormat:@"pinging %@", DisplayAddressForAddress(address)];
  [self.delegate pingController:self addLog:log];

  // Send the first ping straight away.
  
  [self sendPing];
  
  // And start a timer to send the subsequent pings.
  
  assert(self.sendTimer == nil);
  self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(sendPing) userInfo:nil repeats:YES];
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error
// A SimplePing delegate callback method.  We shut down our timer and the
// SimplePing object itself, which causes the runloop code to exit.
{
#pragma unused(pinger)
  assert(pinger == self.pinger);
#pragma unused(error)
  NSString *log = [NSString stringWithFormat:@"failed: %@", [self shortErrorFromError:error]];
  [self.delegate pingController:self addLog:log];
  
  [self.sendTimer invalidate];
  self.sendTimer = nil;
  
  // No need to call -stop.  The pinger will stop itself in this case.
  // We do however want to nil out pinger so that the runloop stops.
  
  self.pinger = nil;
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet
// A SimplePing delegate callback method.  We just log the send.
{
#pragma unused(pinger)
  assert(pinger == self.pinger);
#pragma unused(packet)
  NSString *log = [NSString stringWithFormat:@"#%u sent", (unsigned int) OSSwapBigToHostInt16(((const ICMPHeader *) [packet bytes])->sequenceNumber)];
  [self.delegate pingController:self addLog:log];
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error
// A SimplePing delegate callback method.  We just log the failure.
{
#pragma unused(pinger)
  assert(pinger == self.pinger);
#pragma unused(packet)
#pragma unused(error)
  NSString *log = [NSString stringWithFormat:@"#%u send failed: %@", (unsigned int) OSSwapBigToHostInt16(((const ICMPHeader *) [packet bytes])->sequenceNumber), [self shortErrorFromError:error]];
  [self.delegate pingController:self addLog:log];
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
// A SimplePing delegate callback method.  We just log the reception of a ping response.
{
#pragma unused(pinger)
  assert(pinger == self.pinger);
#pragma unused(packet)
  NSString *log = [NSString stringWithFormat:@"#%u received", (unsigned int) OSSwapBigToHostInt16([SimplePing icmpInPacket:packet]->sequenceNumber)];
  [self.delegate pingController:self addLog:log];
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet
// A SimplePing delegate callback method.  We just log the receive.
{
  const ICMPHeader *  icmpPtr;
  
#pragma unused(pinger)
  assert(pinger == self.pinger);
#pragma unused(packet)
  
  icmpPtr = [SimplePing icmpInPacket:packet];
  if (icmpPtr != NULL) {
    NSString *log = [NSString stringWithFormat:@"#%u unexpected ICMP type=%u, code=%u, identifier=%u", (unsigned int) OSSwapBigToHostInt16(icmpPtr->sequenceNumber), (unsigned int) icmpPtr->type, (unsigned int) icmpPtr->code, (unsigned int) OSSwapBigToHostInt16(icmpPtr->identifier) ];
    [self.delegate pingController:self addLog:log];
  } else {
    NSString *log = [NSString stringWithFormat:@"unexpected packet size=%zu", (size_t) [packet length] ];
    [self.delegate pingController:self addLog:log];
  }
}

@end
