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
  
  boolean photonMapping = false;
  
  photonTypes photonType;
  int photonCount = 0;
  int numPhotonsNearby = 0;
  float maxDistToSearch = 0;
  kd_tree photonTree;
  
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
      //objects.add(obj);
      addToScene(obj);
    }
    //printlg("current object set");
    //objects.add(obj);
    printlg("object set at "+obj.pos.x+","+obj.pos.y+","+obj.pos.z+"; Mat id:"+curMaterialId);
  }
  void addMaterial(float r, float g, float b, float ar, float ag, float ab, float krefl){
    materials.add(new Material(r,g,b,ar,ag,ab,krefl));
    curMaterialId=materials.size()-1;
    printlg("material added");
  }
  void addNoiseToMaterial(int scale){
    materials.get(curMaterialId).setToNoise(scale);
  }
  void setCurMaterial(TextureType t){
    if(t == TextureType.WOOD){
      materials.get(curMaterialId).setToWood();
      println("wood texture set to material");
    }
    else if(t == TextureType.MARBLE)
      materials.get(curMaterialId).setToMarble();
    else if(t == TextureType.STONE)
      materials.get(curMaterialId).setToStone();
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
  void addLight(Light light){
    lights.add(light);
    printlg("light added");
  }
  void setBg(float r, float g, float b){
    bg = color(r, g, b);
    printlg("bg set");
  }
  
  void rayTrace(){
    LOG = false;
    loadPixels();
    
    if(photonMapping){
      photonMapping();
    }
    
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
       if((x==495 && y==503)){
          LOG = true;
          printlg("\n Processing Pixel:"+x+","+y);
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
            printlg("Start origin:"+origin.toString());
            printlg("Before norm raydir:"+raydir.toString());
            raydir.normalize();
            printlg("Start raydir:"+raydir.toString());
            color pixelColor = intersectsObject(origin, raydir);
            printlg("Final pixelColor: "+colorToStr(pixelColor));
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
      CollisionData cData = objects.get(i).isIntersects(org,raydir);
      if(cData.root > 0){
        printlg("\n IsIntersects obj "+i+" root:"+cData.root+" obj center:"+cData.objPos);
        printlg("pos on obj:"+cData.posOnObj.toString());
        printlg("finalz:"+finalZ);
         if( cData.posOnObj.z > finalZ){
          printlg("$ Z is less. so checking");
          finalZ = cData.posOnObj.z;
          
          color diffuseColor = materials.get(cData.materialId).getDiffuse(cData.posOnObj.x, cData.posOnObj.y, cData.posOnObj.z, cData.objPos); //color(0.3,0.6,0.1);//
          color ambientColor = materials.get(cData.materialId).getAmbient();
          
          color reflRayColor = getReflectedRayColor( i, cData); //For shadows
          pixelColor = mulColors(diffuseColor, reflRayColor);
          
          //If reflective material, spawn reflective ray to get reflection of other objects. i.e. color
          if(materials.get(cData.materialId).getMaterialType() == MaterialType.REFLECTIVE){
            printlg("=>>Shooting reflection ray:");
            float k_refl = materials.get(cData.materialId).getReflectanceQuotient();
            printlg("k_refl:"+k_refl);
            raydir.normalize();
            cData.normal.normalize();
            PVector reflectionDir = PVector.sub(raydir, PVector.mult(cData.normal,2.0f * PVector.dot(raydir,cData.normal)));
            color reflection = intersectsReflectionObject(cData.posOnObj, reflectionDir);
            printlg("Reflection color:"+colorToStr(reflection));
            reflection = mulColor(reflection, k_refl);
            pixelColor = addColors(pixelColor, reflection);
            printlg("<<=Out of refl ray");
          }
          
          //If photonmapping 
          if(photonMapping){
            color photonColor = getNearbyPhotonsColor(cData.posOnObj);
            //println("pix before:"+colorToStr(pixelColor));
            pixelColor = addColors(pixelColor, photonColor);
            printlg("Final Photon color:"+colorToStr(photonColor),2);
            //println("pix after:"+colorToStr(pixelColor));
           }
          
          //printlg("diffuse col:" + colorToStr(diffuseColor));
          //printlg("ambient col:" + colorToStr(ambientColor));
          //printlg("refl ray color"+ colorToStr(reflRayColor));
          
          pixelColor = addColors(pixelColor,ambientColor);
          printlg("pixel col:" + colorToStr(pixelColor));
        }
      }
    }
    printlg("is intersects final pixel col:" + colorToStr(pixelColor));
    return pixelColor;
  }
  
  color intersectsReflectionObject(PVector org, PVector raydir){
    color pixelColor = bg;
    float finalRoot = MAX_FLOAT;
    for(int i=0;i<objects.size();i++){
      CollisionData cData = objects.get(i).isIntersects(org,raydir);
      if(cData.root > 0 && cData.posOnObj != org){
        printlg("IsIntersects obj "+i+" root:"+cData.root+" obj center:"+cData.objPos);
        printlg("pos on obj:"+cData.posOnObj.toString());
        printlg("finalRoot:"+finalRoot);
        if( cData.root < finalRoot){
          printlg("\nchecking");
          finalRoot = cData.root;
          
          color diffuseColor = materials.get(cData.materialId).getDiffuse(cData.posOnObj.x, cData.posOnObj.y, cData.posOnObj.z, cData.objPos); //color(0.3,0.6,0.1);//
          color ambientColor = materials.get(cData.materialId).getAmbient();
          
          color reflRayColor = getReflectedRayColor( i, cData); //For shadows
          pixelColor = mulColors(diffuseColor, reflRayColor);
          
          //If reflective material, spawn reflective ray to get reflection of other objects. i.e. color
          if(materials.get(cData.materialId).getMaterialType() == MaterialType.REFLECTIVE){
            printlg("=>Shooting reflection ray:");
            
            float k_refl = materials.get(cData.materialId).getReflectanceQuotient();
            printlg("k_refl:"+k_refl);
            
            raydir.normalize();
            cData.normal.normalize();
            
            PVector reflectionDir = PVector.sub(raydir, PVector.mult(cData.normal,2.0f * PVector.dot(raydir,cData.normal)));
            color reflection = intersectsReflectionObject(cData.posOnObj, reflectionDir);
            printlg("Reflection color:"+colorToStr(reflection));
            reflection = mulColor(reflection, k_refl);
            pixelColor = addColors(pixelColor, reflection);
            printlg("=>Out of refl ray");
           }
          //If photonmapping 
          if(photonMapping){
            color photonColor = getNearbyPhotonsColor(cData.posOnObj); 
            pixelColor = addColors(pixelColor, photonColor);
           }
          pixelColor = addColors(pixelColor,ambientColor);
          printlg("refl pixel col:" + colorToStr(pixelColor), 2);
        }
      }
    }
    //printlg("pixel col:" + colorToStr(pixelColor));
    return pixelColor;
  }
  
  color getReflectedRayColor(int objId, CollisionData cData){
    printlg("=>Finding shadow");
    //Function to get shadows
    color refrRayColor = color(0,0,0);
    //send ray to all lights
    //printlg("posOnObj:"+cData.posOnObj.toString());
    //printlg("normal:" + cData.normal.toString());
    //printlg("obj pos:" +cData.objPos.toString());
    for(int i=0;i<lights.size();i++){
      //PVector refrRayDir = PVector.sub(lights.get(i).getPos(), cData.posOnObj).normalize();
      PVector refrRayDir = PVector.sub(cData.posOnObj,lights.get(i).getPos()).normalize(); //casting from light to point not the other way
      
      boolean hitAnObject=false;
      for(int j=0; j<objects.size(); j++){
          //CollisionData hitData = objects.get(j).isIntersects(cData.posOnObj,refrRayDir);
          CollisionData hitData = objects.get(j).isIntersects(lights.get(i).getPos(),refrRayDir);   //origin is set as light
          //printlg(hitData.root+" hitData:"+hitData.posOnObj.toString());
          if(hitData.root > 0 && !vectorEquals(hitData.objPos,cData.objPos)){
            //if hit
            if(hitData.posOnObj.z >= cData.posOnObj.z){
              hitAnObject = true;
              //printlg("hit an  obj true with obj pos "+hitData.objPos.toString());
              break;
            }
          }
      }
      if(hitAnObject==false){
          //if not hit, then find refrRayColor
          PVector reflRayDir = PVector.sub(lights.get(i).getPos(), cData.posOnObj).normalize(); //dir from point to lightsource
          float coeff = objects.get(objId).dotWithNormal(cData.normal,reflRayDir);
          //printlg("coeff: "+coeff);
          if(coeff<0) coeff = 0;
          float distance = cData.posOnObj.dist(lights.get(i).pos);
          float intensity = 1;///distance;
         
          refrRayColor = addColors(refrRayColor,lights.get(i).getColor(),coeff*intensity);
          //printlg("refr Ray color: "+colorToStr(refrRayColor));
      }
    }
    //printlg("refr Ray color: "+colorToStr(refrRayColor));
    printlg("<=Out of finding shadow");
    return refrRayColor;
  }
  
  void photonMapping(){
    println("Starting Photon Mapping");
    photonTree = new kd_tree();
    int powerScale = 4;
    if(photonType == photonTypes.CAUSTIC){
      powerScale = 10;
    }else{
      powerScale = 4;
    }
    int added = 0;
    int nothing = 0;
    
    for(int l=0; l<lights.size(); l++){
      Light light = lights.get(l);
      //mapPhotons(lights.get(i), photonTree, causticPhotonCount, 4);
      for(int i=0;i<photonCount; i++){
        float x,y,z;
        do{
          x = random(-1,1);
          y = random(-1,1);
          z = random(-1,1);
        }while(sqrt(x*x+y*y+z*z)>1);
        PVector dir = new PVector(x,y,z).normalize();
        PVector org = light.getPos();
        if(photonType == photonTypes.CAUSTIC){
          PVector photonPos = shootCausticPhoton(org,dir);
          if(photonPos.x == -MAX_FLOAT && photonPos.y == -MAX_FLOAT && photonPos.z == -MAX_FLOAT){
            //do nothing
            nothing++;
          }else{
            // PVector power = PVector.mult(convertColor(light.getColor()), powerScale*1.0/float(photonCount));
            PVector power = PVector.mult(convertColor(light.getColor()), powerScale*1.0/float(photonCount));
            // PVector power = convertColor(light.getColor());
            printlg("Adding power:"+power.toString(),2);
            Photon photon = new Photon(photonPos, power);
            photonTree.add_photon(photon);
            added++;
          }
        }else{
          //photon type is diffuse
          //Do diffuse photon
          ArrayList<Photon> photonPoss = shootDiffusePhoton(org,dir, convertColor(light.getColor()), powerScale);
          for(int j=0;j<photonPoss.size();j++){
              Photon photon = photonPoss.get(j);
              photonTree.add_photon(photon);
              added++;
            }
          }
        }
      }
    photonTree.build_tree();
    printlg("added:"+added);
    printlg("nothing:"+nothing);
    printlg("Photon tree size:"+photonTree.get_photon_count());
    println("Photon Mapping done!");
  }
  
  ArrayList shootDiffusePhoton(PVector org, PVector dir, PVector lightColor, int powerScale){
    int hitCount =0 ;
    ArrayList<Photon> photonList = new ArrayList<Photon>();
    boolean stop = false;
    float avg = 1;//(lightColor.x +lightColor.y + lightColor.z)/3;
    PVector power = PVector.mult(lightColor, powerScale*1.0/float(photonCount));
   
    while(random(0,1)<avg){
        CollisionData cData = shootPhotonRandomly(org, dir);
        if(cData.root>0 && cData.root!=MAX_FLOAT){
          hitCount ++;
          if(hitCount > 1){
            photonList.add(new Photon(cData.posOnObj, power));
          }
          color surfaceCol = materials.get(cData.materialId).getDiffuse();
          avg = (red(surfaceCol)+green(surfaceCol)+blue(surfaceCol))/3.0;
          power.x *= red(surfaceCol)/avg;
          power.y *= green(surfaceCol)/avg;
          power.z *= blue(surfaceCol)/avg;
          org = cData.posOnObj;
          dir = cData.normal;
        }else{
          avg = 0;
        }
      }
    return photonList;
  }
  
  CollisionData shootPhotonRandomly(PVector org, PVector normalToSurface){
    //Picking random direction
    float x,y,z;
    do{
      x = random(-1,1);
      y = random(-1,1);
    }while(sqrt(x*x+y*y)>=1);
    z = sqrt(1 - x*x - y*y);
    PVector p,q;
    if(abs(normalToSurface.x) > abs(normalToSurface.y) && abs(normalToSurface.x)>abs(normalToSurface.z)){
      p = new PVector(0,1,0);
    }else{
      p = new PVector(1,0,0);
    }
    q = normalToSurface.cross(p).normalize();
    p = normalToSurface.cross(q).normalize();
    PVector dir = PVector.add(PVector.add(PVector.mult(p,x), PVector.mult(q,y)), PVector.mult(normalToSurface,z));
    
    float rootMax = MAX_FLOAT;
    CollisionData finalCData = new CollisionData();
    for(int i=0;i<objects.size();i++){
        CollisionData cData = objects.get(i).isIntersects(org,dir);
        if(cData.root > 0 && cData.root<rootMax &&  cData.posOnObj != org){
          rootMax = cData.root;
          finalCData = cData;
        }
      }
    return finalCData;
  }
  
  PVector shootCausticPhoton(PVector org, PVector dir){
    
    int photonHitCount = 0;
    boolean foundPosition = false;
    PVector finalPos = new PVector(0,0,0);
    /*
    float rootMax = MAX_FLOAT;
    CollisionData finalCData = null;
    for(int i=0;i<objects.size();i++){
      CollisionData cData = objects.get(i).isIntersects(org,dir);
      if(cData.root > 0 && cData.root<rootMax &&  cData.posOnObj != org){
        rootMax = cData.root;
        finalCData = cData;
      }
    }
    if(rootMax < 0 || rootMax == MAX_FLOAT){
        finalPos = new PVector(-MAX_FLOAT, -MAX_FLOAT, -MAX_FLOAT);
        return finalPos;
    }
    return finalCData.posOnObj;
    */
    
    while(foundPosition == false){
      float rootMax = MAX_FLOAT;
      CollisionData finalCData = null;
      for(int i=0;i<objects.size();i++){
        CollisionData cData = objects.get(i).isIntersects(org,dir);
        if(cData.root > 0 && cData.root<rootMax &&  cData.posOnObj != org){
          rootMax = cData.root;
          finalCData = cData;
        }
      }
      if(rootMax < 0 || rootMax == MAX_FLOAT){
        finalPos = new PVector(-MAX_FLOAT, -MAX_FLOAT, -MAX_FLOAT);
        foundPosition = true;
      }else{
        photonHitCount++;
        if(photonHitCount>1 && materials.get(finalCData.materialId).getMaterialType() == MaterialType.DIFFUSIVE){
          foundPosition = true;
          finalPos = finalCData.posOnObj;
        }else if(materials.get(finalCData.materialId).getMaterialType() == MaterialType.REFLECTIVE){
          org = finalCData.posOnObj;
          dir.normalize();
          finalCData.normal.normalize();
          dir = PVector.sub(dir, PVector.mult(finalCData.normal,2.0f * PVector.dot(dir,finalCData.normal)));
        }else{
          foundPosition = true;
          finalPos = new PVector(-MAX_FLOAT, -MAX_FLOAT, -MAX_FLOAT);
        }
      }
    }
    return finalPos;
  }
  
  color getNearbyPhotonsColor(PVector pos){ 
    ArrayList<Photon> plist;
    plist = photonTree.find_near ((float)pos.x, (float)pos.y, (float)pos.z, numPhotonsNearby, maxDistToSearch);
    color photonColor = color(0,0,0);
    float maxr = 0;
    PVector maxpow = new PVector(0,0,0);
    for(int i=0;i<plist.size();i++){
      //println("pos:"+pos.toString());
      Photon p = plist.get(i);
      if(p!=null){
        //println("photon:"+ p.getPos().toString());
        float r = PVector.dist(pos, p.getPos());
        if(r > maxr)
          maxr = r;
        //printlg("r:"+r,2);
        PVector pow = p.getPow();
        maxpow = PVector.add(maxpow,pow);
        //printlg("pow:"+pow.toString(),2);
        //pow = PVector.mult(pow,1.0/(r*r));
        //printlg("After considering dist:"+pow.toString(),2);
        //color toAdd = convertColor(pow);
        //printlg("toAdd col:"+colorToStr(toAdd),2);
        //photonColor = addColors(photonColor, toAdd);
        //printlg("Photon color:" + colorToStr(photonColor),2);
      }else{
        //println("p is null");
      }
    }
    maxpow = PVector.mult(maxpow, 1/(maxr*maxr));
    color toAdd = convertColor(maxpow);
    photonColor = addColors(photonColor, toAdd);
    printlg("returning Photon color:" + colorToStr(photonColor),2);
    return photonColor;
  }
  
  boolean vectorEquals(PVector one, PVector two){
    if(one.x == two.x && one.y == two.y && one.z == two.z)
      return true;
    else
      return false;
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
    
    photonMapping = false;
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