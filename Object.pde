abstract class Object{
  PVector pos = new PVector(0,0,0);
  int materialId=0;
  Object(float tx, float ty, float tz){
    pos.x = tx; pos.y = ty; pos.z = tz;
  }
  abstract void assignMaterial(int id);
  abstract float isIntersects(PVector rayorigin, PVector raydir);
  abstract PVector getNormal(PVector posOnObj);
  abstract float dotWithNormal(PVector norm, PVector refrdir);
}

class Sphere extends Object{
  float radius;
  Sphere(float tr, float tx,float ty, float tz){
    super(tx,ty,tz);
    radius = tr;
  }
  float isIntersects(PVector rayorigin, PVector raydir){
    PVector tcenter = PVector.sub(pos,rayorigin);
    float a = raydir.x*raydir.x + raydir.y*raydir.y + raydir.z*raydir.z;
    float b = -2*(raydir.x*tcenter.x+raydir.y*tcenter.y+raydir.z*tcenter.z);
    float c = tcenter.x*tcenter.x + tcenter.y*tcenter.y + tcenter.z*tcenter.z - radius*radius;
    float d = b*b - 4*a*c;
    if(d>=0){
      //if real root
      float t1 = (-b + sqrt(d))/2*a ;
      float t2 = (-b - sqrt(d))/2*a ;
      //if(t2<0) return t1;
       if(t1<t2) return t1;
      else return t2;
    }else{
      return 0.0;
    }
    /*
    Vec3f l = center - rayorig;
    float tca = l.dot(raydir);
    if (tca < 0) return false;
    float d2 = l.dot(l) - tca * tca;
    if (d2 > radius2) return false;
    float thc = sqrt(radius2 - d2);
    t0 = tca - thc;
    t1 = tca + thc;
    return true; 
    */
  }
  void assignMaterial(int id){
    materialId = id;
  }
  PVector getNormal(PVector posOnObj){
    return PVector.sub(posOnObj,pos).normalize();
  }
  float dotWithNormal(PVector norm, PVector ray){
    return norm.dot(ray);
  }
}
class MovingSphere extends Object{
  float radius;
  PVector startPos;
  PVector endPos;
  PVector movingDir; //not normalized
  float curRandomizedTime = 0;
  MovingSphere(float tr, float sx,float sy, float sz, float ex, float ey, float ez){
    super(sx,sy,sz);
    radius = tr;
    startPos = new PVector(sx,sy,sz);
    endPos = new PVector(ex,ey,ez);
    movingDir = PVector.sub(endPos, startPos);
  }
  PVector getPos(float time){
    //time is expected to be between 0.0 and 1.0
    return PVector.add(startPos,PVector.mult(movingDir,time));
  }
  float isIntersects(PVector rayorigin, PVector raydir){
    float time = random(1);
    curRandomizedTime = time;
    PVector tcenter = PVector.sub( getPos(time), rayorigin);
    float a = raydir.x*raydir.x + raydir.y*raydir.y + raydir.z*raydir.z;
    float b = -2*(raydir.x*tcenter.x+raydir.y*tcenter.y+raydir.z*tcenter.z);
    float c = tcenter.x*tcenter.x + tcenter.y*tcenter.y + tcenter.z*tcenter.z - radius*radius;
    float d = b*b - 4*a*c;
    if(d>=0){
      //if real root
      float t1 = (-b + sqrt(d))/2*a ;
      float t2 = (-b - sqrt(d))/2*a ;
      //if(t2<0) return t1;
       if(t1<t2) return t1;
      else return t2;
    }else{
      return 0.0;
    }   
  }
  void assignMaterial(int id){
    materialId = id;
  }
  PVector getNormal(PVector posOnObj){
    return PVector.sub(posOnObj, getPos(curRandomizedTime)).normalize();
  }
  float dotWithNormal(PVector norm, PVector ray){
    return norm.dot(ray);
  }
}
class Triangle extends Object{
  ArrayList<PVector> vertices;
  PVector normal;
  Triangle(){
    super(0,0,0);
    vertices = new ArrayList<PVector>(3);
    normal = new PVector(0,0,0);
  }
  Triangle(Polygon temp){
    super(0,0,0);
    this.vertices = new ArrayList<PVector>(3);
    this.vertices.add(temp.vertices.get(0));
    this.vertices.add(temp.vertices.get(1));
    this.vertices.add(temp.vertices.get(2));
    this.pos.x = (vertices.get(0).x+vertices.get(1).x+vertices.get(2).x)/3.0;
    this.pos.y = (vertices.get(0).y+vertices.get(1).y+vertices.get(2).y)/3.0;
    this.pos.z = (vertices.get(0).z+vertices.get(1).z+vertices.get(2).z)/3.0;
    //RTracer.addObject(new Sphere(0.3,pos.x,pos.y,pos.z));
    PVector AB = PVector.sub(this.vertices.get(1),this.vertices.get(0));
    PVector AC = PVector.sub(this.vertices.get(2),this.vertices.get(0));
    normal = AB.cross(AC).normalize(); //have to correct this by flipping normal
  }
  void assignMaterial(int id){
    materialId = id;
  }
  PVector getNormal(PVector posOnObj){
    return normal;
  }
  float dotWithNormal(PVector norm, PVector ray){
    float coeff = normal.dot(ray);
    if(coeff<0){
      normal = normal.mult(-1);
      return normal.dot(ray);
    }
    return coeff;
  }
  float nearzero = 0.000001;
  float isIntersects(PVector rayorigin, PVector raydir){
    PVector vecA = PVector.sub(vertices.get(1),vertices.get(0));
    PVector vecB = PVector.sub(vertices.get(2),vertices.get(0));
    PVector p = raydir.cross(vecB);
    float det = PVector.dot(vecA,p);
    if( det>-nearzero && det<nearzero)
      return 0;
    float invdet = 1.f/det;
    PVector t = PVector.sub(rayorigin,vertices.get(0));
    float u = PVector.dot(t,p)*invdet;
    if( u<0.f || u>1.f)
      return 0;
    PVector q = t.cross(vecA);
    float v = PVector.dot(raydir,q)*invdet;
    if(v<0.f || u+v > 1.f)
      return 0;
    float root = PVector.dot(vecB,q)*invdet;
    if(root>nearzero){
      return root;
    }
    return 0;
    /*
    PVector vecA = PVector.sub(vertices.get(0),vertices.get(1));
    PVector vecB = PVector.sub(vertices.get(2),vertices.get(1));
    PVector normToPlane = vecA.cross(vecB);
    normToPlane.normalize();
    float planeOffset = -(PVector.dot(normToPlane,vertices.get(0)));
    float t = -(PVector.dot(rayorigin,normToPlane)+planeOffset)/(PVector.dot(raydir,normToPlane));
    //println("t:"+t);
    PVector point = PVector.add(rayorigin,PVector.mult(raydir,t));
    
    //if(RTracer.tx>280 && RTracer.ty>280)
    //  println("hit "+RTracer.tx+","+RTracer.ty+" for "+t+" point:"+point.x+","+point.y+","+point.z);
      
    if(isWithinTriangle(point))
      return t;
    else
      return 0;
      */
  }
  
  boolean isWithinTriangle(PVector point){
    return false;
    /*
    PVector ab = PVector.sub(this.vertices.get(1),this.vertices.get(0));
    PVector ac = PVector.sub(this.vertices.get(2),this.vertices.get(0));
    PVector ap = PVector.sub(point,this.vertices.get(0));
    float del = ab.x*ac.y - ab.y*ac.x;
    float delx = ap.x*ac.y - ap.y*ac.x;
    float dely = ab.x*ap.y - ab.y*ap.x;
    float x = delx/del;
    float y = dely/del;
    if(RTracer.tx>280 && RTracer.ty>280)
      println("hit "+RTracer.tx+","+RTracer.ty+" point:"+point.x+","+point.y+","+point.z+" with vals:"+x+":"+y);
      
    if(x>=0 && y>=0 && (x+y)<=1)
      return true;
    else 
      return false;
    */
    /*
    PVector u = PVector.sub(this.vertices.get(1),this.vertices.get(0));
    PVector v = PVector.sub(this.vertices.get(2),this.vertices.get(0));
    PVector w = PVector.sub(point,this.vertices.get(0));
    //w = w.normalize();
    //u = u.normalize();
    //v = v.normalize();
    PVector n = u.cross(v);
    float nsq = sqrt(sq(n.x)+sq(n.y)+sq(n.z));
    float gamma = (u.cross(w).dot(n))/nsq;
    float beta = (w.cross(v).dot(n))/nsq;
    float alpha = 1 - gamma - beta;
    if(alpha>=0 && alpha<=1 && beta>=0 && beta<=1 && gamma>=0 && gamma<=1)
      return true;
    else 
      return false;
      */
    /*
    PVector AB = PVector.sub(this.vertices.get(1),this.vertices.get(0));
    PVector AP = PVector.sub(point,this.vertices.get(0));
    PVector BC = PVector.sub(this.vertices.get(2),this.vertices.get(1));
    PVector BP = PVector.sub(point,this.vertices.get(1));
    PVector CA = PVector.sub(this.vertices.get(0),this.vertices.get(2));
    PVector CP = PVector.sub(point,this.vertices.get(2));
    PVector abxap = AB.cross(AP);
    PVector bcxbp = BC.cross(BP);
    PVector caxcp = CA.cross(CP);
    //if(RTracer.tx>280 && RTracer.ty>280)
    //  println("hit "+RTracer.tx+","+RTracer.ty+" point:"+point.x+","+point.y+","+point.z+" with vals:"+abxap.z+":"+bcxbp.z+":"+caxcp.z);
      
    if( abxap.z>0 && bcxbp.z>0 && caxcp.z>0 )
      return true;
    else if( abxap.z<0 && bcxbp.z<0 && caxcp.z<0 )
      return true;
    //else if(abxap.z==0 && bcxbp.z==0 && caxcp.z==0 )
    //  return true;
    else
      return false;
    */
  }
}
class Polygon extends Object{
  ArrayList<PVector> vertices;
  PVector normal;
  Polygon(){
    //right now the pos of polygon is 0,0,0
    //Maybe we need find the center of the polygon or update pos after getting all vertices
    super(0,0,0); 
    vertices = new ArrayList<PVector>();
    normal = new PVector(0,0,0);
  }
  Polygon(Polygon temp){
    super(0,0,0);
    this.vertices = temp.vertices;
    normal = temp.normal;
  }
  void addVertex(float tx,float ty, float tz){
    vertices.add(new PVector(tx,ty,tz));
  }
  void assignMaterial(int id){
    materialId = id;
  }
  PVector getNormal(PVector posOnObj){
    return normal;
  }
  float dotWithNormal(PVector norm, PVector ray){
    float coeff = normal.dot(ray);
    return coeff;
  }
  float isIntersects(PVector rayorigin, PVector raydir){
    return 0;
  }
}

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