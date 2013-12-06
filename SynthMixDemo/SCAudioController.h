//
//  SCAudioController.h
//  Sound Scape
//
//  Created by Stephen Cussen on 11/19/13.
//  Copyright (c) 2013 Stephen Cussen. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface SCAudioController : NSObject <AVAudioSessionDelegate>
@property (readwrite) AudioUnit samplerUnit;
@property (readwrite) AudioUnit samplerUnit2;
@property (readwrite)  BOOL bus1IsOn;
@property (readwrite)  BOOL bus2IsOn;

- (void) setupAudio;
@end
