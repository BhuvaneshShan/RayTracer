///////////////////////////////////////////////////////////////////////
//
//  Ray Tracing Shell
//
///////////////////////////////////////////////////////////////////////

int screen_width = 300;
int screen_height = 300;

// global matrix values
PMatrix3D global_mat;
float[] gmat = new float[16];  // global matrix values

// Some initializations for the scene.

void setup() {
  size (300, 300, P3D);  // use P3D environment so that matrix commands work properly
  noStroke();
  colorMode (RGB, 1.0);
  background (0, 0, 0);
  
  // grab the global matrix values (to use later when drawing pixels)
  PMatrix3D global_mat = (PMatrix3D) getMatrix();
  global_mat.get(gmat);  
  printMatrix();
  resetMatrix();    // you may want to reset the matrix here
  println("Matrix reset");
  printMatrix();
  RTracer = new raytracer();
  RTracer.reset();
  interpreter("t01.cli");
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
  if (str == null) println("Error! Failed to read the file.");
  for (int i=0; i < str.length; i++) {
    
    String[] token = splitTokens(str[i], " "); // Get a line and parse tokens.
    
    if (token.length == 0) continue; // Skip blank line.
    if(token[0].equals("rays_per_pixel")){
      RTracer.setRaysPerPixel(int(token[1]));
    }  
    else if (token[0].equals("fov")) {
      RTracer.setFov(float(token[1]));
    }
    else if (token[0].equals("background")) {
      RTracer.setBg(float(token[1]),float(token[2]),float(token[3]));
    }
    else if (token[0].equals("point_light")) {
      RTracer.addLight(float(token[1]),float(token[2]),float(token[3]),float(token[4]),float(token[5]),float(token[6]));
    }
    else if (token[0].equals("diffuse")) {
      RTracer.addMaterial(float(token[1]),float(token[2]),float(token[3]),float(token[4]),float(token[5]),float(token[6]));
    }    
    else if (token[0].equals("sphere")) {
      PVector txVertex = getTransformedVertex(float(token[2]),float(token[3]),float(token[4]));
      RTracer.addObject(new Sphere(float(token[1]),txVertex.x,txVertex.y,txVertex.z));
      //RTracer.addObject(new Sphere(float(token[1]),float(token[2]),float(token[3]),float(token[4])));
    }
    else if (token[0].equals("moving_sphere")){
      PVector sxVertex = getTransformedVertex(float(token[2]),float(token[3]),float(token[4]));
      PVector exVertex = getTransformedVertex(float(token[5]),float(token[6]),float(token[7]));
      RTracer.addObject(new MovingSphere(float(token[1]),sxVertex.x,sxVertex.y,sxVertex.z,exVertex.x,exVertex.y,exVertex.z));
    }
    else if(token[0].equals("begin")){
      tempPolygon = new Polygon();
    }
    else if(token[0].equals("end")){
      if(tempPolygon.vertices.size()>3)
        RTracer.addObject(new Polygon(tempPolygon));
      else if(tempPolygon.vertices.size()==3)
        RTracer.addObject(new Triangle(tempPolygon));  
    }
    else if(token[0].equals("vertex")){
      PVector txVertex = getTransformedVertex(float(token[1]),float(token[2]),float(token[3]));
      tempPolygon.addVertex(txVertex.x,txVertex.y,txVertex.z);
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
    else if (token[0].equals("write")) {
      restoreMatrix();
      RTracer.rayTrace();
      save(token[1]);  
    }
  }
}

//Some global variables for accessing
Polygon tempPolygon;

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