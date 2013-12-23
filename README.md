synthmixerdemo
==============

The SynthMixDemo application is a Core Audio demonstration example to show loading from a sound font, routing through an effects unit for pitch adjustment and mixing with a multi-channel mixer

Here is a graphical representation in the AU Graph for the SynthMixDemo:

[AU Graph diagram](AUGraph.png)

Features:

- Two instruments loaded for the sound font file and routed to bus 1 and bus 2 inputs on the mixer
- Each input bus independently selectable - either bu1 1, or bus 2, or both
- Instrument 2 (bus 2) goes through an effects unit that has a ui slider for the pitch adjustment.  The pictch bend in this example is a 'semitone' (100 Cents) in either direction. So for the C note - the slider to full right will give a C# note and full left will give a B note.  Note that the full range of adjustment the pitch shift effect allows is two octaves in either direction (+/- 2400 Cents).
- Pitch adjustment on instrument 2 will not effect the note pitch of the notes on instrument 1 as instrument 1 does not go though the effects unit.  This you can demonstrate by playing notes with both bus 1 and 2 on while applying a pitch adjustment 
- Multiple keyborad notes can be played at once

Licence info:

- The GeneralUser GS sound font is from [S. Christian Collins](http://www.schristiancollins.com/generaluser.php) where you will find his current licence


Presentation:

- My slide deck for the Dec 6th, 2013 'Intro To iOS Core Audio' presentation for the Cocoa Conspiracy is here on [Slide Share](http://www.slideshare.net/slideshow/embed_code/29184534)
