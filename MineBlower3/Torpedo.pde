/* Torpedo class - by Al Biles
 Handles Torpedo stuff
 */
class Torpedo
{
  PVector loc = new PVector(0, 0);  // Location of torpedo center, set in fire()
  PVector t1 = new PVector(50, -7); // 3 points for detonator triangle at front
  PVector t2 = new PVector(50, 5);  // All three are relative to loc
  PVector t3 = new PVector(60, -1); // 3rd point is tip of detonator (nose cone)
  PVector locInSub = new PVector(60, 30);

  PVector d = new PVector(0, 0);    // delta per frame (d.x, d.y), set in fire()

  // acceleration a has drag in x direction, buoyancy in y direction (always < 0)
  PVector a = new PVector(-0.020, -0.03); // Water exerts drag, wants to float

  float launchV = 13;       // Launch speed in x direction, always to right
  int tState = 0;           // 0 prelaunch, 1 launched, 2 spent, 3 all gone
  int nTorps;               // Number of torpedos remaining (set in constructor)
  int waitSome = 0;

  Torpedo(int n)            // Pass in number of torpedos
  {
    nTorps = n;
  }

  void reset()
  {
    d.set(0, 0);            // Start it over not moving
  }

  void fire(PVector subLoc) // Called when 'f' hit by user
  {
    if (tState == 0)        // Can only fire from state 0
    {
      loc.set(PVector.add(subLoc, locInSub));
      d.set(launchV, sub.d.y*0.5); // launch speed, half of Sub's vertical speed
      tState = 1;
      aud.panPlay(aud.torpRunSnd, subLoc.x, launchV);
    }
    else if (tState == 3)   // No more torpedos, state is a sink
      aud.safePlay (aud.noMoreSnd, subLoc.x);
  }

  boolean running()
  {
    return tState == 1;
  }

  void explode()            // Called when torpedo hits a mine
  {
    if (tState == 1)        // Can only explode if currently running
    {
      tState = 2;           // Torpedo is gone
      waitSome = 30;        // Give animations a chance to finish
      aud.torpRunSnd.pause(); // Torpedo is no longer running
    }
  }

  // Primary move method
  void move()
  {
    if (tState == 0)        // Prelaunch state
    {
      if (nTorps <= 0)      // Out of torpedos
        tState = 3;         // Go to no more torpedos state
    }
    else if (tState == 1)   // Launched and running
    {
      if (loc.x > width + 100) // Torpedo beyond window, so give up...
      {
        tState = 2;         // ...and retire the torpedo
        waitSome = 30;      // Give animations a chance to finish
        aud.fadeOut(aud.torpRunSnd);
      }
      else                  // Torpedo still running, so stay in this state
      {
        d.add(a);           // Apply drag and buoyancy to delta
        loc.add(d);         // Move the torpedo
      }
    }
    else if (tState == 2)   // Torpedo's run is over, waiting to reset
    {
      waitSome--;
      if (waitSome <= 0)    // Animations should have finished
      {
        nTorps--;           // Count the torpedo
        reset();            // Reinitialize torpedo's attributes
        tState = 0;         // and reset to initial state
      }
    }
    //else tState == 3 => No more torpedos, state is a sink
  }

  PVector nose()            // Return the tip of the nose cone
  {
    return PVector.add(loc, t3);
  }
  
  void display()
  {
    if (tState == 1)   // Only display if torpedo is launched and running
    {
      image(gr.tImage, loc.x, loc.y); // Torpedo body
      strokeWeight(2);                // Detonator in nose
      stroke(0);
      fill(75, 255, 255);
      triangle (loc.x+t1.x, loc.y+t1.y, loc.x+t2.x, loc.y+t2.y,
                loc.x+t3.x, loc.y+t3.y);
    }
  }
}