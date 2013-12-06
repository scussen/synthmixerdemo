//
//  SCAudioController.m
//  Sound Scape
//
//  Created by Stephen Cussen on 11/19/13.
//  Copyright (c) 2013 Stephen Cussen. All rights reserved.
//

#import "SCAudioController.h"

// private class extension
@interface SCAudioController ()
@property (readwrite) Float64   graphSampleRate;
@property (readwrite) AUGraph   processingGraph;
@property (readwrite) AudioUnit pitchEffectUnit;
@property (readwrite) AudioUnit mixerUnit;
@property (readwrite) AudioUnit ioUnit;

//- (void)    registerForUIApplicationNotifications;
- (BOOL)    createAUGraph;
- (void)    configureAndStartAudioProcessingGraph: (AUGraph) graph;
- (void)    load2SoundFonts;
//- (void)    stopAudioProcessingGraph;
//- (void)    restartAudioProcessingGraph;
@end

@implementation SCAudioController

- (void) setupAudio {
    // Set up the audio session for this app, in the process obtaining the
    // hardware sample rate for use in the audio processing graph.
    BOOL audioSessionActivated = [self setupAudioSession];
    NSAssert (audioSessionActivated == YES, @"Unable to set up audio session.");
    
    // Create the audio processing graph; place references to the graph and to the Sampler unit
    // into the processingGraph and samplerUnit instance variables.
    [self createAUGraph];
    [self configureAndStartAudioProcessingGraph: self.processingGraph];
    
    [self load2SoundFonts];
    
    self.bus1IsOn = NO;
    self.bus2IsOn = YES;
}

#pragma mark -
#pragma mark Audio setup

// Create an audio processing graph.
- (BOOL) createAUGraph {
    
	OSStatus result = noErr;
	AUNode samplerNode, samplerNode2, pitchEffectNode, mixerNode, ioNode;
    
    // Specify the common portion of an audio unit's identify, used for both audio units
    // in the graph.
	AudioComponentDescription cd = {};
	cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
	cd.componentFlags            = 0;
	cd.componentFlagsMask        = 0;
    
    // Instantiate an audio processing graph
	result = NewAUGraph (&_processingGraph);
    if (result != noErr) NSLog (@"Unable to create an AUGraph object. Error code: %d", (int)result);
    
	//Specify the Sampler units, first nodes of the graph
	cd.componentType = kAudioUnitType_MusicDevice;
	cd.componentSubType = kAudioUnitSubType_Sampler;
	
    // Add the Sampler unit node to the graph
	result = AUGraphAddNode (self.processingGraph, &cd, &samplerNode);
    if (result != noErr) NSLog (@"Unable to add the Sampler unit to the audio processing graph. Error code: %d", (int) result);
    
    // Add the Sampler unit 2 node to the graph
	result = AUGraphAddNode (self.processingGraph, &cd, &samplerNode2);
    if (result != noErr) NSLog (@"Unable to add the Sampler unit 2 to the audio processing graph. Error code: %d", (int) result);
    
    //............................................................................
    // Add the Effects unit node to the graph
    // AUTime Pitch Effect Unit
    AudioComponentDescription EffectsUnitDescription = {0};
    EffectsUnitDescription.componentType          = kAudioUnitType_FormatConverter;
    EffectsUnitDescription.componentSubType       = kAudioUnitSubType_NewTimePitch;
    EffectsUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    
    result =    AUGraphAddNode (
                                self.processingGraph,
                                &EffectsUnitDescription,
                                &pitchEffectNode);
    if (result != noErr) NSLog (@"Unable to add the Effect Node [time/pitch] to the audio processing graph. Error code: %d", (int) result);
    
    //............................................................................
    // Add the Mixer unit node to the graph
    
    // Multichannel mixer unit
    AudioComponentDescription MixerUnitDescription;
    MixerUnitDescription.componentType          = kAudioUnitType_Mixer;
    MixerUnitDescription.componentSubType       = kAudioUnitSubType_MultiChannelMixer;
    MixerUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    MixerUnitDescription.componentFlags         = 0;
    MixerUnitDescription.componentFlagsMask     = 0;
    
    result =    AUGraphAddNode (
                                self.processingGraph,
                                &MixerUnitDescription,
                                &mixerNode
                                );
    if (result != noErr) NSLog (@"Unable to add the Mixer unit to the audio processing graph. Error code: %d", (int) result);
    
    //............................................................................
	// Specify the Output unit, to be used as the 4th and final node of the graph
	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_RemoteIO;
    
    // Add the Output unit node to the graph
	result = AUGraphAddNode (self.processingGraph, &cd, &ioNode);
    if (result != noErr) NSLog (@"Unable to add the Output unit to the audio processing graph. Error code: %d", (int) result);
    
    // Open the graph
	result = AUGraphOpen (self.processingGraph);
    if (result != noErr) NSLog (@"Unable to open the audio processing graph. Error code: %d", (int) result);

    //............................................................................
    // Obtain the mixer unit instance from its corresponding node.
    
    result =    AUGraphNodeInfo (
                                 self.processingGraph,
                                 mixerNode,
                                 NULL,
                                 &_mixerUnit
                                 );
    if (result != noErr) NSLog (@"AUGraphNodeInfo on Mixer. Error code: %d", (int) result);
    
    //............................................................................
    // Multichannel Mixer unit Setup
    
    UInt32 busCount   = 2;    // bus count for mixer unit input
    //    UInt32 samplerBus  = 0;    // mixer unit bus 0 will be the instrument from sampler
    //    UInt32 sampler2Bus   = 1;    // mixer unit bus 1 will be the instrument from sampler2
    
    NSLog (@"Setting mixer unit input bus count to: %u", (unsigned int)busCount);
    result = AudioUnitSetProperty (
                                   _mixerUnit,
                                   kAudioUnitProperty_ElementCount,
                                   kAudioUnitScope_Input,
                                   0,
                                   &busCount,
                                   sizeof (busCount)
                                   );
    if (result != noErr) NSLog (@"AudioUnitSetProperty (set mixer unit bus count). Error code: %d", (int) result);
    
    //............................................................................
    //------------------
    // Connect the nodes
    //------------------
    
    AUGraphConnectNodeInput (self.processingGraph, samplerNode, 0, mixerNode, 0);
    if (result != noErr) NSLog (@"Unable to interconnect the sampler node to the mixer node in the audio processing graph. Error code: %d", (int) result);
    // connect the sample node 2 to the effects unit
    AUGraphConnectNodeInput (self.processingGraph, samplerNode2, 0, pitchEffectNode, 0);
    if (result != noErr) NSLog (@"Unable to interconnect the sampler node 2 to the effects node in the audio processing graph. Error code: %d", (int) result);
    // connect the effects unit to the mixer bus 2
    AUGraphConnectNodeInput (self.processingGraph, pitchEffectNode, 0, mixerNode, 1);
    if (result != noErr) NSLog (@"Unable to interconnect the effects node to the mixer node bus 2 in the audio processing graph. Error code: %d", (int) result);
    // Connect the mixer unit to the output unit
    AUGraphConnectNodeInput (self.processingGraph, mixerNode, 0, ioNode, 0);
    if (result != noErr) NSLog (@"Unable to interconnect the mixer node to the ouput node in the audio processing graph. Error code: %d", (int) result);
    
    // Obtain references to all of the audio units from their nodes
    AUGraphNodeInfo (self.processingGraph, samplerNode, 0, &_samplerUnit);
    if (result != noErr) NSLog (@"Unable to obtain a reference to the Sampler unit. Error code: %d", (int) result);
    AUGraphNodeInfo (self.processingGraph, samplerNode2, 0, &_samplerUnit2);
    if (result != noErr) NSLog (@"Unable to obtain a reference to the Sampler unit 2. Error code: %d", (int) result);
    AUGraphNodeInfo (self.processingGraph, pitchEffectNode, 0, &_pitchEffectUnit);
    if (result != noErr) NSLog (@"Unable to obtain a reference to the Effects unit. Error code: %d", (int) result);
	result = AUGraphNodeInfo (self.processingGraph, ioNode, 0, &_ioUnit);
    if (result != noErr) NSLog (@"Unable to obtain a reference to the I/O unit. Error code: %d", (int) result);
    
    return YES;
}


// With an instantiated audio processing graph, configure
// audio units, initialize it, and start it.
- (void) configureAndStartAudioProcessingGraph: (AUGraph) graph {
    
    OSStatus result = noErr;
    UInt32 framesPerSlice = 0;
    UInt32 framesPerSlicePropertySize = sizeof (framesPerSlice);
    UInt32 sampleRatePropertySize = sizeof (self.graphSampleRate);
    
    result = AudioUnitInitialize (self.ioUnit);
    if (result != noErr) NSLog (@"Unable to initialize the I/O unit. Error code: %d", (int) result);
    
    // Set the I/O unit's output sample rate.
    result =    AudioUnitSetProperty (
                                      self.ioUnit,
                                      kAudioUnitProperty_SampleRate,
                                      kAudioUnitScope_Output,
                                      0,
                                      &_graphSampleRate,
                                      sampleRatePropertySize
                                      );
    
    if (result != noErr) NSLog (@"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d", (int) result);
    
    // Obtain the value of the maximum-frames-per-slice from the I/O unit.
    result =    AudioUnitGetProperty (
                                      self.ioUnit,
                                      kAudioUnitProperty_MaximumFramesPerSlice,
                                      kAudioUnitScope_Global,
                                      0,
                                      &framesPerSlice,
                                      &framesPerSlicePropertySize
                                      );
    
    if (result != noErr) NSLog (@"Unable to retrieve the maximum frames per slice property from the I/O unit. Error code: %d", (int) result);
    
    // Set the first Sampler unit's output sample rate.
    result =    AudioUnitSetProperty (
                                      self.samplerUnit,
                                      kAudioUnitProperty_SampleRate,
                                      kAudioUnitScope_Output,
                                      0,
                                      &_graphSampleRate,
                                      sampleRatePropertySize
                                      );
    if (result != noErr) NSLog (@"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d", (int) result);
    
    // Set the first Sampler unit's maximum frames-per-slice.
    result =    AudioUnitSetProperty (
                                      self.samplerUnit,
                                      kAudioUnitProperty_MaximumFramesPerSlice,
                                      kAudioUnitScope_Global,
                                      0,
                                      &framesPerSlice,
                                      framesPerSlicePropertySize
                                      );
    if (result != noErr) NSLog (@"AudioUnitSetProperty (set Sampler unit maximum frames per slice). Error code: %d", (int) result);
    
    // Set the second Sampler unit's output sample rate.
    result =    AudioUnitSetProperty (
                                      self.samplerUnit2,
                                      kAudioUnitProperty_SampleRate,
                                      kAudioUnitScope_Output,
                                      0,
                                      &_graphSampleRate,
                                      sampleRatePropertySize
                                      );
    if (result != noErr) NSLog (@"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d", (int) result);
    
    // Set the second Sampler unit's maximum frames-per-slice.
    result =    AudioUnitSetProperty (
                                      self.samplerUnit2,
                                      kAudioUnitProperty_MaximumFramesPerSlice,
                                      kAudioUnitScope_Global,
                                      0,
                                      &framesPerSlice,
                                      framesPerSlicePropertySize
                                      );
    if (result != noErr) NSLog (@"AudioUnitSetProperty (set Sampler unit maximum frames per slice). Error code: %d", (int) result);
    
    
    if (graph) {
        
        // Initialize the audio processing graph.
        result = AUGraphInitialize (graph);
        if (result != noErr) NSLog (@"Unable to initialze AUGraph object. Error code: %d", (int) result);
        
        // Start the graph
        result = AUGraphStart (graph);
        if (result != noErr) NSLog (@"Unable to start audio processing graph. Error code: %d", (int) result);
        
        // Print out the graph to the console
        CAShow (graph); 
    }
}

- (void) load2SoundFonts {
    
    NSURL *soundFontURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"GUGS_Fluid_v1_44" ofType:@"sf2"]];
    
	if (soundFontURL) {
		NSLog(@"Attempting to load sound font '%@'\n", [soundFontURL description]);
    }
	else {
		NSLog(@"COULD NOT GET SOUND FONT PATH!");
	}
    
    // LOAD FIRST SOUND FONT INSTRUMENT
    OSStatus result = noErr;
    
    // fill out a bank preset data structure
    AUSamplerBankPresetData bpdata;
    bpdata.bankURL  = (__bridge CFURLRef) soundFontURL;
    bpdata.bankMSB  = kAUSampler_DefaultMelodicBankMSB;
    //bpdata.bankLSB  = kAUSampler_DefaultBankLSB;
    bpdata.bankLSB  = 12;
    bpdata.presetID = (UInt8) 88;
    
    
    // set the kAUSamplerProperty_LoadPresetFromBank property
    result = AudioUnitSetProperty(self.samplerUnit,
                                  kAUSamplerProperty_LoadPresetFromBank,
                                  kAudioUnitScope_Global,
                                  0,
                                  &bpdata,
                                  sizeof(bpdata));
    // check for errors
    if (result != noErr) {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result userInfo:nil];
        NSLog(@"Unable to set the preset property on the first Sampler. Error:%@",error);
    }
    
    
    // LOAD SECOND SOUND FONT INSTRUMENT
    bpdata.bankLSB  = kAUSampler_DefaultBankLSB;
    bpdata.presetID = (UInt8) 110;
    
    // set the kAUSamplerProperty_LoadPresetFromBank property
    result = AudioUnitSetProperty(self.samplerUnit2,
                                  kAUSamplerProperty_LoadPresetFromBank,
                                  kAudioUnitScope_Global,
                                  0,
                                  &bpdata,
                                  sizeof(bpdata));
    // check for errors
    if (result != noErr) {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result userInfo:nil];
        NSLog(@"Unable to set the preset property on the second Sampler. Error:%@",error);
    }

}


// Set up the audio session for this app.
- (BOOL) setupAudioSession {
    
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    
    // Specify that this object is the delegate of the audio session, so that
    //    this object's endInterruption method will be invoked when needed.
//deprecated:    [mySession setDelegate: self];
    
    // Assign the Playback category to the audio session. This category supports
    //    audio output with the Ring/Silent switch in the Silent position.
    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayback error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting audio session category."); return NO;}
    
    // Request a desired hardware sample rate.
    self.graphSampleRate = 44100.0;    // Hertz
    
//deprecated:    [mySession setPreferredHardwareSampleRate: self.graphSampleRate error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting preferred hardware sample rate."); return NO;}
    
    // Activate the audio session
    [mySession setActive: YES error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error activating the audio session."); return NO;}
    
    // Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
//deprecated:    self.graphSampleRate = [mySession currentHardwareSampleRate];
    
    return YES;
}


@end
