public class Sprite {
  
  PImage spriteSheet;
  
  // Hardcoded values to match the bird spritesheet
  // nombre de frames d'animation
  //Oiseau :
  int frameCount;
  //durée de cchaque étape de l'animation (secondes)
  float frameDurationSeconds;
  // largeur d'une frame sur le spritesheet (pixels)
  //Oiseau :
  int frameWidth;
  
  float secondsSinceAnimationStarted = 0;
  
  public Sprite(PImage spriteSheet) {
    //this.spriteSheet = spriteSheet;
    this(spriteSheet, 9, 0.2, 32);
  }
  
   public Sprite(PImage spriteSheet, int frames, float duration, int fwidth) {
    this.spriteSheet = spriteSheet;
    this.frameCount = frames;
    this.frameDurationSeconds = duration;
    this.frameWidth = fwidth;
  }
  
  //public Sprite(PImage spriteSheet, int frame, int fwidth) {
  //  this(spriteSheet, frame, 0.1, fwidth);
  //}
  
  void updateAnimation(float secondsElapsed) {
    secondsSinceAnimationStarted += secondsElapsed;
  }
  
  void draw(boolean perturbated) {
    // Figure out which frame we should be drawing currently
    int currentFrameIndex = (int)(secondsSinceAnimationStarted / frameDurationSeconds);
    currentFrameIndex %= frameCount;
    
    drawAnimationFrame(currentFrameIndex, perturbated);
  }
  
  void drawAnimationFrame(int frameIndex, boolean perturbated) {
    // Crop out and draw the appropriate part of the image
    imageMode(CENTER);
    
    int frameStartX = frameWidth*frameIndex;
    if (!perturbated) {
      tint(0,0,0);
    }
    image(
        spriteSheet,
        0, 0,
        frameWidth, frameWidth,                // Size to draw
        frameStartX, 0,                        // Top-left of section to draw
        frameStartX + frameWidth, frameWidth   // Bottom-right
    );
    noTint();
  }
  
} 
