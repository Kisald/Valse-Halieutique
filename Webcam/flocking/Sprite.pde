public class Sprite {
  
  PImage spriteSheet;
  
  // Hardcoded values to match the bird spritesheet
  // nombre de frames d'animation
  //Oiseau :
  //int frameCount = 3;
  //Poisson :
  int frameCount = 3;
  //durée de cchaque étape de l'animation (secondes)
  float frameDurationSeconds = 0.1;
  // largeur d'une frame sur le spritesheet (pixels)
  //Oiseau :
  int frameWidth = 32;
  //Poisson :
  //int frameWidth = 782;
  //Poisson v2 :
  //int frameWidth = 128;
  
  float secondsSinceAnimationStarted = 0;
  
  public Sprite(PImage spriteSheet) {
    this.spriteSheet = spriteSheet;
  }
  
  
  void updateAnimation(float secondsElapsed) {
    secondsSinceAnimationStarted += secondsElapsed;
  }
  
  void draw() {
    // Figure out which frame we should be drawing currently
    int currentFrameIndex = (int)(secondsSinceAnimationStarted / frameDurationSeconds);
    currentFrameIndex %= frameCount;
    
    drawAnimationFrame(currentFrameIndex);
  }
  
  void drawAnimationFrame(int frameIndex) {
    // Crop out and draw the appropriate part of the image
    imageMode(CENTER);
    
    int frameStartX = frameWidth*frameIndex;
    
    image(
        spriteSheet,
        0, 0,
        frameWidth, frameWidth,                // Size to draw
        frameStartX, 0,                        // Top-left of section to draw
        frameStartX + frameWidth, frameWidth   // Bottom-right
    );
  }
  
} 
