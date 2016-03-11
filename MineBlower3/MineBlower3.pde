/* MineBlower Version 3.0 - by Al Biles
 This game was developed for IGME 571/671, Interactive and Game Audio.
 The purpose is to provide a simple 2D game that requires a lot
 of audio assets that can be developed in the class.
 The types of assets are the usual suspects: Foley and ambient
 sounds, background music, dialog, and interface sounds.
 The version distributed to the class has placeholder sounds that
 should be sufficiently annoying to motivate their replacement
 with student-generated audio.
 
 All the default sounds can be replaced by simply changing the files
 in the Audio folder, but there are opportunities to add additional
 audio triggered by events that are not linked to audio yet.
 The ambient sounds and dialog assets are in this category, as there
 are no placeholder sounds for them.

 However, there are test sound banks for the MultiSound, HorReSeq and
 VertReMix classes, which are triggered by keystrokes handled in the
 keyPressed() handler. In an actual game, these calls would happen
 when notable events occur during gameplay.
 */
 
import ddf.minim.spi.*;   // Set up the audio library
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

Minim minim;              // Need a global object for the audio interface

// Audio assets object contains all audio assets & specialized methods 
Audio aud = new Audio();  // aud.loadAudio will be called in setup()

// Graphics assets object contains all the animations and still frames
Graphics gr = new Graphics();

Sub sub;

int nEels = 9;
Eel [] eels = new Eel [nEels];

int nMines = 6;
Mine [] mines = new Mine [nMines];
final int MAX_RESET = 2;        // Max number of times a mine can be reset

Torpedo t1;                     // Torpedo object
int nTorpedos = 6;              // Can use the torpedo this many times max

Bubbles b1;                     // Does the bubbles

Score sc;                       // Handles score and health

boolean downPressed = false;    // True when DOWN arrow is pressed
boolean leftPressed = false;    // Ditto LEFT arrow
boolean rightPressed = false;   // Ditto RIGHT arrow
                                // No upPressed; sub naturally buoyant
boolean showInstruct = false;

int gameState = 0;              // 0 intro, 1 play, 2 sinking, 3 sunk, 4 won
int winWait = 100;              // Give animations time to finish if won

float backOff = 0.0;            // Background hue offset for Perlin noise

int hRSSongTrk = -1;            // Horizontal Resequencing song track num
int hRSDiaLine = -1;            // Dialog line number (-1 => hasn't started)

int vRMNum = 0;                 // Used to test Vertical Remixing

void setup()
{
  //fullScreen();               // Make window full screen
  size(1400, 1000);             // This size works well for # of eels, etc.
  frameRate(30);                // Slow it down a bit
  imageMode(CENTER);
  colorMode(HSB);
  background(129, 60, 220);

  gr.loadGraphics();            // Load up the graphics assets
  minim = new Minim(this);      // Set up the audio interface
  aud.loadAudio();              // Load up the audio assets

  sub = new Sub();              // Create the submarine

  for (int i = 0; i < nEels; i++)   // Create all the eels
    eels[i] = new Eel();
  for (int i = 0; i < nMines; i++)  // Create all the mines
    mines[i] = new Mine();
  t1 = new Torpedo(nTorpedos);  // Use the same torpedo multiple times
  b1 = new Bubbles();

  sc = new Score();

  //aud.backMus.loop();         // Fire up background music (replaced by xFade)
  aud.bkgdMus.xFade(0);         // Crossfade into background Menu music to start
}

void draw()
{
  if (gameState == 0)           // Game state 0: Show instructions
  {
    if (showInstruct)
      sc.instructions();
    else
      sc.splashScreen();
  }
  else if (gameState == 3)      // Game state 3: Game over, sub sunk
  {
    sc.youSankScreen();
  }
  else if (gameState == 4 && winWait <= 0) // State 4: Game over, player won!
  {
    sc.youWonScreen();
  }
  else // gameState 1: still in the game, or gameState 4: waiting to win
  {
    if (gameState == 4)               // Game state 4: Counting down to win
    {
      winWait--;
      if (winWait == 0)
      {
        aud.bkgdMus.xFade(2);
        aud.safePlay(aud.winSnd);     // Trigger win sound only once
      }
    }
    // else Game state 1: Do next frame

    // Update for game state 1 ////////////////////////////////////////////
    
    b1.move();                        // Animate the bubbles

    // Maybe create an ambient sonar ping
    aud.maybePing();
          
    aud.hRSSong.update();             // Update Horizontal Resequencing
    aud.hRSDialog.update();           // objects

    for (int i = 0; i < nEels; i++)   // Animate all the eels
      eels[i].move();

    for (int i = 0; i < nMines; i++)  // Animate all the mines
      mines[i].move();

    t1.move();                        // Move the torpedo

    sub.move();                       // Move the sub

    // Test the MultiSound class with ambient sub sound at sub's x coord
    if (random(1000.0) < 10.0)
      aud.ambSub.trigRand(sub.loc.x);
    //if (random(1000.0) < 10.0)      // Trigger sounds sequentially
    //  aud.ambSub.trigSeq(random(width));
    
    if (t1.running())                 // See if the torpedo hit anything
        checkTorpedo();

    if (! sub.sunk())                 // Check mines for sub touches
      checkMines();

    for (int i = 0; i < nEels; i++)   // Check eels for sub touches
      if (sub.eelTouch(eels[i]))
      {
        sub.zap();                    // If touching, zap 'em both
        eels[i].zap();
      }

    // Display for game state 1 //////////////////////////////////////////
    
    backOff += 0.02;                  // Subtle changes in background hue
    float hue = noise(backOff) * 20 + 122;  // ...using Perlin noise
    background(hue, 60, 220);

    sc.display();                     // Display the score

    b1.display();                     // Display the bubbles

    for (int i = 0; i < nMines; i++)  // Display all the fading mines
      if (mines[i].inactive())
        mines[i].display();

    for (int i = 0; i < nEels; i++)   // Display all the grounded eels
      if (eels[i].grounded())
        eels[i].display();

    t1.display();                     // Display the torpedo
    sub.display();                    // Display the sub

    for (int i = 0; i < nMines; i++)  // Display all the active mines
      if (! mines[i].inactive())
        mines[i].display();

    for (int i = 0; i < nEels; i++)   // Display all the active eels
      if (! eels[i].grounded())
        eels[i].display();
  }
}

// See if the torpedo hit anything and act accordingly
void checkTorpedo()
{
  for (int i = 0; i < nEels; i++)   // Check all eels for torpedo touches
  {
    if (eels[i].touch(t1.nose()))
    {
      eels[i].ground();
    }
  }

  boolean hitMine = false;          // Check mines for torpedo touches
  int k = 0;                        // until one is hit or missed them all
  while (! hitMine && k < nMines)
  {
    if (mines[k].touch(t1.nose()))
    {
      mines[k].explode();
      t1.explode();
      sub.blast(mines[k].mineLoc());
      sc.detonatePoints();          // Score points for hitting a mine
      hitMine = true;
    }
    else
      k++;                     // Haven't hit one yet, so check next one
  }
}

// Check all the mines to see if the sub hit one
void checkMines()
{
  boolean touchMine = false;         // Check mines for sub touches
  int i = 0;                         // Until one is hit or missed them all
  while (! touchMine && i < nMines)
  {
    if (mines[i].touch(sub.arm.grab()))
    {
      // If arm touch is careful enough and sub not sinking...
      if (sub.careful() && sub.subState <= 1)
      {
        mines[i].disarm();           // Disarm it and score points
        touchMine = true;
      }
      else
      {
        mines[i].explode();          // Too hard or sinking, so blow it up
        sub.blast(mines[i].mineLoc());
        sc.blastPoints();
        touchMine = true;
      }
    }
    else if (sub.mineTouch(mines[i])) // Any sub touch blows it up
    {
      mines[i].explode();
      sub.blast(mines[i].mineLoc());
      sc.blastPoints();
      touchMine = true;
    }
    else
      i++;                     // Sub missed this mine, so check next one
  }
}

/**** Handlers ******************************************************/

// Handle all key presses, even chords
// DOWN, LEFT & RIGHT keys are "continuous controllers" that apply
// thrust in the appropritate direction as long as the key remains
// pressed, hence the use of booleans.  The '?' key behaves the same
// way, displaying the detailed instructions on the splash screen as
// long as the key remains pressed.  The rest of the keys trigger
// actions once when first pressed.
void keyPressed()
{
  if (keyCode == DOWN)
    downPressed = true;
  if (keyCode == LEFT)
    leftPressed = true;
  if (keyCode == RIGHT)
    rightPressed = true;
  if (key == 'f')
    sub.fireTorp(t1);
  if (key == '?' && gameState == 0)
    showInstruct = true;
  if (key == 's' && gameState < 2)
  {
    gameState = 1;
    aud.bkgdMus.xFade(1);
  }
  if (key == 'q')
  {
    aud.pauseAll();       // Pause or stop all the sounds
    exit();
  }
  
  // The remaining keys are used to test Audio classes and are not
  // really part of the game.
  if (key == 'm')         // Test the HorReSeq class on looping music
  {
    hRSSongTrk++;         // Schedule transition to NEXT track
    if (hRSSongTrk > 6)   // Start over after song is done
    {
      hRSSongTrk = -1;
      aud.hRSSong.reset();
    }
    aud.hRSSong.trigTrans(hRSSongTrk);  // Trigger actual transition
  }
  if (key == 'M')         // Test HorReSeq class on looping music
  {
    hRSSongTrk--;         // Schedule transition to PREVIOUS track
    aud.hRSSong.trigTrans(hRSSongTrk);
  }
  if (key == 'd')         // Test HorReSeq class on non-looping dialog
  {
    hRSDiaLine++;         // Schedule transition to NEXT track
    if (hRSDiaLine > 5)
    {
      hRSDiaLine = -1;
      aud.hRSDialog.reset();
    }
    aud.hRSDialog.trigTrans(hRSDiaLine);
  }
  if (key == 'D')         // Test HorReSeq class on non-looping dialog
  {
    hRSDiaLine--;         // Schedule transition to PREVIOUS track
    aud.hRSDialog.trigTrans(hRSDiaLine);
  }
  
  // Test VertReMix class with 4 trumpet phrases, harmonized in 3rds
  // Adds tracks one at a time until all playing, then silenes them
  // one at a time until all silent, then repeats.
  if (key == 'v')
  {
    int vRMtrk = vRMNum % 4;    // Cycle through 4 tracks to pot...
    int vRMdir = vRMNum / 4;    // ... either up or down
    if (vRMdir == 0)
      aud.vRMHarmo.potUp(vRMtrk, -45.0);  // Not very loud
    else
      aud.vRMHarmo.potDn(vRMtrk);
    //println(vRMNum, vRMtrk, vRMdir);
    vRMNum = (vRMNum + 1) % 8;  // cycle to next combination for next time
  }
}

// Detect all key releases and reset booleans
void keyReleased()
{
  if (keyCode == DOWN)
  {
    downPressed = false;
    aud.diveSnd.pause();  // Pause the sound immediately
  }
  if (keyCode == LEFT)
  {
    leftPressed = false;
    aud.reverseSnd.pause();
  }
  if (keyCode == RIGHT)
  {
    rightPressed = false;
    aud.forwardSnd.pause();
  }
  if (key == '?')
    showInstruct = false;
}

void stop()            // Override default stop() method to clean up audio
{
  aud.closeAll();      // Close up all the sounds
  minim.stop();        // Close up minim itself
  super.stop();        // Now call the default stop()
}