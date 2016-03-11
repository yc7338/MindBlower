/* Audio class - by Al Biles
 Declares and loads all audio assets.
 A global Audio object should be created in setup().
 Also provides methods that make life easier for playing or triggering
 sounds from the other classes.
 
 Methods:
 safePlay() - Plays a sound only if the sound isn't already playing.
 safePlay() has an overload that plays the sound at a given pan loc.
 triggerWhere() - Triggers an AudioSample at a given pan location.
 tooFarLeft(), Right, Up & Down - Each call safePlay() with the appropriate
 sound when the sub goes too far off the screen in that direction.

 panPlay() - specialized method for playing the torpedo running sound
 by panning it with the torpedo from the sub's location on launch
 to the right edge of the window. From there a call to fadeOut() will
 fade the sound out, as if it is moving away in the distance.
 
 This class uses the PingTone, RingFile, MultiSound, CrossFade, HorReSeq
 & VerReMix classes, which are defined in separate tabs.
 These classes depend on patches to the audio hardware that are set up
 here, but are otherwise independent.  However, the actual objects
 instantiated from these classes are set up here in the Audio class.
 The philosphy is to hide as many of the details as possible here and
 require the non-audio classes and the main tab to know only what's
 needed to interact with the audio objects during game play.
 
 To set up an object from the CrossFade, MultiSound, HorReSeq, VertReMix
 or RingFile classes:
 1) Declare an object as a (global) attribute below
 2) Create the object in the constructor below and...
 3) ...Call any additional setup methods for objects of that class
 4) Add a pauseAll() method call to the pauseAll() method below
 5) Add a closeAll() method call to the closeAll() method below
 6) Insert calls to transition or other methods as needed in other tabs
 */
 
class Audio
{
  AudioPlayer forwardSnd;   // AudioPlayer is for longer sounds
  AudioPlayer reverseSnd;
  AudioPlayer diveSnd;
  AudioSample bangSnd;      // AudioSample is for short, frequent sounds
  AudioSample disarmSnd;
  AudioSample zapSnd;
  AudioSample groundSnd;
  AudioPlayer noMoreSnd;
  AudioPlayer fireSnd;
  //AudioPlayer backMus;    // Replaced by the CrossFade object below
  AudioPlayer tooLeftSnd;
  AudioPlayer tooRightSnd;
  AudioPlayer tooUpSnd;
  AudioPlayer tooDownSnd;
  AudioPlayer sinkingSnd;
  AudioPlayer sunkSnd;
  AudioPlayer winSnd;
  AudioPlayer bubbleSnd;
  AudioPlayer torpRunSnd;

  AudioOutput out;    // Used for PingTone, RingFile and any other UGen chain

  int pingCount = 0;  // Counter in maybePing() to keep random pings at bay
  
  CrossFade bkgdMus;  // CrossFade object for background music tunes

  MultiSound ambSub;  // MultiSound object: Ambient sub sounds

  HorReSeq hRSSong;   // Looping horizontal resequencing object
  HorReSeq hRSDialog; // Non-looping horizontal resequencing object
  
  VertReMix vRMHarmo; // Vertical remixing object
  
  RingFile rF1;       // Declare ring modulator object from RingFile class

  void loadAudio()    // Called in setup()
  {
    forwardSnd = minim.loadFile("Audio/Forward.mp3", 512);
    forwardSnd.setGain(-8.0);     // Turn it down
    reverseSnd = minim.loadFile("Audio/Reverse.mp3", 512);
    reverseSnd.setGain(-8.0);
    diveSnd = minim.loadFile("Audio/Dive.mp3", 512);
    diveSnd.setGain(-8.0);
    bangSnd = minim.loadSample("Audio/Bang.mp3", 512);
    disarmSnd = minim.loadSample("Audio/Disarm.mp3", 512);
    zapSnd = minim.loadSample("Audio/Zap.mp3", 512);
    zapSnd.setGain(-8.0);
    groundSnd = minim.loadSample("Audio/Grounded.mp3", 512);
    noMoreSnd = minim.loadFile("Audio/NoMore.mp3", 512);
    fireSnd = minim.loadFile("Audio/Fire.mp3", 512);
    //backMus = minim.loadFile("Audio/Luie.mp3", 512);
    //backMus.setGain(-24.0);
    tooLeftSnd = minim.loadFile("Audio/TooLeft.mp3", 512);
    tooRightSnd = minim.loadFile("Audio/TooRight.mp3", 512);
    tooUpSnd = minim.loadFile("Audio/TooUp.mp3", 512);
    tooDownSnd = minim.loadFile("Audio/TooDown.mp3", 512);
    sinkingSnd = minim.loadFile("Audio/Sinking.mp3", 512);
    sunkSnd = minim.loadFile("Audio/Sunk.mp3", 512);
    winSnd = minim.loadFile("Audio/Win.mp3", 512);
    bubbleSnd = minim.loadFile("Audio/Bubbles.mp3", 512);
    bubbleSnd.setGain(-12.0);
    torpRunSnd = minim.loadFile("Audio/TorpedoRun.mp3", 512);
    //torpRun.setGain(-12.0);          // Keep it loud

    out = minim.getLineOut();          // Used for PingTone
    
    bkgdMus = new CrossFade("Audio/JukeBox/Outside", 5);

    ambSub = new MultiSound("Audio/AmbientSub/Snd", 4);
    ambSub.setGain(-12.0);             // Make all the sounds quieter

    hRSSong = new HorReSeq("Audio/TDSong/TaxiD", 6, true); // looping
    hRSSong.setGain(-12.0);            // Make all the sounds quieter
    
    hRSDialog = new HorReSeq("Audio/Dialog1/Line", 5, false); // non-looping
    
    vRMHarmo = new VertReMix("Audio/Layers/Layer", 4);
    vRMHarmo.startAll();
    
    // Set up the ring modulator with the file as carrier, modulating
    // frequency of 500 Hz, modulating amplitude (depth) of 2.0.
    rF1 = new RingFile("Audio/WhatWasThat.mp3", 500, 2.0);
  }

  void pauseAll()  // Called when user types 'q' to quit
  {    
    forwardSnd.pause();
    reverseSnd.pause();
    diveSnd.pause();
    bangSnd.stop();
    disarmSnd.stop();
    zapSnd.stop();
    groundSnd.stop();
    noMoreSnd.pause();
    fireSnd.pause();
    //backMus.pause();
    tooLeftSnd.pause();
    tooRightSnd.pause();
    tooUpSnd.pause();
    tooDownSnd.pause();
    sinkingSnd.pause();
    sunkSnd.pause();
    winSnd.pause();
    bubbleSnd.pause();
    torpRunSnd.pause();
    out.mute();
    ambSub.pauseAll();
    hRSSong.pauseAll();
    hRSDialog.pauseAll();
    vRMHarmo.pauseAll();
  }

  void closeAll()  // Called from stop() in main
  {
    forwardSnd.close();
    reverseSnd.close();
    diveSnd.close();
    bangSnd.close();
    disarmSnd.close();
    zapSnd.close();
    groundSnd.close();
    noMoreSnd.close();
    fireSnd.close();
    //backMus.close();
    tooLeftSnd.close();
    tooRightSnd.close();
    tooUpSnd.close();
    tooDownSnd.close();
    sinkingSnd.close();
    sunkSnd.close();
    winSnd.close();
    bubbleSnd.close();
    torpRunSnd.close();
    ambSub.closeAll();
    hRSSong.closeAll();
    hRSDialog.closeAll();
    vRMHarmo.closeAll();
  }

/******* Simple sound activation methods ***********************/

  // Play sound only if it's not already playing
  void safePlay (AudioPlayer snd)
  {
    if (! snd.isPlaying())
    {
      snd.rewind();
      snd.play();
    }
  }

  // Overload to play sound at loc x mapped to L/R pan
  void safePlay (AudioPlayer snd, float x)
  {
    if (! snd.isPlaying())
    {
      snd.rewind();
      snd.setPan(map(x, 0, width, -1.0, 1.0));
      snd.play();
    }
  }

  // Trigger sample at pan value mapped from x location
  void triggerWhere(AudioSample snd, float x)
  {
    snd.setPan(map(x, 0, width, -1.0, 1.0));
    snd.trigger();
  }

  // Triggered when sub moves too far out of the window
  void tooFarLeft()  // Plays when sub too far left out of the window
  {
    safePlay(tooLeftSnd, 0.0);      // Pan hard left
  }

  void tooFarRight()
  {
    safePlay(tooRightSnd, width);   // Pan hard right
  }

  void tooFarUp()
  {
    safePlay(tooUpSnd);
  }

  void tooFarDown()
  {
    safePlay(tooDownSnd);
  }
  
  /****** maybePing() ***************************************************/
  
  // Maybe generate an ambient ping - Creates new PingTone object each time
  // it decides to start a ping echo chain so that more than one can play
  // at the same time. Uses class attribute pingCount. Called from Main tab.
  void maybePing()
  {
    if (pingCount > 0)                // Too soon since previous ping
      pingCount--;
    else if (random (0, 100) < 1.0)   // 1% chance each frame
    {
      pingCount = 50;                 // Wait at least 50 frames
      PingTone pt = new PingTone();   // Create a PingTone Instrument
      pt.noteOn();                    // Send it a noteOn signal
    }
  }
  
  /****** Torpedo running sound methods *******************************/
  
  // Plays snd beginning at pan location x, panning in real time
  // toward right window edge, given initial torpedo speed launchV
  void panPlay(AudioPlayer snd, float x, float launchV)
  {
    if (! snd.isPlaying())
    {
      float panStart = map(x, 0, width, -1.0, 1.0);  // Where to start pan
      int panTime = figurePanTime(x, launchV);  // How long pan will take
      snd.rewind();
      snd.setGain(0.0);
      snd.shiftPan(panStart, 1.0, panTime);     // Start panning the sound
      snd.play();                               // Start playing the sound
    }
  }

  // Figures how many milliseconds it will take for torpedo to move from
  // x location to right window edge, given initial speed initV
  int figurePanTime(float x, float initV)
  {
    float where = x;       // Starting at x, move where
    float velX = initV;    // Initial velocity
    int nPanFrames = 0;    // Count number of frames
    while (where < width)
    {
      where += velX;       // move to next x location
      velX += t1.a.x;      // Apply drag effect
      nPanFrames++;        // Count the frame
    }
    return int (nPanFrames * 1000 / frameRate);  // Convert to milliseconds
  }

  // Fade out snd over the rest of its playing
  void fadeOut(AudioPlayer snd)
  {
    if (snd.isPlaying())
    {
      int fadeTime = snd.length() - snd.position();    // How much left
      snd.shiftGain(snd.getGain(), -15.0, fadeTime);   // Fade that long
    }
  }
}