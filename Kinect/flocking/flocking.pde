//VERSION Kinect : Filet en gif
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
//Librairies Video
import gab.opencv.*;
import processing.video.*;
import java.awt.*;
// Librairie Audio
import processing.sound.*;
//Librairies Kinect
import org.openkinect.freenect.*;
import org.openkinect.processing.*;
//Librairies DeepVision
import ch.bildspur.vision.*;
import ch.bildspur.vision.result.*;
//Autres Librairies
import processing.core.PApplet;
import processing.core.PConstants;
import processing.core.PImage;
import processing.video.Capture;
import gifAnimation.*;

//Intégration de la Kinect
Kinect kinect;
//Paramètres de la Kinect
//--------------------------
float deg;

boolean ir = false;
boolean colorDepth = false;
boolean mirror = false;
//--------------------------

//Initialisation de DeepVision
DeepVision deepVision = new DeepVision(this);
YOLONetwork yolo;
ResultList<ObjectDetectionResult> detections;


//Initialisation des boids
//---------------------------------------
PImage birdSpritesheet;

PVector seekPos = new PVector(600, 400);

ArrayList<Bird> birds = new ArrayList<Bird>();
ArrayList<PVector> obstacles = new ArrayList<PVector>();
ArrayList<ObjectDetectionResult> ppl = new ArrayList<ObjectDetectionResult>();
ArrayList<Sprite> sprites = new ArrayList<Sprite>(); 

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

float BIRD_COHESION_RADIUS = 20f;
float BIRD_COHESION_STRENGTH = 200f;
  
float OBSTACLE_SIZE = 250;
float OBSTACLE_AVOID_STRENGTH = 3000f;

//----------------------------------------------------

//Déclaration d'une variable pour stocker le gif de l'obstacle
Gif obstacleImage;
ArrayList<Gif> obstacleImages;
//Et d'un sprite pour en stocker le sprite
PImage filet;
Sprite fSprite;
int nbetapes;
//Chargement du fichier audio
SoundFile file;



PImage bground;

void setup() {

  //Démarrage de la Kinect
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
  
  //Initialisation de la fenêtre
  //--------------------------------------
  //size(1280, 720);
  fullScreen();

  //-------------------------------------

  //Démarrage de l'outil de vision
  println("creating model...");
  yolo = deepVision.createYOLOv4Tiny();

  println("loading yolo model...");
  yolo.setup();

  // Loading image assets
  //--------------------------------------------
  //load poisson v2 
  birdSpritesheet = loadImage("poisson_frames.png");
  birdSpritesheet.resize(288 ,0);
  //Obstacle
  obstacleImage = new Gif(this, "filet.gif");
  obstacleImage.play();
  filet = loadImage("filet.png");
  obstacleImages = new ArrayList<Gif>();
  //Background
  bground = loadImage("fond.png");
  
  //Démarrage de l'amblance sonore
  file = new SoundFile(this,"Ambiance.WAV");
  file.loop();
  
  //---------------------------------------------
  //Mise en place de la fenêtre
  //Drawing the background
    //Resizing the background image at the size of the window
  bground.resize(width, height);
    //Setting it as background
  background(bground);
  
  //Création d'un sprite pour le filet
  nbetapes = 6;
  filet.resize(300*nbetapes, 0);
  fSprite = new Sprite(filet, nbetapes, 1/12, 300); 
  sprites.add(new Sprite(filet, nbetapes, 1/12, 300));
  
    
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
  background(bground);
  if (kinect.getVideoImage().width == 0) {
    return;
  }

  //Détection des objets
  yolo.setConfidenceThreshold(0.2f);
  detections = yolo.run(kinect.getVideoImage());
  print("\n\ndetecte :", detections, '\n');
  //Sélection des gens
  ArrayList<ObjectDetectionResult> ppl = new ArrayList<ObjectDetectionResult>(); // Réinitialisation de la liste des gens
  for(ObjectDetectionResult detection : detections){
      print(detection);
      if  (detection.getClassName().equals("person")) {
        print("X :", detection.getX(),"   Y:", detection.getY());
        ppl.add(detection); //Make the temporary ArrayList of people
      }
  }
  
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
  clear();
  // Draw the sky
  // NOTE: using alpha to create a motion-blur effect
  //fill(0, 0, 255);
  noFill();
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
  


  
  for (int i=0; i < ppl.size(); i++){
    try{
      //Moving the obstacle
      obstacles.get(i).set(width - (ppl.get(i).getX() + ppl.get(i).getWidth()/2)*4, (ppl.get(i).getY()*4 + ppl.get(i).getHeight()/1.5));
      //Drawing the obstacle
      //With gifs (working)
      image(obstacleImages.get(i),obstacles.get(i).x,obstacles.get(i).y,ppl.get(i).getWidth()*1.2,ppl.get(i).getHeight());
      //With a sprite (untested)
      //fSprite.updateAnimation(secondsElapsed);
      //translate(ppl.get(i).getX(),ppl.get(i).getY());
      //fSprite.draw(false);
      //translate(-ppl.get(i).getX(),-ppl.get(i).getY());
    }
    catch(ArrayIndexOutOfBoundsException aioobe){
      obstacles.get(0).x = 453 + sin(millis() / 1000.0) * 100;
    }
    catch(IndexOutOfBoundsException exc){
      obstacles.add(new PVector(ppl.get(i).getX()*4, ppl.get(i).getY()*4));
      obstacleImages.add(new Gif(this, "filet.gif"));
      obstacleImages.get(i).play();
      image(obstacleImages.get(i),obstacles.get(i).x,obstacles.get(i).y,ppl.get(i).getWidth(),ppl.get(i).getHeight());
    }
  }
// (OLD) Moving one obstacle 
//  try{
//    for(ObjectDetectionResult detection : detections){
//      if  (detection.getClassName().equals("person")) {
//        print("X :", detection.getX(),"   Y:", detection.getY());
        //obstacles.get(0).x = 453 + sin(millis() / 1000.0) * 100; // Example: moves the obstacle in a sine wave pattern
//        obstacles.get(0).set(width-detection.getX()*2, detection.getY()*2); // l'obstacle bouge en fonction de la position de la postition de la camera
//        ppl.add(detection);
//      }
//    }
//  }
//  catch(ArrayIndexOutOfBoundsException aioobe){
//    obstacles.get(0).x = 453 + sin(millis() / 1000.0) * 100;
 // }
  
  //(OLD) Drawing one sprite
  // Draw obstacles
  //fSprite.updateAnimation(secondsElapsed);
  //for (PVector obstacle : obstacles) {
  //  translate(obstacle.x,obstacle.y);
  //  fSprite.draw();
  //  translate(-obstacle.x,-obstacle.y);
  //}
  
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
    
    // Remove one obstacle if there are more obstacles than people
    if (ppl.size() < obstacles.size()) {
    //removing an ovstacle
    obstacles.remove(obstacles.size() -1 );
  }
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
