///////////////////////////////////////////////////////////////////////
//
//  Ray Tracing Shell
//
///////////////////////////////////////////////////////////////////////
import java.util.*;

int screen_width = 600;
int screen_height = 600;

// global matrix values
PMatrix3D global_mat;
float[] gmat = new float[16];  // global matrix values

// Some initializations for the scene.

void setup() {
  size (600, 600, P3D);  // use P3D environment so that matrix commands work properly
  noStroke();
  colorMode (RGB, 1.0);
  background (0, 0, 0);
  
  //readying objects
  instantiate();
  
  // grab the global matrix values (to use later when drawing pixels)
  PMatrix3D global_mat = (PMatrix3D) getMatrix();
  global_mat.get(gmat);  
  printMatrix();
  resetMatrix();    // you may want to reset the matrix here
  println("Matrix reset");
  printMatrix();
  RTracer = new raytracer();
  RTracer.reset();
  interpreter("t08.cli");
}

// Press key 1 to 9 and 0 to run different test cases.

void keyPressed() {
  switch(key) {
    case '1':  RTracer.reset();interpreter("t01.cli"); break;
    case '2':  RTracer.reset();interpreter("t02.cli"); break;
    case '3':  RTracer.reset();interpreter("t03.cli"); break;
    case '4':  RTracer.reset();interpreter("t04.cli"); break;
    case '5':  RTracer.reset();interpreter("t05.cli"); break;
    case '6':  RTracer.reset();interpreter("t06.cli"); break;
    case '7':  RTracer.reset();interpreter("t07.cli"); break;
    case '8':  RTracer.reset();interpreter("t08.cli"); break;
    case '9':  RTracer.reset();interpreter("t09.cli"); break;
    case '0':  RTracer.reset();interpreter("t10.cli"); break;
    case 'q':  exit(); break;
  }
}

//  Parser core. It parses the CLI file and processes it based on each 
//  token. Only "color", "rect", and "write" tokens are implemented. 
//  You should start from here and add more functionalities for your
//  ray tracer.
//
//  Note: Function "splitToken()" is only available in processing 1.25 or higher.

void interpreter(String filename) {
  
  String str[] = loadStrings(filename);
  if (str == null) printlg("Error! Failed to read the file.");
  for (int i=0; i < str.length; i++) {
    
    String[] token = splitTokens(str[i], " "); // Get a line and parse tokens.
    
    if (token.length == 0) continue; // Skip blank line.
    if(token[0].equals("rays_per_pixel")){
      RTracer.setRaysPerPixel(int(token[1]));
    }  
    else if(token[0].equals("lens")){
      RTracer.setLens(float(token[1]), float(token[2]));
    }
    else if (token[0].equals("fov")) {
      RTracer.setFov(float(token[1]));
    }
    else if (token[0].equals("background")) {
      RTracer.setBg(float(token[1]),float(token[2]),float(token[3]));
    }
    else if (token[0].equals("point_light")) {
      RTracer.addLight(new PointLight(float(token[1]),float(token[2]),float(token[3]),float(token[4]),float(token[5]),float(token[6])));
    }
    else if (token[0].equals("disk_light")) {
      RTracer.addLight(new DiskLight(float(token[1]),float(token[2]),float(token[3]), //x,y,z
        float(token[4]), //rad
        float(token[5]),float(token[6]), float(token[7]), //normal
        float(token[8]),float(token[9]), float(token[10]) //r,g,b
        )); 
     }
    else if(token[0].equals("caustic_photons")){
      RTracer.photonMapping= true;
      RTracer.photonType = photonTypes.CAUSTIC;
      RTracer.photonCount = int(token[1]);
      RTracer.numPhotonsNearby = int(token[2]);
      RTracer.maxDistToSearch = float(token[3]);
    }
    else if(token[0].equals("diffuse_photons")){
      RTracer.photonMapping= true;
      RTracer.photonType = photonTypes.DIFFUSIVE;
      RTracer.photonCount = int(token[1]);
      RTracer.numPhotonsNearby = int(token[2]);
      RTracer.maxDistToSearch = float(token[3]);
    }
    else if (token[0].equals("diffuse")) {
      RTracer.addMaterial(float(token[1]),float(token[2]),float(token[3]),float(token[4]),float(token[5]),float(token[6]), 0); //k_relf is 0 for diffuse surface
    }
    else if (token[0].equals("reflective")){
      RTracer.addMaterial(float(token[1]),float(token[2]),float(token[3]),float(token[4]),float(token[5]),float(token[6]), float(token[7]));
    }
    else if (token[0].equals("noise")){
      RTracer.addNoiseToMaterial(int(token[1]));
    }
    else if (token[0].equals("wood")){
      RTracer.setCurMaterial(TextureType.WOOD);
    }
    else if (token[0].equals("marble")){
      RTracer.setCurMaterial(TextureType.MARBLE);
    }
    else if (token[0].equals("stone")){
      RTracer.setCurMaterial(TextureType.STONE);
    }
    else if(token[0].equals("named_object")){
      NamedObjects.put(token[1], CurrentObject);
      //CurrentObject = null;
    }
    else if(token[0].equals("instance")){
      println("top of stack:");
      printMatrix();
      RTracer.addToScene(token[1], (PMatrix3D)getMatrix());
    }
    else if (token[0].equals("sphere")) {
      PVector txVertex = getTransformedVertex(float(token[2]),float(token[3]),float(token[4]));
      RTracer.addObject(new Sphere(float(token[1]),txVertex.x,txVertex.y,txVertex.z));
      //CurrentObject = new Sphere(float(token[1]),txVertex.x,txVertex.y,txVertex.z);
      //RTracer.addObject(new Sphere(float(token[1]),float(token[2]),float(token[3]),float(token[4])));
    }
    else if (token[0].equals("moving_sphere")){
      PVector sxVertex = getTransformedVertex(float(token[2]),float(token[3]),float(token[4]));
      PVector exVertex = getTransformedVertex(float(token[5]),float(token[6]),float(token[7]));
      RTracer.addObject(new MovingSphere(float(token[1]),sxVertex.x,sxVertex.y,sxVertex.z,exVertex.x,exVertex.y,exVertex.z));
    }
    else if (token[0].equals("box")){
      PVector minBound = getTransformedVertex(float(token[1]),float(token[2]),float(token[3]));
      PVector maxBound = getTransformedVertex(float(token[4]),float(token[5]),float(token[6]));
      RTracer.addObject(new Box(minBound.x, minBound.y, minBound.z, maxBound.x, maxBound.y, maxBound.z));
      if(!AddToList){
        RTracer.addToScene(CurrentObject);
        CurrentObject = null;
      }
    }
    else if(token[0].equals("hollow_cylinder")){
      PVector txVertex1 = getTransformedVertex(float(token[2]),float(token[4]),float(token[3]));
      PVector txVertex2 = getTransformedVertex(float(token[2]),float(token[5]),float(token[3]));
      RTracer.addObject(new HollowCylinder( float(token[1]), txVertex1.x, txVertex1.y, txVertex2.y, txVertex1.z));
    }
    else if(token[0].equals("begin")){
      tempPolygon = new Polygon();
    }
    else if(token[0].equals("end")){
      if(tempPolygon.vertices.size()>3)
        RTracer.addObject(new Polygon(tempPolygon));
      else if(tempPolygon.vertices.size()==3)
        RTracer.addObject(new Triangle(tempPolygon));  
      /*if(!AddToList){
        RTracer.addToScene(CurrentObject);
        CurrentObject = null;
      }*/
    }
    else if(token[0].equals("vertex")){
      PVector txVertex = getTransformedVertex(float(token[1]),float(token[2]),float(token[3]));
      tempPolygon.addVertex(txVertex.x,txVertex.y,txVertex.z);
    }
    else if(token[0].equals("begin_list")){
      AddToList = true;
      ListStartIndices.push(CurrentList.size());
    }
    else if(token[0].equals("end_list")){
      int recentListStartIndex = (Integer) ListStartIndices.pop();
      ObjList objList = new ObjList();
      for(int k = recentListStartIndex; k<CurrentList.size();k++){
        objList.addObject(CurrentList.get(k));
      }
      CurrentList.set(recentListStartIndex,objList);
      CurrentList.subList(recentListStartIndex+1, CurrentList.size()).clear();
      if(recentListStartIndex == 0){
        RTracer.addToScene(CurrentList.get(0));
        AddToList = false;
        CurrentList.clear();
        ListStartIndices.clear();
      }
    }
    else if(token[0].equals("end_accel")){
      
      int recentListStartIndex = (Integer) ListStartIndices.pop();
      ArrayList<Object> objs = new ArrayList<Object>();
      for(int k = recentListStartIndex; k<CurrentList.size();k++){
        objs.add(CurrentList.get(k));
      }
      Accelerator accel = new Accelerator( objs, 0);
      
      CurrentList.set(recentListStartIndex,accel);
      CurrentList.subList(recentListStartIndex+1, CurrentList.size()).clear();
      if(recentListStartIndex == 0){
        RTracer.addToScene(CurrentList.get(0));
        //CurrentObject = CurrentList.get(0);
        AddToList = false;
        CurrentList.clear();
        ListStartIndices.clear();
      }
      
    }
    else if(token[0].equals("push")){
      pushMatrix();
    }
    else if(token[0].equals("pop")){
      popMatrix();
    }
    else if(token[0].equals("translate")){
      applyMatrix(1,0,0,float(token[1]),
                  0,1,0,float(token[2]),
                  0,0,1,float(token[3]),
                  0,0,0,1);
    }
    else if(token[0].equals("scale")){
      applyMatrix(float(token[1]),0,0,0,
                  0,float(token[2]),0,0,
                  0,0,float(token[3]),0,
                  0,0,0,1);
    }
    else if(token[0].equals("rotate")){
      float ang = radians(float(token[1]));
      if(float(token[2])!=0)
        rotateX(ang);
      if(float(token[3])!=0)
        rotateY(ang);
      if(float(token[4])!=0)
        rotateZ(ang);
    }
    else if (token[0].equals("read")) {  // reads input from another file
      interpreter (token[1]);
    }
    else if (token[0].equals("color")) {  // example command -- not part of ray tracer
      float r = float(token[1]);
      float g = float(token[2]);
      float b = float(token[3]);
      fill(r, g, b);
    }
    else if (token[0].equals("rect")) {  // example command -- not part of ray tracer
      float x0 = float(token[1]);
      float y0 = float(token[2]);
      float x1 = float(token[3]);
      float y1 = float(token[4]);
      rect(x0, screen_height-y1, x1-x0, y1-y0);
    }
    else if (token[0].equals("reset_timer")) {
      timer = millis();
    }
    else if (token[0].equals("print_timer")) {
      int new_timer = millis();
      int diff = new_timer - timer;
      float seconds = diff / 1000.0;
      println("timer = " + seconds);
    }
    else if (token[0].equals("write")) {
      
      restoreMatrix();
      println("Rendering...");
      RTracer.rayTrace();
      save(token[1]);  
      println("Done.");
    }
  }
}

//Some global variables for accessing
int timer;
//  Draw frames.  Should be left empty.
void draw() {
}

void restoreMatrix(){
  resetMatrix();
  applyMatrix(gmat[0], gmat[1], gmat[2], gmat[3], gmat[4], gmat[5], gmat[6], gmat[7],
              gmat[8], gmat[9], gmat[10], gmat[11], gmat[12], gmat[13], gmat[14], gmat[15]);
}

PVector getTransformedVertex(float x, float y, float z){
  PMatrix3D curMatrix = (PMatrix3D) getMatrix();
  PVector vertx = new PVector(x,y,z);
  PVector destn = new PVector();
  curMatrix.mult(vertx,destn);
  return destn;
}
// when mouse is pressed, print the cursor location
void mousePressed() {
  println ("mouse: " + mouseX + " " + mouseY);
}

void instantiate(){
  CurrentObject = null;
  NamedObjects = new HashMap<String, Object>();
  CurrentList = new ArrayList<Object>();
  ListStartIndices = new Stack();
  LOG = true;
}