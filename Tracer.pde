class raytracer{
  float k = 0; //view plane extrema
  float z1 = -1;
  int minx, miny, maxx, maxy;
  float sw2, sh2; //screen width /2 and screen height /2
  PVector origin = new PVector(0,0,0);
  
  ArrayList<Object> objects;
  ArrayList<Material> materials;
  ArrayList<Light> lights;
  
  int curMaterialId=0;
  color bg;
  
  raytracer(){
    objects = new ArrayList<Object>();
    materials = new ArrayList<Material>();
    lights = new ArrayList<Light>();
    sw2 = screen_width/2;
    sh2 = screen_height/2;
  }
  void setFov(float fov){
    k = tan(radians(fov/2));

    minx = int(-k); miny = int(-k); 
    maxx = int(k); maxy = int(k);
    println("k found"+k);
  }
  /*void addObject(float tr, float tx, float ty, float tz){
    objects.add(new Sphere(tr,tx,ty,tz));
    println("object added:"+tr+" at "+tx+","+ty+","+tz);
  }*/
  void addObject(Object obj){
    obj.assignMaterial(curMaterialId);
    objects.add(obj);
    println("object added at "+obj.pos.x+","+obj.pos.y+","+obj.pos.z);
  }
  void addMaterial(float r, float g, float b, float ar, float ag, float ab){
    materials.add(new Material(r,g,b,ar,ag,ab));
    curMaterialId=materials.size()-1;
    println("material added");
  }
  void addLight(float x,float y, float z, float r, float g, float b){
    lights.add(new Light(x,y,z,r,g,b));
    println("light added");
  }
  void setBg(float r, float g, float b){
    bg = color(r, g, b);
    println("bg set");
  }
  public int tx,ty;
  void rayTrace(){
    loadPixels();
    for(int y=0;y<screen_height;y++){
      for(int x=0;x<screen_width;x++){
        tx = x;ty=y;
        PVector raydir = getRayFromEyeToPixelPos(x,y);
        raydir.normalize();
        pixels[y*screen_width+x] = intersectsObject(origin, raydir);
      }
    }
    updatePixels();
  }
  color intersectsObject(PVector org, PVector raydir){
    //Assumes origin as the start of the ray
    color pixelColor = bg;
    float finalZ = -MAX_FLOAT;
    for(int i=0;i<objects.size();i++){
      float root = objects.get(i).isIntersects(org, raydir);
      if(root>0){ //positive means in the direction of the ray
        //if(objects.get(i).pos.z > finalZ){
         PVector posOnObj = PVector.add(org,PVector.mult(raydir,root));
         if( posOnObj.z > finalZ){
          finalZ = posOnObj.z;
          color diffuseColor = materials.get(objects.get(i).materialId).getDiffuse(); //color(0.3,0.6,0.1);//
          color ambientColor = materials.get(objects.get(i).materialId).getAmbient();
          color reflRayColor = getReflectedRayColor( i, root, org, raydir);
          pixelColor = mulColors(diffuseColor, reflRayColor);
          pixelColor = addColors(pixelColor,ambientColor);
              
        }
      }
    }
    return pixelColor;
  }
  void printColor(color c, String t){
    println(t+" Color val:"+red(c)+","+green(c)+","+blue(c));
  }
  color getReflectedRayColor(int objId, float root, PVector org, PVector raydir){
    PVector posOnObj = PVector.add(org,PVector.mult(raydir,root));
    //normal at the position where ray hits object
    PVector normal = objects.get(objId).getNormal(posOnObj);
    //initial reflected ray color is black or shadow color
    color refrRayColor = color(0,0,0);
    //send ray to all lights
    for(int i=0;i<lights.size();i++){
      PVector refrRayDir = PVector.sub(lights.get(i).pos,posOnObj).normalize();
      //check if ray hits any object before reaching light
      boolean hitAnObject=false;
      for(int j=0; j<objects.size(); j++){
        if(j!=objId){
          float hitVal = objects.get(j).isIntersects(posOnObj,refrRayDir);
          if(hitVal>0){
            //if hit
            hitAnObject = true;
          }
        }
      }
      if(hitAnObject==false){
          //if not hit, then find refrRayColor
          float coeff = objects.get(objId).dotWithNormal(normal,refrRayDir);
          //println("coeff of dot normal:"+coeff);
          if(coeff<0) coeff = 0;
          float distance = posOnObj.dist(lights.get(i).pos);
          float intensity = 1;///distance;
          /*if(objId==1){
            println("root:"+root+" ray:"+ray.x+","+ray.y+","+ray.z);
            println("posOnObj:"+posOnObj.x+","+posOnObj.y+","+posOnObj.z);
            println("normal:"+normal.x+","+normal.y+","+normal.z);
            println("refrRay:"+refrRay.x+","+refrRay.y+","+refrRay.z);
            println("coeff:"+coeff+",dist:"+distance);
          }*/
          refrRayColor = addColors(refrRayColor,lights.get(i).col,coeff*intensity);
      }
    }
    return refrRayColor;
  }
  PVector getRay(int sx, int sy, int sz, int dx, int dy, int dz){
     return new PVector(dx-sx,dy-sy,dz-sz); //destn - src
  }
  PVector getRayFromEyeToPixelPos(int x, int y){ 
    float x1 = (x-sw2)*k/sw2;
    float y1 = (y-sh2)*(-k)/sh2;
    PVector ray =  new PVector(x1,y1,z1); //x1-x0 (origin) y1-y0 z1-z0 but origin is 0,0,0
    return ray;
  }
  void reset(){
    clearPixelBuffer();
    bg = color(0,0,0); //black as default background color
    objects.clear();
    materials.clear();
    lights.clear();
  }
  void clearPixelBuffer(){
    color black = color(0,0,0);
    loadPixels();
    for(int i=0;i<screen_width*screen_height;i++){
      pixels[i] = black;
    }
    updatePixels();
  }
}
raytracer RTracer;