class raytracer{
  float k = 0; //view plane extrema
  float z1 = -1;
  int minx, miny, maxx, maxy;
  float sw2, sh2; //screen width /2 and screen height /2
  PVector origin = new PVector(0,0,0); //also eye position
  
  int raysPerPixel = 1;
  float midPixelOffset = 0.5;
  
  ArrayList<Object> objects;
  ArrayList<Material> materials;
  ArrayList<Light> lights;
  
  int curMaterialId=0;
  color bg;
  
  boolean hasLens = false;
  Lens lens;
  
  raytracer(){
    objects = new ArrayList<Object>();
    materials = new ArrayList<Material>();
    lights = new ArrayList<Light>();
    sw2 = screen_width/2;
    sh2 = screen_height/2;
  }
  void setRaysPerPixel(int raysperpixel){
    raysPerPixel = raysperpixel;
  }
  void setFov(float fov){
    k = tan(radians(fov/2));

    minx = int(-k); miny = int(-k); 
    maxx = int(k); maxy = int(k);
    printlg("k found"+k);
  }
   void setLens(float lensRadius, float lensFocalDist){
    //currently supports only one lens
    hasLens = true;
    lens = new Lens(lensRadius, lensFocalDist);
  }
  void addObject(Object obj){
    obj.assignMaterial(curMaterialId);
    if(AddToList){
      CurrentList.add(obj);
    }else{
      CurrentObject = obj;
    }
    //printlg("current object set");
    //objects.add(obj);
    printlg("object set at "+obj.pos.x+","+obj.pos.y+","+obj.pos.z);
  }
  void addMaterial(float r, float g, float b, float ar, float ag, float ab){
    materials.add(new Material(r,g,b,ar,ag,ab));
    curMaterialId=materials.size()-1;
    printlg("material added");
  }
  void addToScene(String instanceName, PMatrix3D topOfStack){
    Object instance = new Instance(topOfStack,NamedObjects.get(instanceName));
    objects.add(instance);
    printlg(instanceName+"added to scene");
  }
  void addToScene(Object obj){
    objects.add(obj);
    printlg("object added to scene");
  }
  /*void addLight(float x,float y, float z, float r, float g, float b){
    lights.add(new Light(x,y,z,r,g,b));
    printlg("light added");
  }*/
  void addLight(Light light){
    lights.add(light);
    printlg("light added");
  }
  void setBg(float r, float g, float b){
    bg = color(r, g, b);
    printlg("bg set");
  }
  
  void rayTrace(){
    loadPixels();
    
    PVector raydir = new PVector();
    boolean randomizeOffset;
    PVector pixelColVal = new PVector(0,0,0);
    
    if(raysPerPixel == 1){
      randomizeOffset = false;
    }
    else{
      randomizeOffset = true;
    }
      
    for(int y=0; y<screen_height; y++){
      for(int x=0; x<screen_width; x++){
        if(x==screen_width/2 && y==screen_height/2){
          LOG = true;
        }
        else{
          LOG = false;
        }
        pixelColVal.set(0,0,0);
        
        if(hasLens == true){
          raydir = getRayFromEyeToPixelPos(x, y, false);
          raydir.normalize();
          PVector pointOnFocalPlane = lens.computeIntersectionPointOnFocalPlane(origin, raydir);
          
          for(int i=0; i<raysPerPixel; i++){
            PVector pointOnLens = lens.randomPointOnLens();
            raydir = PVector.sub(pointOnFocalPlane, pointOnLens);
            raydir.normalize();
            color pixelColor = intersectsObject(pointOnLens, raydir); //point on the lens is the origin
            pixelColVal.add(convertColor(pixelColor));
          }
          
        }else{
          //when hasLens is false
          
          for(int i=0; i<raysPerPixel; i++){
            raydir = getRayFromEyeToPixelPos(x,y,randomizeOffset);
            raydir.normalize();
            color pixelColor = intersectsObject(origin, raydir);
            pixelColVal.add(convertColor(pixelColor));
          }
          
        }
        pixels[y*screen_width+x] = convertColor(pixelColVal.div(raysPerPixel));
      }
    }
    updatePixels();
  }
  
  color intersectsObject(PVector org, PVector raydir){
    color pixelColor = bg;
    float finalZ = -MAX_FLOAT;
    for(int i=0;i<objects.size();i++){
      float root = objects.get(i).isIntersects(org, raydir);
      if(root>0){ //positive means in the direction of the ray
        
        printlg("IsIntersects obj "+i+" root:"+root);
        
        PVector txOrg = org;
        PVector txRaydir = raydir;
         if( objects.get(i) instanceof Instance){
           txOrg = ((Instance)objects.get(i)).getInvTransVector(org);
           txRaydir = ((Instance)objects.get(i)).getAdjointTransVector(raydir);
           txRaydir.normalize();
           printlg("is instance");
         }
         PVector posOnObj = PVector.add( txOrg, PVector.mult(txRaydir,root));
         if( posOnObj.z > finalZ){
          finalZ = posOnObj.z;
          color diffuseColor = materials.get(objects.get(i).getMaterialId()).getDiffuse(); //color(0.3,0.6,0.1);//
          color ambientColor = materials.get(objects.get(i).getMaterialId()).getAmbient();
          color reflRayColor = getReflectedRayColor( i, root, txOrg, txRaydir);
          //printlg("refl ray color"+ tostring(reflRayColor));
          pixelColor = mulColors(diffuseColor, reflRayColor);
          pixelColor = addColors(pixelColor,ambientColor);
              
        }
      }
    }
    return pixelColor;
  }
  color getReflectedRayColor(int objId, float root, PVector org, PVector raydir){
    PVector posOnObj = PVector.add(org, PVector.mult(raydir,root));
    //normal at the position where ray hits object
    PVector normal = objects.get(objId).getNormal(posOnObj);
    //initial reflected ray color is black or shadow color
    color refrRayColor = color(0,0,0);
    //send ray to all lights
    for(int i=0;i<lights.size();i++){
      PVector refrRayDir = PVector.sub(lights.get(i).getPos(), posOnObj).normalize();
      //check if ray hits any object before reaching light
      boolean hitAnObject=false;
      for(int j=0; j<objects.size(); j++){
        if(j!=objId){
          float hitVal = objects.get(j).isIntersects(posOnObj,refrRayDir);
          if(hitVal>0){
            //if hit
            hitAnObject = true;
            //printlg("hit true with obj"+j);
          }
        }
      }
      if(hitAnObject==false){
          //if not hit, then find refrRayColor
          float coeff = objects.get(objId).dotWithNormal(normal,refrRayDir);
          if(coeff<0) coeff = 0;
          float distance = posOnObj.dist(lights.get(i).pos);
          float intensity = 1;///distance;
          /*if(objId==1){
            printlg("root:"+root+" ray:"+ray.x+","+ray.y+","+ray.z);
            printlg("posOnObj:"+posOnObj.x+","+posOnObj.y+","+posOnObj.z);
            printlg("normal:"+normal.x+","+normal.y+","+normal.z);
            printlg("refrRay:"+refrRay.x+","+refrRay.y+","+refrRay.z);
            printlg("coeff:"+coeff+",dist:"+distance);
          }*/
          refrRayColor = addColors(refrRayColor,lights.get(i).getColor(),coeff*intensity);
      }
    }
    return refrRayColor;
  }
  
   PVector getRayFromEyeToPixelPos(int x, int y, boolean randomOffset){ 
     float tx = 0; 
     float ty = 0;
     if(randomOffset == true){
      tx = x + random(1);
      ty = y + random(1);
    }else{
      tx = x + midPixelOffset;
      ty = y + midPixelOffset;
    }
    float x1 = (tx-sw2)*k/sw2;
    float y1 = (ty-sh2)*(-k)/sh2;
    
    PVector ray =  new PVector(x1 - origin.x ,y1 - origin.y ,z1 - origin.z); //x1-x0 (origin) y1-y0 z1-z0 but origin is 0,0,0
    return ray;
  }
  PVector getRay(int sx, int sy, int sz, int dx, int dy, int dz){
     return new PVector(dx-sx,dy-sy,dz-sz); //destn - src
  }
 
  void reset(){
    clearPixelBuffer();
    bg = color(0,0,0); //black as default background color
    objects.clear();
    materials.clear();
    lights.clear();
    hasLens = false;
    lens = null;
    
    CurrentObject = null;
    NamedObjects.clear();
    CurrentList.clear();
    ListStartIndices.clear();
  }
  void clearPixelBuffer(){
    color black = color(0,0,0);
    loadPixels();
    for(int i=0;i<screen_width*screen_height;i++){
      pixels[i] = black;
    }
    updatePixels();
  }
  void printColor(color c, String t){
    printlg(t+" Color val:"+red(c)+","+green(c)+","+blue(c));
  }
}
raytracer RTracer;