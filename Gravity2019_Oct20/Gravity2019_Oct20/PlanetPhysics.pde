class MovingBodyPhysics {
  Planet pl ;
  MovingBodyPhysics(Planet myplanet) {
    this.pl = myplanet ;
  }
  void movePlanet() {
    if (pl.isInOrbit) {
      if (pl.speed >= 0) {
        pl.stepInOrbit = pl.stepInOrbit+pl.speed ;
      } else {
        pl.stepInOrbit = pl.stepInOrbit+unitCircleX.length+pl.speed ;
        // step backwards
      }
      // Since stepInOrbit is a float, we cannot just use % for wraparound.
      while (pl.stepInOrbit >= unitCircleX.length) {
        pl.stepInOrbit -= unitCircleX.length ;
      }
      while (pl.stepInOrbit < 0) {
        pl.stepInOrbit += unitCircleX.length ;
      }
      int sio = int(pl.stepInOrbit);
      pushMatrix();
      // DEBUG? rotateX(worldxrotate); rotateY(worldyrotate); rotateZ(worldzrotate);
      rotate(pl.orbitAngle);  // Must rotate before scale to warp space.
      
      scale(pl.xOrbitDistanceFromSun, pl.yOrbitDistanceFromSun);
      
      
      translate((float)unitCircleX[sio], (float)unitCircleY[sio]);
      
      pl.locationx = modelX(0, 0, 0) - xcenterOfOrbits ; // model() is in global coord
      pl.locationy = modelY(0, 0, 0) - ycenterOfOrbits ; // our 0,0 is middle of display
      //println("DEBUG stepInOrbit = " + stepInOrbit + ", unitCircleX[stepInOrbit] = " + unitCircleX[stepInOrbit] + ", unitCircleY[stepInOrbit] " + unitCircleX[stepInOrbit]);
      popMatrix();
    } else {
      println("Non-orbiting trajectories not yet supported.");
      exit();
    }
  }
}
  
  
