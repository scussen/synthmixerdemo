//
//  SCSynthMixerViewController.h
//  SynthMixDemo
//
//  Created by Stephen Cussen on 12/5/13.
//  Copyright (c) 2013 Stephen Cussen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface SCSynthMixerViewController : UIViewController

- (IBAction) startPlayLowNote:(id)sender;
- (IBAction) stopPlayLowNote:(id)sender;
- (IBAction) startPlayMidNote:(id)sender;
- (IBAction) stopPlayMidNote:(id)sender;
- (IBAction) startPlayHighNote:(id)sender;
- (IBAction) stopPlayHighNote:(id)sender;
- (IBAction) pitchAdjustmentChanged:(id)sender;
- (IBAction) mixerBusInputSelect:(id)sender;


@end
