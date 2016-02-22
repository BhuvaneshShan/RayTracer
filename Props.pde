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