/* Vertical Remixing class - by Al Biles
 Implements simple vertical remixing, with an array of sounds (tracks)
 where each track can be potted up or down independently.
 Could be used to implement a music piece, where different tracks
 are potted up or down based on game events.  Could also be used to
 implement layers of ambient sounds.
 
 Note: If the tracks need to remain synchronized (as for a tune),
 the files must all be exactly the same length and should be synched
 at the beginning, since they will all be looping in parallel.
 
 Methods:
 startAll() should be called once, likely in setup(). It starts looping
 all the tracks at once at an inaudible level.
 potUp() will pot up level of indicated track to indicated level.
 potDn() will pot down the indicated track to an inaudible level.
 */

class VertReMix
{
  AudioPlayer [] snds;  // The sounds (tracks) in to be mixed
  float [] leng;        // Length of each track in ms (not used)

  // Constructor needs path & number of sound files
  // The dirPath should be a folder name followed by a slash followed
  // by a root file name.  For example if you have Snd0.mp3, Snd1.mp3
  // and Snd2.mp3 in the the Layers folder, you would pass in
  // "Layers/Snd" as the value of dirPath, and nSnds would be 3.
  VertReMix(String dirPath, int nSnds)
  {
    snds = new AudioPlayer [nSnds];
    leng = new float [nSnds];

    for (int i = 0; i < snds.length; i++)
    {
      String filePath = dirPath + i + ".mp3";
      snds[i] = minim.loadFile(filePath, 512);
      leng[i] = snds[i].length();
      //println(filePath, leng[i]);
    }
  }
  
  // Start them all looping together at an inaudible level
  void startAll()
  {
    for (int i = 0; i < snds.length; i++)
    {
      snds[i].setGain(-70.0);
      snds[i].loop();
    }
  }

  // Quickly pot up the volume of indicated track to indicated level
  void potUp(int trk, float newLevel)
  {
    float currLevel = snds[trk].getGain();
    snds[trk].shiftGain(currLevel, newLevel, 100);
  }

  // Pot down the volume on the indicated track to inaudible level
  void potDn(int trk)
  {
    float currLevel = snds[trk].getGain();
    snds[trk].shiftGain(currLevel, -70.0, 100);
  }

  // Called by aud.pauseAll()
  void pauseAll()
  {
    for (int i = 0; i < snds.length; i++)
      snds[i].pause();
  }

  // Called by aud.closeAll()
  void closeAll()
  {
    for (int i = 0; i < snds.length; i++)
      snds[i].close();
  }
}