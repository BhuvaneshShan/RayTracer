enum TextureType{ NONE, NOISE, WOOD, MARBLE, STONE};
  
class Material{
  color diffuse;
  color ambient;
  
  boolean hasNoise = false;
  int noiseScale = 0;
  
  TextureType texType;
  
  Material(float tr, float tg, float tb, float ar, float ag, float ab){
    diffuse = color(tr,tg,tb);
    ambient = color(ar,ag,ab);
    texType = TextureType.NONE;
  }
  color getDiffuse(){
    return diffuse;
  }
  color getDiffuse(float x, float y, float z, PVector pos){
    if(texType == TextureType.NOISE){
      float noiseVal = noise_3d(noiseScale * x,noiseScale * y,noiseScale * z);
      noiseVal = (noiseVal+1)/2;
      return mulColor(diffuse, noiseVal);
    }else if(texType == TextureType.WOOD){
      return getWoodTexel(x,y,z, pos);
    }else if(texType == TextureType.MARBLE){
      return getMarbleTexel(x,y,z);
    }else if(texType == TextureType.STONE){
      return getStoneTexel(x,y,z);
    }else{
      return diffuse;
    }
  }
  color getAmbient(){
    return ambient;
  }
  void setToNoise(int scale){
    texType = TextureType.NOISE;
    noiseScale = scale;
  }
  void setToWood(){
     texType = TextureType.WOOD;
  }
  void setToMarble(){
     texType = TextureType.MARBLE;
  }
  void setToStone(){
     texType = TextureType.STONE;
  }
  
  int calcNumberOfFeatures(float p){
    if(p<0.2)
      return 1;
    else if(p<0.4)
      return 2;
    else if(p<0.6)
      return 3;
    else if(p<0.8)
      return 4;
    else 
      return 5;
  }
  
  PVector getFeaturePoint(int cx, int cy, int cz){
    return new PVector(cx+random(1),cy+random(1), cz+random(1));
  }
  
  color getStoneTexel(float x, float y, float z){
    //color stoneColor = color(0.149,0.772,0.988);
    color stoneColor = color(0.98,0.41,0.14);
    int seedscale = 10;
    float dist1 = 9999; float dist2 = 9999;
    float cellSize = 1.73;      
    
    x = x*cellSize;
    y = y*cellSize;
    z = z*cellSize;
    
    PVector nfp = new PVector(); //nearest feature point
    int ecx = fastfloor(x); int ecy = fastfloor(y); int ecz = fastfloor(z);
    for(int i=-1; i<2; i++){
      for(int j=-1; j<2; j++){
        for(int k=-1; k<2; k++){
          int cx = ecx+i; int cy = ecy +j; int cz = ecz + k;
          int seed = int(3728377 * (1+noise_3d(seedscale*cx, seedscale*cy, seedscale*cz)));
          randomSeed(seed);
          float probability = random(1);
          int numOfFeaturePoints = calcNumberOfFeatures(probability);
          for(int l=0;l<numOfFeaturePoints; l++){
            PVector fp = getFeaturePoint(cx,cy,cz);
            float dist = sqrt((x-fp.x)*(x-fp.x) + (y-fp.y)*(y-fp.y) + (z-fp.z)*(z-fp.z));
            if(dist < dist1){
              dist2 = dist1;
              dist1 = dist;
              nfp = fp;
            }else if(dist<dist2){
              dist2 = dist;
            }
          }      
        }
      }
    }
    float inLine = (dist2 - dist1)/dist2;
    if(inLine>0.08){
      //inside cells
      int scale = 5;
      float noiseVal = noise_3d(scale * x,scale * y,scale * z);
      noiseVal = (noiseVal+1)/2;
      noiseVal = 0.85 + noiseVal/7;
      
      randomSeed(int(nfp.x*232+nfp.y*173837+nfp.z*372327));
      //color sc = color(red(stoneColor)+random(-0.25,0.1),green(stoneColor)+random(-0.25,0.1),blue(stoneColor)+random(-0.5,0.1));
      color sc = color(red(stoneColor)+random(-0.5,0.1),green(stoneColor)+random(-0.25,0.1),blue(stoneColor)+random(-0.25,0.1));
      return mulColor(sc,noiseVal);
    }
    else{
      //outside cells or in cement
      int scale = 40;
      float noiseVal = noise_3d(scale * x,scale * y,scale * z);
      noiseVal = (noiseVal+1)/2;
      noiseVal = 0.75 + noiseVal/4;
      return mulColor(diffuse, noiseVal);
    }
  }
  
  float turbulence(float x,float y,float z){
    float t = 0;
    float scale = 10;
    float initScale = scale;
    while(scale >= 1){
      t += noise_3d(x/scale,y/scale,z/scale)*scale;
      scale = scale/2;
    }
    return t/initScale;
  }
  
  color getMarbleTexel(float x, float y, float z){
     color light = color(0.83, 0.95, 0.75);
     color dark = color(0.1, 0.52, 0);
     
     int scale = 10;
     float noiseVal =  2*noise_3d(scale * x,scale * y,scale * z);
     int scale2 = 20;
     float noiseVal2 = 0.5*noise_3d(scale2 * x,scale2 * y,scale2 * z);
     int scale3 = 3;
     float noiseVal3 = 4*noise_3d(scale3 * x,scale3 * y,scale3 * z);
     
     x = x*20 + y*10 + 2*turbulence(x,y,z);
     x = x +noiseVal+noiseVal2+noiseVal3;
     float inLine = (1+sin(x))/2;
     color front = interpolateColors(light, inLine, dark);
     
     return front; 
  }
  
  color getWoodTexel(float x, float y, float z, PVector pos){
      color light = color(0.91, 0.65, 0.35);
      color dark = color(0.54, 0.31, 0.05);
      color brown = color(0.7, 0.4, 0.2);
      
      y = y - pos.y ;
      z = z - pos.z ;
      
      //rotating
      float q = radians(-60);
      z = z*cos(q) - x*sin(q);
      x = z*sin(q) + x*cos(q);
      y = y;
      
      //for bands
      float dist = sqrt(y*y + z*z);
      dist = dist * 55;
      
      float scale = 8;
      float noiseVal = noise_3d(scale * x,scale * y,scale * z);
      
      dist = dist + noiseVal; 
      float onLine = (1+sin(dist))*0.5;
      
      //for thin lines
      int scale2 = 10;
      float noiseVal2 = 4*noise_3d(scale2 * x,scale2 * y,scale2 * z);
      float param = x*217 + y*227+ noiseVal2 + 2*turbulence(x,y,z);
      float inLine = (1+sin(param))/2;
      
      //deciding the band color
      color base = light;
      if(onLine<0.55){
        if(inLine<0.25){
          base = interpolateColors(brown,inLine+0.2,light);
        }
        else
          base = light;
      }
      else{
        if(inLine < 0.25){
          base = interpolateColors(brown,inLine+0.2,dark);
        }else{
           base = dark;
        }
      }
      
      //final faint noise on texture
      float noiseScale3 = 20;
      float noiseVal3 = noise_3d(noiseScale3 * x,noiseScale3 * y,noiseScale3 * z);
      noiseVal3 = 0.8 + (noiseVal3+1)/20;
      return mulColor(base, noiseVal3);
  }
}




abstract class Light{
  PVector pos;
  color col;
  Light(float x,float y, float z, float r, float g, float b){
    pos = new PVector(x,y,z);
    col = color(r,g,b);
  }
  abstract PVector getPos();
  abstract color getColor();
}


class PointLight extends Light{
  PointLight(float x,float y, float z, float r, float g, float b){
    super(x,y,z,r,g,b);
  }
  PVector getPos(){
    return pos;
  }
  color getColor(){
    return col;
  }
}



class DiskLight extends Light{
  float radius = 0;
  PVector normal;
  DiskLight(float x, float y, float z, float rad, float nx, float ny, float nz, float r, float g, float b){
    super(x,y,z,r,g,b);
    radius = rad;
    normal = new PVector(nx,ny,nz);
  }
  PVector getPos(){
    //returns random position on the disk
    float theta = random(2*PI);
    float phi = random(PI);
    PVector B = new PVector(radius*cos(theta)*sin(phi),radius*sin(theta)*sin(phi),radius*cos(phi));
    B.add(pos);
    PVector AB = PVector.sub(B,pos);
    float d = PVector.mult(normal.normalize(),radius).dot(AB);
    PVector C = PVector.sub(B,PVector.mult(normal.normalize(),d));
    return C;
  }
  color getColor(){
    return col;
  }
}


class Lens{
  float radius = 0;
  float focalDist = 0;
  Lens(float rad, float fd){
    radius = rad;
    focalDist = fd;
  }
  PVector computeIntersectionPointOnFocalPlane(PVector origin, PVector raydir){
    //plane is assumed to be from the origin at z = -focalDist
    //normal of plane is assumed to be facing eye/origin i.e. normal = (0,0,1);
    PVector normalOfPlane = new PVector(0,0,focalDist).normalize();
    float root = -(normalOfPlane.dot(origin) + focalDist)/(normalOfPlane.dot(raydir));
    return PVector.add(origin,PVector.mult(raydir,root));
  }
  PVector randomPointOnLens(){
    //from disk light random point
    PVector normalOfLens =  new PVector(0,0,-1).normalize();
    
    float theta = random(2*PI);
    float phi = random(PI);
    PVector B = new PVector(radius*cos(theta)*sin(phi),radius*sin(theta)*sin(phi),radius*cos(phi));
    //B.add(pos); //not needed since lens position is assumed to be origin
    PVector AB = B; //since A is origin
    float d = PVector.mult(normalOfLens,radius).dot(AB);
    PVector C = PVector.sub(B,PVector.mult(normalOfLens,d));
    return C;
  }
}

class CollisionData{
  float root = 0;
  PVector normal;
  PVector posOnObj;
  PVector objPos;
  int materialId;
  CollisionData(float troot, PVector tnormal, PVector tposOnObj, PVector tObjPos, int tmatId){
    root = troot;
    normal = tnormal;
    posOnObj = tposOnObj;
    objPos = tObjPos;
    materialId = tmatId;
  }
  CollisionData(){
    root = 0;
    materialId = 0;
    normal = new PVector(0,0,0);
    posOnObj = new PVector(0,0,0);
    objPos = new PVector(0,0,0);
  }
}