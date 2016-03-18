
class Material{
  color diffuse;
  color ambient;
  Material(float tr, float tg, float tb, float ar, float ag, float ab){
    diffuse = color(tr,tg,tb);
    ambient = color(ar,ag,ab);
  }
  color getDiffuse(){
    return diffuse;
  }
  color getAmbient(){
    return ambient;
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