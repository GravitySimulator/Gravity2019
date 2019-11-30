
// Maybe the models as a Planet? Leave open options for alternatives.
interface SolarBody {
  // Show it in its trajectory or orbit.
  void display() ;
  // Advance it in its trajectory or orbit.
  void move();
}

class Planet implements SolarBody {
  int H, S, B ;
  MovingBodyPhysics physics ;
  PlanetAssets assets ;
  // Document unit of measure for these in a later version that does real orbits.
  float mass ;
  float size ;        // size is a function of mass & density. Compute density?
  float speed ;       // pixels per draw() for now. Will change to app units later.
  float directionx ;  // when approaching an orbit in a line
  float directiony ;  // when approaching an orbit in a line
  float locationx ;   // when approaching an orbit in a line OR already in orbit
  float locationy ;   // when approaching an orbit in a line OR already in orbit
  boolean isInOrbit ;
  float stepInOrbit ; // step in unitCircle[0..unitCircle.length-1], with fractional part
  float xOrbitDistanceFromSun ;
  float yOrbitDistanceFromSun ;
  float orbitAngle ;
  // When it attains orbit, speed is in steps within orbital ellipse, should be an int?
  Planet(int hue, int saturation, int brightness, float mass, float size, float speed,
      float directionx, float directiony, float locationx, float locationy,
      boolean isInOrbit, int stepInOrbit, float xOrbitDistanceFromSun,
      float yOrbitDistanceFromSun, float orbitAngle) {
    H = hue ;
    S = saturation ;
    B = brightness ;
    this.mass = mass ;
    this.size = size ;
    this.speed = speed ;
    this.directionx = directionx ;
    this.directiony = directiony ;
    this.locationx = locationx ;
    this.locationy = locationy ;
    this.isInOrbit = isInOrbit ;
    this.stepInOrbit = stepInOrbit ;
    this.xOrbitDistanceFromSun = xOrbitDistanceFromSun ;
    this.yOrbitDistanceFromSun = yOrbitDistanceFromSun ;
    this.orbitAngle = orbitAngle ;
    if (isInOrbit) {
      int sio = (int)(stepInOrbit); 
      pushMatrix();
      rotate(orbitAngle); // Must rotate before scale to warp space.
      scale(xOrbitDistanceFromSun, yOrbitDistanceFromSun);
      translate((float)unitCircleX[sio], (float)unitCircleY[sio]);
      this.locationx = modelX(0, 0, 0) /*- xcenterOfOrbits*/ ; // model() is in global coord
      this.locationy = modelY(0, 0, 0) /*- ycenterOfOrbits*/ ; // our 0,0 is middle of display
      popMatrix();

    }
    physics = new MovingBodyPhysics(this);    // physics must run in this same thread
    assets = new PlanetAssets(this);
  }
  void display() {
    colorMode(HSB, 360, 100, 100, 100);
    pushMatrix();
    pushMatrix();  // trace orbit around center of display
      // orbit shows up within planet circle unless you move it back a little
      // Parson - planets are going to be 3D using Todd's visuals XXX translate(0, 0, 0);
      rotate(orbitAngle);  // Must rotate before scale to warp space.
      scale(xOrbitDistanceFromSun, yOrbitDistanceFromSun);
      // rotate(orbitAngle);
      noFill();
      stroke(0,0,99,50);
      strokeWeight(4.0/min(xOrbitDistanceFromSun, yOrbitDistanceFromSun));
      ellipse(0, 0, 2, 2);    // This draws the thin orbit ellipse in white.
    popMatrix();
    translate(locationx, locationy);    // x,y location relative to the star
    fill(H,S,B,99);
    // test half brightness
    // fill(H, 50, 50, 99);
    noStroke();
    // circle(0, 0, size);
    pushStyle();
    assets.showPlanetAt_0_0();
    popStyle();
    //sphere(size);
    popMatrix();
    strokeWeight(1);
  }
  void move() {
    physics.movePlanet();
  }     
}
