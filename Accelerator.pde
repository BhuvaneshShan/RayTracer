class Accelerator extends Object{
  
  Object node;
  Object left;
  Object right;
  int level;
  int hitItemSide; //-1 left, +1 right
  
  /*
  Accelerator(Object obj, int tlevel){
    super(obj);
    left = null;
    right = null;
    node = obj;
    level = tlevel;
    hitItemSide = 0;
  }
  */
  Accelerator(ArrayList<Object> objs, int tlevel){
    super(0,0,0);
    if(objs.size()==1){
      this.node = objs.get(0);
      left = null;
      right = null;
      level = tlevel;
      hitItemSide = 0;
      this.pos = this.node.pos;
      this.materialId = this.node.materialId;
    }
    else{
      level = tlevel;
      hitItemSide = 0;
      Box bbox = new Box(objs.get(0));
      PVector centroid = new PVector(objs.get(0).pos.x, objs.get(0).pos.y, objs.get(0).pos.z);
      for(int i=1;i<objs.size();i++){
        centroid.add(objs.get(i).pos);
        bbox.recomputeMinBounds(objs.get(i).getMinBounds());
        bbox.recomputeMaxBounds(objs.get(i).getMaxBounds());
      }
      this.node = bbox;
      centroid.div(objs.size());
      this.pos = centroid;
      ArrayList<Object> leftList = new ArrayList<Object>();
      ArrayList<Object> rightList = new ArrayList<Object>();
      switch(level%3){
        case 0:
          for(int i=0;i<objs.size();i++){
            if(objs.get(i).pos.x < this.pos.x)
              leftList.add(objs.get(i));
            else
              rightList.add(objs.get(i));
          }
          break;
        case 1:
          for(int i=0;i<objs.size();i++){
            if(objs.get(i).pos.y < this.pos.y)
              leftList.add(objs.get(i));
            else
              rightList.add(objs.get(i));
          }
          break;
        case 2:
          for(int i=0;i<objs.size();i++){
            if(objs.get(i).pos.z < this.pos.z)
              leftList.add(objs.get(i));
            else
              rightList.add(objs.get(i));
          }
          break;
      }
      if(leftList.size() == 0){
        for(int i=rightList.size()/2;i<rightList.size();i++){
          leftList.add(rightList.get(i));
        }
        rightList.subList(rightList.size()/2,rightList.size()).clear();
      }else if(rightList.size()==0){
        for(int i=leftList.size()/2;i<leftList.size();i++){
          rightList.add(leftList.get(i));
        }
        leftList.subList(leftList.size()/2,leftList.size()).clear();
      }
      left = new Accelerator(leftList, level+1);
      right = new Accelerator(rightList, level+1);
    }
  }
  /*
  void addObject(Object obj){
    Box bbox = new Box(node);
    bbox.recomputeMinBounds(obj.getMinBounds());
    bbox.recomputeMaxBounds(obj.getMaxBounds());
     
    int side = 0; //side to be inserted for the object. -1 = left, 1 = right 
    
    switch(level%3){
      case 0:
        if(obj.pos.x < node.pos.x){
          side = -1;
        }else{
          side = 1;
        }
        break;
      case 1:
        if(obj.pos.y < node.pos.y){
          side = -1;
        }else{
          side = 1;
        }
        break;
      case 2:
        if(obj.pos.z < node.pos.z){
          side = -1;
        }else{
          side = 1;
        }
        break;
    }
    
    if(side==-1){
      if(left==null){
          left = new Accelerator(obj,level+1);
          right = new Accelerator(node,level+1);
      }else{
        ((Accelerator)left).addObject(obj);
      }
    }else if(side==1){
      if(right==null){
          right = new Accelerator(obj,level+1);
          left = new Accelerator(node, level+1);
      }else{
        ((Accelerator)right).addObject(obj);
      }
    }
   node = bbox;
  }
  */
  void assignMaterial(int id){
    this.materialId = id;
  }
  
  float isIntersects(PVector rayorigin, PVector raydir){
    if(left==null && right==null){
      return node.isIntersects(rayorigin, raydir);
    }else {
      if(node.isIntersects(rayorigin, raydir)!=0){
        float leftroot = left.isIntersects(rayorigin, raydir);
        float rightroot = right.isIntersects(rayorigin, raydir);
        if(leftroot!=0 && rightroot!=0){
          if(leftroot<rightroot){
            hitItemSide = -1;
            return leftroot;
          }else{
            hitItemSide = 1;
            return rightroot;
          }
        }else if(leftroot!=0){
          hitItemSide = -1;
          return leftroot;
        }else{
          hitItemSide = 1;
          return rightroot;
        }
      }else{
        hitItemSide = 0;
        return 0.0;
      }
    }
  }
  
  PVector getNormal(PVector posOnObj){
    if(left==null && right==null){
      return node.getNormal(posOnObj);
    }else{
      if(hitItemSide==-1){
        return left.getNormal(posOnObj);
      }else if(hitItemSide==1){
        return right.getNormal(posOnObj);
      }else{
        return node.getNormal(posOnObj);
      }
    }
  }
  
  float dotWithNormal(PVector norm, PVector ray){
    return norm.dot(ray);
  }
  
  int  getMaterialId(){
    if(left==null && right==null){
      return node.getMaterialId();
    }else{
      if(hitItemSide==-1){
        return left.getMaterialId();
      }else if(hitItemSide==1){
        return right.getMaterialId();
      }else{
        return node.getMaterialId();
      }
    }
  }
  
  PVector getMinBounds(){
    if(left==null && right==null){
      return node.getMinBounds();
    }else{
      if(hitItemSide==-1){
        return left.getMinBounds();
      }else if(hitItemSide==1){
        return right.getMinBounds();
      }else{
        return node.getMinBounds();
      }
    }
  }
  
  PVector getMaxBounds(){
    if(left==null && right==null){
      return node.getMaxBounds();
    }else{
      if(hitItemSide==-1){
        return left.getMaxBounds();
      }else if(hitItemSide==1){
        return right.getMaxBounds();
      }else{
        return node.getMaxBounds();
      }
    }
  }
}