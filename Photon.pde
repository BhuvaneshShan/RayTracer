
int photon_radius = 4;
enum photonTypes{ CAUSTIC, DIFFUSIVE};
// Photon class
public class Photon implements Comparable<Photon>{
  float[] pos;  // 3D position of photon, plus one extra value for nearest neighbor queries
  // YOU WILL WANT TO MODIFY THIS CLASS TO RECORD THE POWER OF A PHOTON
  PVector power;
  
  Photon (float x, float y, float z) {
    pos = new float[4];  // x,y,z position, plus fourth value that is used for nearest neighbor queries
    pos[0] = x;
    pos[1] = y;
    pos[2] = z;
    pos[3] = 0;  // distance squared, used for nearby photon queries
  }
  Photon (PVector position, PVector pow){
    pos = new float[4];  // x,y,z position, plus fourth value that is used for nearest neighbor queries
    pos[0] = position.x;
    pos[1] = position.y;
    pos[2] = position.z;
    pos[3] = 0;
    power = new PVector(pow.x,pow.y, pow.z);
  }
  
  PVector getPos(){
    return new PVector(pos[0],pos[1],pos[2]);
  }
  PVector getPow(){
    return power;
  }

  // Compare two nodes, used in two different circumstances:
  // 1) for sorting along a given axes during kd-tree construction (sort_axis is 0, 1 or 2)
  // 2) for comparing distances when locating nearby photons (sort_axis is 3)
  public int compareTo(Photon other_photon) {
    if (this.pos[sort_axis] < other_photon.pos[sort_axis])
      return (-1);
    else if (this.pos[sort_axis] > other_photon.pos[sort_axis])
      return (1);
    else
      return (0);
  }
}


  
  /*
  photons = new kd_tree();
  
  Photon p = new Photon (x, y, z);
  photons.add_photon (p);
  
  photons.build_tree();
  
  ArrayList<Photon> plist;
  plist = photons.find_near ((float) mouseX, (float) mouseY, 0.0, num_near, 200.0);
  
  */