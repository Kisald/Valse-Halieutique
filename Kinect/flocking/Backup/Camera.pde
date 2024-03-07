
class Camera{

public Camera(Kinect kinect, OpenCV opencv) {
  //Lancement d'OpenCV avec la webcam(video) ou la kinect (kinect.getVideoImage())
  opencv.loadImage(kinect.getVideoImage());
}

public Camera(Capture video, OpenCV opencv) {
  //Lancement d'OpenCV avec la webcam(video) ou la kinect (kinect.getVideoImage())
  opencv.loadImage(video);
}
  
public void getVideo(){
  //Le flux vidéo qui sera affiché : Webcam (video) ou kinect (kinect.getVideoImage())
  //image(video, 0, 0 );
  image(kinect.getVideoImage(), 0, 0 );

  noFill();
  stroke(0, 255, 0);
  strokeWeight(3);
  //Faces = liste des visages
  //opencv.detect() renvoie une liste de visages
  Rectangle[] faces = opencv.detect();
  println(faces.length);

  for (int i = 0; i < faces.length; i++) {
    //rectangle.x = coordonnées en x du rectangle
    //rectangle.y = coordonnées en y du rectangle
    //rectangle.width = largeur du rectangle
    //rectangle.height = hauteur du rectangle
    println(faces[i].x + "," + faces[i].y);
    rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
  }
}
 
public Rectangle[] GetFaces(){

  //opencv.detect() renvoie une liste de visages
  Rectangle[] faces = opencv.detect();
  return faces;
}

//Lecture d'un flux vidéo
//------------------------------
//Caméra
//void captureEvent(Capture c) {
  //c.read();
//}
//------------------------------
}
