synthmixerdemo
==============

The SynthMixDemo application is a Core Audio demonstration example to show loading from a sound font, effects unit for pitch adjustment and multi-channel mixer

Here is a graphical representation in the AU Graph for the SynthMixDemo:

[AU Graph diagram](AUGraph.png)

Features:

- Two instruments loaded for the sound font file and routed to bus 1 and bus 2 inputs on the mixer
- Each input bus independently selectable - either bu1 1, or bus 2, or both
- Instrument 2 (Bus 2) goes through an effects unit that has a slider for the a pitch adjustment.  The pictch bend in this example is a step (100 Cents) in either direction. So for the C note - the slide full right will give a C# note and full left will give a B note.  Note that the range of adjustment with the pitch shift effect allows is two octaves in either direction (+/- 2400 Cents).
- Pitch adjustment on instrument 2 will not effect the note pitch of the notes on instrument 1 when they are both playing at the same time 
- Multiple keyborad notes can be played at once

licence info:

- The GeneralUser GS sound font is from [S. Christian Collins](http://www.schristiancollins.com/generaluser.php) where you will find his current licence
