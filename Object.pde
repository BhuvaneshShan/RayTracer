Object CurrentObject;
HashMap<String, Object> NamedObjects;
Polygon tempPolygon;
ArrayList<Object> CurrentList;
Stack ListStartIndices;
boolean AddToList = false;

abstract class Object{
  PVector pos = new PVector(0,0,0);
  int materialId=0;
  
  Object(float tx, float ty, float tz){
    pos.x = tx; pos.y = ty; pos.z = tz;
    
  }  
  Object(Object obj){
    this.pos = obj.pos;
    this.materialId = obj.materialId;
    
  }
  /*void setTransMatrix(PMatrix3D topOfStack){
    printlg("SetTransMat:");
    topOfStack.print();
    invTransMatrix = topOfStack.get();
    invTransMatrix.invert();
    invTransMatrix.print();
  }*/
  
  abstract void assignMaterial(int id);
  abstract float isIntersects(PVector rayorigin, PVector raydir);
  abstract PVector getNormal(PVector posOnObj);
  abstract float dotWithNormal(PVector norm, PVector refrdir);
  abstract int  getMaterialId();
  abstract PVector getMinBounds();
  abstract PVector getMaxBounds();
}

class Instance extends Object{
  PMatrix3D invTransMatrix; //inverse of top of stack when instance is created
  Object obj;
  Box boundingBox;
  
  Instance(PMatrix3D topOfStack, Object tObj){
    super(tObj);
    invTransMatrix = topOfStack.get();
    invTransMatrix.invert();
    obj = tObj;
  }
  
  Instance(Instance i){
    super(i);
    this.invTransMatrix = i.invTransMatrix;
    this.obj = i.obj;
    this.boundingBox = i.boundingBox;
  }
  
  PVector getMinBounds(){
    return this.boundingBox.getMinBounds();
  }
  PVector getMaxBounds(){
    return this.boundingBox.getMaxBounds();
  }
  
  PVector getTransformedVector(PVector vector){
    //PVector transformed = new PVector();
    //invTransMatrix.mult(vector,transformed);
    //return transformed;
    float[] gmat = new float[16];
    invTransMatrix.get(gmat);
    PVector fin = new PVector(vector.x + gmat[3], vector.y + gmat[7], vector.z + gmat[11]);
    return fin;
  }
  PVector getInvTransVector(PVector vector){
    PVector transformed = new PVector();
    invTransMatrix.mult(vector,transformed);
    return transformed;
  }
  PVector getAdjointTransVector(PVector vector){
    PVector transformed = new PVector();
    PMatrix3D adjoint = invTransMatrix.get();
    adjoint.transpose();
    adjoint.mult(vector, transformed);
    return transformed;
  }
  PVector getScaledTx(PVector vector){
    float[] gmat = new float[16];
    invTransMatrix.get(gmat);
    PVector fin = new PVector(vector.x * gmat[0], vector.y * gmat[5], vector.z * gmat[10]);
    return fin;
  }
  float isIntersects(PVector rayorigin, PVector raydir){
    PVector rayOrg = getInvTransVector(rayorigin);
    PVector rayDir = getAdjointTransVector(raydir);
    rayDir.normalize();
    return obj.isIntersects(rayOrg,rayDir);
  }
  
  void assignMaterial(int id){
    materialId = id;
  }
  int getMaterialId(){
    return obj.getMaterialId();
  }
  PVector getNormal(PVector posOnObj){
    return getAdjointTransVector(PVector.sub(posOnObj,obj.pos)).normalize();
  }
  float dotWithNormal(PVector norm, PVector ray){
    return norm.dot(ray);
  }
  
}


class Sphere extends Object{
  float radius;
  Sphere(float tr, float tx,float ty, float tz){
    super(tx,ty,tz);
    radius = tr;
  }
  Sphere(Sphere s){
    super(s);
    this.radius = s.radius;
  }
  float isIntersects(PVector rayorigin, PVector raydir){
    //printlg("Sphre ray Origin:"+rayorigin.x+","+rayorigin.y+","+rayorigin.z);
    //printlg("Sphre Trans Origin:"+txrayorigin.x+","+txrayorigin.y+","+txrayorigin.z);
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
   int getMaterialId(){
    return materialId;
  }
  PVector getMinBounds(){
    return new PVector(this.pos.x - radius, this.pos.y - radius, this.pos.z - radius);
  }
  PVector getMaxBounds(){
    return new PVector(this.pos.x + radius, this.pos.y + radius, this.pos.z + radius);
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
  MovingSphere(MovingSphere s){
    super(s);
    this.radius = s.radius;
    this.startPos = s.startPos;
    this.endPos = s.endPos;
    this.movingDir = s.movingDir;
    this.curRandomizedTime = s.curRandomizedTime;
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
   int getMaterialId(){
    return materialId;
  }
  PVector getMinBounds(){
    return new PVector(this.startPos.x - radius, this.startPos.y - radius, this.startPos.z - radius);
  }
  PVector getMaxBounds(){
    return new PVector(this.endPos.x + radius, this.endPos.y + radius, this.endPos.z + radius);
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
  Triangle(Triangle t){
    super(t);
    this.vertices = t.vertices;
    this.normal = t.normal;
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
  }
  
  PVector getMinBounds(){
    PVector min = new PVector(MAX_FLOAT, MAX_FLOAT, MAX_FLOAT);
    for(int i=0; i<vertices.size();i++){
      if(vertices.get(i).x<min.x)
        min.x = vertices.get(i).x;
      if(vertices.get(i).y<min.y)
        min.y = vertices.get(i).y;
      if(vertices.get(i).z<min.z)
        min.z = vertices.get(i).z;
    }
    return min;
  }
  PVector getMaxBounds(){
    PVector max = new PVector(-MAX_FLOAT, -MAX_FLOAT, -MAX_FLOAT);
     for(int i=0; i<vertices.size();i++){
      if(vertices.get(i).x > max.x)
        max.x = vertices.get(i).x;
      if(vertices.get(i).y > max.y)
        max.y = vertices.get(i).y;
      if(vertices.get(i).z > max.z)
        max.z = vertices.get(i).z;
    }
    return max;
  }
   int getMaterialId(){
    return materialId;
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
      printlg("hit "+RTracer.tx+","+RTracer.ty+" point:"+point.x+","+point.y+","+point.z+" with vals:"+x+":"+y);
      
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
    //  printlg("hit "+RTracer.tx+","+RTracer.ty+" point:"+point.x+","+point.y+","+point.z+" with vals:"+abxap.z+":"+bcxbp.z+":"+caxcp.z);
      
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
    super(temp); // this was previously super(0,0,0)
    this.vertices = temp.vertices;
    this.normal = temp.normal;
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
  PVector getMinBounds(){
    PVector min = new PVector(MAX_FLOAT, MAX_FLOAT, MAX_FLOAT);
    for(int i=0; i<vertices.size();i++){
      if(vertices.get(i).x<min.x)
        min.x = vertices.get(i).x;
      if(vertices.get(i).y<min.y)
        min.y = vertices.get(i).y;
      if(vertices.get(i).z<min.z)
        min.z = vertices.get(i).z;
    }
    return min;
  }
  PVector getMaxBounds(){
    PVector max = new PVector(-MAX_FLOAT, -MAX_FLOAT, -MAX_FLOAT);
     for(int i=0; i<vertices.size();i++){
      if(vertices.get(i).x > max.x)
        max.x = vertices.get(i).x;
      if(vertices.get(i).y > max.y)
        max.y = vertices.get(i).y;
      if(vertices.get(i).z > max.z)
        max.z = vertices.get(i).z;
    }
    return max;
  }
   int getMaterialId(){
    return materialId;
  }
}

class Box extends Object{
  PVector min;
  PVector max;
  Box(float xmin, float ymin,float zmin, float xmax, float ymax,float zmax){
    super((xmin+xmax)/2,(ymin+ymax)/2,(zmin+zmax)/2);
    min = new PVector(xmin,ymin,zmin);
    max = new PVector(xmax, ymax, zmax);
  }
  Box(Box box){
    super(box);
    this.min = box.min;
    this.max = box.max;
  }
  Box(Object obj){
    super(obj);
    this.min = obj.getMinBounds();
    this.max = obj.getMaxBounds();
  }
  float isIntersects(PVector rayorigin, PVector raydir){
     return intersect(rayorigin, raydir);
    //get intersection
    /*PVector frontPlane = new PVector(0,0,max.z);
    float root = (frontPlane.sub(rayorigin)).dot(raydir); 
    if(root>0){
      PVector hitPoint  = PVector.add(rayorigin,PVector.mult(raydir,root));
      if( isWithin(min.x,hitPoint.x,max.x))
        if(isWithin(min.y,hitPoint.y,max.y))
          return root;
    }
    */
    /*float root = 0;
    if(root==0){
      root = planeIntersection(2, max.z, rayorigin, raydir);
    }if(root==0){
      root = planeIntersection(0, min.x, rayorigin, raydir);
    }if(root==0){
      root = planeIntersection(0, max.x, rayorigin, raydir);
    }if(root==0){
      root = planeIntersection(1, min.y, rayorigin, raydir);
    }if(root==0){
      root = planeIntersection(1, max.y, rayorigin, raydir);
    }if(root==0){
      root = planeIntersection(2, min.z, rayorigin, raydir);
    }*/
    //return root;
  }
  /*
  float planeIntersection(int planeType, float coord, PVector rayorigin, PVector raydir){
    if(planeType == 0){ //x plane
      PVector plane = new PVector(coord,0,0);
      float root = (plane.sub(rayorigin)).dot(raydir); 
      if(root>0){
        PVector hitPoint  = PVector.add(rayorigin,PVector.mult(raydir,root));
        if( isWithin(min.z,hitPoint.z,max.z))
          if(isWithin(min.y,hitPoint.y,max.y))
            return root;
      }
    }else if(planeType==1){ //y plane
      PVector plane = new PVector(0,coord,0);
      float root = (plane.sub(rayorigin)).dot(raydir); 
      if(root>0){
        PVector hitPoint  = PVector.add(rayorigin,PVector.mult(raydir,root));
        if( isWithin(min.z,hitPoint.z,max.z))
          if(isWithin(min.x,hitPoint.x,max.x))
            return root;
      }
    }else if(planeType==2){ //z plane
        PVector plane = new PVector(0,0,coord);
      float root = (plane.sub(rayorigin)).dot(raydir); 
      if(root>0){
        PVector hitPoint  = PVector.add(rayorigin,PVector.mult(raydir,root));
        if( isWithin(min.x,hitPoint.x,max.x))
          if(isWithin(min.y,hitPoint.y,max.y))
            return root;   
      }
    }
    return 0.0;
  }*/
  float intersect(PVector rayorg, PVector raydir){
    float tnear = -MAX_FLOAT;
    float tfar = MAX_FLOAT;
    //X planes
    if(raydir.x==0){
      //ray parallel to plane
      if(!isWithin(min.x,rayorg.x,max.x)){
        return 0.0;
      }
    }else{
      //ray not parallel to plane
      float t1 = (min.x - rayorg.x)/raydir.x;
      float t2 = (max.x - rayorg.x)/raydir.x;
      if(t1>t2){ float temp = t1; t1 = t2; t2 = temp; }
      if(t1 > tnear) {tnear = t1;}
      if(t2 < tfar) {tfar = t2;}
      if(tnear>tfar){return 0.0;}
      if(tfar<0){return 0.0;}
    }
    
    //Y planes
    if(raydir.y==0){
      //ray parallel to plane
      if(!isWithin(min.y,rayorg.y,max.y)){
        return 0.0;
      }
    }else{
      //ray not parallel to plane
      float t1 = (min.y - rayorg.y)/raydir.y;
      float t2 = (max.y - rayorg.y)/raydir.y;
      if(t1>t2){ float temp = t1; t1 = t2; t2 = temp; }
      if(t1 > tnear) {tnear = t1;}
      if(t2 < tfar) {tfar = t2;}
      if(tnear>tfar){return 0.0;}
      if(tfar<0){return 0.0;}
    }
     
    //Z planes
    if(raydir.z==0){
      //ray parallel to plane
      if(!isWithin(min.z,rayorg.z,max.z)){
        return 0.0;
      }
    }else{
      //ray not parallel to plane
      float t1 = (min.z - rayorg.z)/raydir.z;
      float t2 = (max.z - rayorg.z)/raydir.z;
      if(t1>t2){ float temp = t1; t1 = t2; t2 = temp; }
      if(t1 > tnear) {tnear = t1;}
      if(t2 < tfar) {tfar = t2;}
      if(tnear>tfar){return 0.0;}
      if(tfar<0){return 0.0;}
    }
    return tnear;
  }
  
  PVector getMinBounds(){
    return min;
  }
  PVector getMaxBounds(){
    return max;
  }
  void recomputeMinBounds(PVector minVals){
    if(minVals.x < min.x){
      min.x = minVals.x;
      pos.x = (min.x+max.x)/2;
    }
    if(minVals.y < min.y){
      min.y = minVals.y;
      pos.y = (min.y+max.y)/2;
    }
    if(minVals.z < min.z){
      min.z = minVals.z;
      pos.z = (min.z+max.z)/2;
    }
  }
  void recomputeMaxBounds(PVector maxVals){
    if(maxVals.x > max.x){
      max.x = maxVals.x;
      pos.x = (min.x+max.x)/2;
    }
    if(maxVals.y > max.y){
      max.y = maxVals.y;
      pos.y = (min.y+max.y)/2;
    }
    if(maxVals.z > max.z){
      max.z = maxVals.z;
      pos.z = (min.z+max.z)/2;
    }
  }
   boolean isWithin(float min, float x, float max){
    if(x<=max && x>=min)
      return true;
    else
      return false;
  }
  void assignMaterial(int id){
    materialId = id;
  }
  PVector getNormal(PVector posOnObj){
    PVector bottomRight = new PVector(min.x,min.y,max.z);
    PVector bottomLeft = new PVector(max.x,min.y,max.z);
    PVector topRight = new PVector(max.x,max.y,max.z);
    return PVector.sub(topRight,bottomRight).cross(PVector.sub(bottomRight,bottomLeft));
  }
  float dotWithNormal(PVector norm, PVector ray){
    return norm.dot(ray);
  }
   int getMaterialId(){
    return materialId;
  }
}


class ObjList extends Object{
  ArrayList<Object> objects;
  Box boundingBox;
  
  PVector curNormal;
  int curMaterialId;
  ObjList(){
    super(0,0,0); 
    objects = new ArrayList<Object>();
    boundingBox = new Box(MAX_FLOAT,MAX_FLOAT,MAX_FLOAT,-MAX_FLOAT,-MAX_FLOAT,-MAX_FLOAT);
    curMaterialId = 0;
    curNormal = new PVector();
  }
  ObjList(ObjList ol){
    super(ol); // this was previously super(0,0,0)
    this.objects = ol.objects;
    this.boundingBox = ol.boundingBox;
  }
  void addObject(Object obj){
    objects.add(obj);
    boundingBox.recomputeMinBounds(obj.getMinBounds());
    boundingBox.recomputeMaxBounds(obj.getMaxBounds());
    if(objects.size()==1){
      this.pos = obj.pos;
    }else{
      this.pos.x = (this.pos.x + obj.pos.x)/2;
      this.pos.y = (this.pos.y + obj.pos.y)/2;
      this.pos.z = (this.pos.z + obj.pos.z)/2;
    }
  }
  float isIntersects(PVector rayorigin, PVector raydir){
    if(objects.size() >0 && boundingBox.isIntersects(rayorigin,raydir)>0){
      float minroot = MAX_FLOAT;
      for(int i=0;i<objects.size();i++){
        float root = objects.get(i).isIntersects(rayorigin, raydir);
        if(root>0 && root<minroot){
          minroot = root;
          curMaterialId = objects.get(i).getMaterialId();
          curNormal = objects.get(i).getNormal(PVector.add(rayorigin, PVector.mult(raydir,root)));
        }
      }
      if(minroot == MAX_FLOAT)
        return 0.0;
      else
        return minroot;
    }
    return 0.0;
  }
  PVector getMinBounds(){
    return boundingBox.getMinBounds();
  }
  PVector getMaxBounds(){
    return boundingBox.getMaxBounds();
  }
  void assignMaterial(int id){
    materialId = id;
  }
  PVector getNormal(PVector posOnObj){
    return curNormal;
  }
  float dotWithNormal(PVector norm, PVector ray){
    float coeff = norm.dot(ray);
    return coeff;
  }
  int getMaterialId(){
    return curMaterialId;
  }
}



Object getInstanceOf(Object obj){
  if(obj instanceof Sphere){
    return new Sphere((Sphere)obj);
  }else if(obj instanceof MovingSphere){
    return new MovingSphere((MovingSphere) obj);
  }else if(obj instanceof Triangle){
    return new Triangle((Triangle) obj);
  }else if(obj instanceof Polygon){
    return new Polygon((Polygon) obj);
  }else if(obj instanceof Box){
    return new Box((Box) obj);
  }else{
    return null;
  }
}