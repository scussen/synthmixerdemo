//
//  SCSynthMixerViewController.m
//  SynthMixDemo
//
//  Created by Stephen Cussen on 12/5/13.
//  Copyright (c) 2013 Stephen Cussen. All rights reserved.
//

#import "SCSynthMixerViewController.h"
#import "SCAudioController.h"

// some MIDI constants:
enum {
	kMIDIMessage_NoteOn    = 0x9,
	kMIDIMessage_NoteOff   = 0x8,
};

enum{lowNote, midNote, highNote};

// define some midi notes to play - middle C (60), C one octave below (48) and C one octave above (72)
#define kLowNote  48
#define kMidNote  60
#define kHighNote 72

@interface SCSynthMixerViewController ()
@property SCAudioController *ssAudio;
@end

@implementation SCSynthMixerViewController
@synthesize ssAudio;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // work around for the annoying segmented control tint bug

//    [self.mySegmentedControl setTintColor:[UIColor clearColor]];
//    [self.mySegmentedControl setTintColor:self.view.tintColor];
    
    
    // setup the Sound Scape Audio Control
    ssAudio = [[SCAudioController alloc] init];
    [ssAudio setupAudio];
    
    ssAudio.bus1IsOn = YES;
    _bus1Button.selected = YES;
    ssAudio.bus2IsOn = NO;
    _bus2Button.selected = NO;
    
    _bus1PresetName.text = @"Fantasia 2";
    _bus2PresetName.text = @"Fiddle";
        [[UINavigationBar appearance]  setTintColor:[UIColor clearColor]];
        [[UINavigationBar appearance]  setTintColor:[UIColor greenColor]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Audio control

// Start the note play
- (IBAction) startPlayNote:(id)sender {
    UIButton *button = (UIButton*) sender;
    UInt32 noteNum;
    
    switch(button.tag) {
        case lowNote:
            noteNum = kLowNote;
            break;
        case midNote:
            noteNum = kMidNote;
            break;
        case highNote:
            noteNum = kHighNote;
            break;
        default:
            noteNum = kMidNote;
            break;
    }
    
	UInt32 onVelocity = 127;
	UInt32 noteCommand = 	kMIDIMessage_NoteOn << 4 | 0;
    OSStatus result = noErr;
	if(ssAudio.bus1IsOn) result = MusicDeviceMIDIEvent(ssAudio.samplerUnit, noteCommand, noteNum, onVelocity, 0);
    if (result != noErr) NSLog (@"Unable to start playing the note on samplerUnit. Error code: %d\n", (int) result);
    if(ssAudio.bus2IsOn) result = MusicDeviceMIDIEvent(ssAudio.samplerUnit2, noteCommand, noteNum, onVelocity, 0);
    if (result != noErr) NSLog (@"Unable to start playing the note on samplerUnit2. Error code: %d\n", (int) result);
}

// Stop the note play
- (IBAction) stopPlayNote:(id)sender {
    UIButton *button = (UIButton*) sender;
    UInt32 noteNum;
    
    switch(button.tag) {
        case lowNote:
            noteNum = kLowNote;
            break;
        case midNote:
            noteNum = kMidNote;
            break;
        case highNote:
            noteNum = kHighNote;
            break;
        default:
            noteNum = kMidNote;
            break;
    }

	UInt32 noteCommand = 	kMIDIMessage_NoteOff << 4 | 0;
    OSStatus result = noErr;
	if(ssAudio.bus1IsOn) result = MusicDeviceMIDIEvent(ssAudio.samplerUnit, noteCommand, noteNum, 0, 0);
    if (result != noErr) NSLog (@"Unable to stop playing the note on samplerUnit. Error code: %d\n", (int) result);
	if(ssAudio.bus2IsOn) result = MusicDeviceMIDIEvent(ssAudio.samplerUnit2, noteCommand, noteNum, 0, 0);
    if (result != noErr) NSLog (@"Unable to stop playing the note on samplerUnit2. Error code: %d\n", (int) result);
}

- (IBAction)pitchAdjustmentChanged:(id)sender {
    UISlider *slider = (UISlider *)sender;
    int pitchAdj = (int)roundf(slider.value);
    if (abs(pitchAdj) <= 5 ) {
        pitchAdj = 0;
    }
    NSLog(@"Pitch adjustment value = %d", pitchAdj);
    _pitchAdjustmentValue.text = [NSString stringWithFormat:@"%d", pitchAdj];
    int result = [ssAudio pitchAdj:pitchAdj];

    if(result != 0) NSLog (@"Unable to set the property pitch adjustment parameter on the effects unit. Error code: %d\n", (int) result);
}

- (IBAction)toggleBus1:(id)sender {
    ssAudio.bus1IsOn = !ssAudio.bus1IsOn;
    if (ssAudio.bus1IsOn) _bus1Button.selected = YES;
    else _bus1Button.selected = NO;
}

- (IBAction)toggleBus2:(id)sender {
    ssAudio.bus2IsOn = !ssAudio.bus2IsOn;
    if (ssAudio.bus2IsOn) _bus2Button.selected = YES;
    else _bus2Button.selected = NO;
}


@end
