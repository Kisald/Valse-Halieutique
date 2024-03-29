//
// Changes since video:
//
// • Added some comments
// • Generalised obstacle-avoidance code
// • Added motion-blur
//
// You are free to modify or use this code however you would like!
//
// • Bird sprite is taken from "[LPC] Birds" by bluecarrot16, commissioned by castelonia: https://opengameart.org/content/lpc-birds
//
import gab.opencv.*;
import processing.video.*;
import java.awt.*;
import org.openkinect.freenect.*;
import org.openkinect.processing.*;

//Intégration de la kinect
Kinect kinect;
//Intégration de la webcam de l'ordi (pour les tests)
Capture video;
//Intégration du module OpenCV
OpenCV opencv;
//Intégration de la classe camera
Camera camera;

//Paramètres de la Kinect
//--------------------------
float deg;

boolean ir = false;
boolean colorDepth = false;
boolean mirror = false;
//--------------------------

PImage birdSpritesheet;

PVector seekPos = new PVector(600, 400);

ArrayList<Bird> birds = new ArrayList<Bird>();
ArrayList<PVector> obstacles = new ArrayList<PVector>();

enum DebugMode { OFF, ALL, SINGLE };
DebugMode debugMode = DebugMode.OFF;

SpatialGrid grid;

/*
 * Bird / flocking tuning parameters
 */
float BIRD_MAX_SPEED = 200;

float BIRD_MOUSE_FOLLOW_STRENGTH = 250;

float BIRD_SEPARATION_RADIUS = 65f;
float BIRD_SEPARATION_STRENGTH = 400f;

float BIRD_ALIGNMENT_RADIUS = 20f;
float BIRD_ALIGNMENT_STRENGTH = 200f;
  
float OBSTACLE_SIZE = 250;
float OBSTACLE_AVOID_STRENGTH = 3000f;
  

void setup() {
  //Démarrage de la Kinect
  //try{
   //--------------------------
   //Résolution de la capture
   size(640, 480);
   kinect = new Kinect(this);
   //Démarre le capteur de profondeur
   kinect.initDepth();
   //Démarre la vidéo
   kinect.initVideo();
   //Démarre le capteur de couleur
   kinect.enableColorDepth(colorDepth);
   //Détecte l'inclinaison de la Kinect
   deg = kinect.getTilt();
   //Lancement de OpenCV
   opencv = new OpenCV(this, 640, 480);
   opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  
   camera = new Camera(kinect, opencv);
  //}
  //catch (IllegalStateException ise){
    //try{
    //print("no kinect found, defaulting to webcam");
    //--------------------------
   //Démarrage de la webcam
   //--------------------------
   //video = new Capture(this, "pipeline:autovideosrc");
   //--------------------------
   //Lancement de OpenCV
   //opencv = new OpenCV(this, 640, 480);
   //opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  
   //video.start();
   //Lancement de l'algo de vision
   //camera = new Camera(video, opencv);
    //}
    //catch(Exception e){
      //print(e.getClass().getName());
      //print("no kinect or webcam found, defaulting to sine movement");
    //}
  //}
  
   
  // Create window
  size(1280, 720, P3D);
  
  // Load bird image asset
  birdSpritesheet = loadImage("poisson.png");
  //birdSpritesheet = loadImage("poisson_anim_test.gif");
    
  // Create a bunch of birds, at random positions
  for (int i=0; i<500; ++i) {
    PVector randomPosition = new PVector(random(0,width), random(0,height));
    Bird bird = new Bird(new Sprite(birdSpritesheet), randomPosition);
    bird.update(random(0,1));
    birds.add(bird);
  }
  
  // Mark one bird arbitrarily (used for single-bird debug view)
  birds.get(0).isBirdZero = true;
  
  // Create an obstacle
  obstacles.add(new PVector(453, 400));
  
  // Init spatial grid
  grid = new SpatialGrid(50);
}


int previousMillis;

void draw() {
  opencv.loadImage(kinect.getVideoImage());
  
  // Reassigning these here to allow them to be modified in Tweak Mode
  BIRD_MAX_SPEED = 200;
  BIRD_MOUSE_FOLLOW_STRENGTH = 100;
  BIRD_SEPARATION_RADIUS = 35;
  BIRD_SEPARATION_STRENGTH = 200;
  BIRD_ALIGNMENT_RADIUS = 75;
  BIRD_ALIGNMENT_STRENGTH = 300;
  OBSTACLE_SIZE = 250;
  OBSTACLE_AVOID_STRENGTH = 3000;
  
  // Calculate delta time since last frame
  int millisElapsed = millis() - previousMillis;
  float secondsElapsed = millisElapsed / 1000f;
  previousMillis = millis();
  
  // Draw the sky
  // NOTE: using alpha to create a motion-blur effect
  fill(145, 189, 203, 30);
  rect(-5,-5,width+5,height+5);
    
  // Populate spatial grid
  grid.empty();
  for (Bird bird : birds) {
    try{
    grid.add(bird, bird.position.x, bird.position.y);
    }
    catch (RuntimeException re){
      //System.out.print(re+", try to find why it doesn't work");
    }
  }
  
  if (debugMode != DebugMode.OFF) {
    grid.debugDraw();
  }
  
  if (mousePressed) {
    seekPos.set(mouseX, mouseY);
  }
  // Update obstacle position
  Rectangle[] faces = opencv.detect();
  print(faces);
  print('\n');
  try{
  //obstacles.get(0).x = 453 + sin(millis() / 1000.0) * 100; // Example: moves the obstacle in a sine wave pattern
  obstacles.get(0).set(faces[0].x*2, faces[0].y*2); // l'obstacle bouge en fonction de la position de la souris
  }
  catch(ArrayIndexOutOfBoundsException aioobe){
    obstacles.get(0).x = 453 + sin(millis() / 1000.0) * 100;
  }
  
  
  // Draw obstacles
  fill(255,200,0);
  noStroke();
  for (PVector obstacle : obstacles) {
    ellipse(obstacle.x, obstacle.y, 100, 100);
  }
  
  // Calculate forces on birds
  for (Bird bird : birds) {
    bird.calculateAcceleration(grid);
  }
  
  // Update + draw every bird
  for (Bird bird : birds) {
    bird.update(secondsElapsed);
    
    // Figure out if we should enable debug drawing for this particular bird
    boolean debugDraw = debugMode == DebugMode.ALL || (debugMode == DebugMode.SINGLE && bird.isBirdZero);
    
    bird.draw(debugDraw);
  }
}

// Cycling debug mode when 'd' key pressed
void keyPressed() {
  if (key == 'd') {
    if      (debugMode == DebugMode.OFF)    { debugMode = DebugMode.SINGLE; }
    else if (debugMode == DebugMode.SINGLE) { debugMode = DebugMode.ALL; }
    else if (debugMode == DebugMode.ALL)    { debugMode = DebugMode.OFF; }
  }
}
