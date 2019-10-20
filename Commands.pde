// Gravity2019BCommands is a tab in sketch Gravity2019A.
// See comments for Gravity2019A.pde. This source file
// handles command interpretation from KeyPressed or OSC
// networked commands.
boolean squared = false, lastsquared = true ;  // toggle with 'q'
// Parson comment - since squared and linear are mutually exclusive, I am
// replacing linear with (! squared), also keep track of previous state in
// lastquared to eliminate some screen glitch. Make them opposite at startup.
  
void keyPressed() {
  interpretKey(key, keyCode);
  // Parson - am moving all this logic into interpretKey to remove distinction
  // between commands arring via a key vs. commands arriving via OSC.
}

int signum(float num) {
  return ((num >= 0) ? 1 : -1);
}

void moveCameraRotateWorldKeys() {
  if (keyPressed) {
    if (key == 'u') {
      zeye += 10 ;
      //println("DEBUG u " + zeye + ", minZ: " + minimumZ + ", maxZ: " + maximumZ);
    } 
    else if (key == 'U') {
      zeye += 100 ;
      // println("DEBUG U " + zeye + ", minZ: " + minimumZ + ", maxZ: " + maximumZ);
    } 
    else if (key == 'd') {
      zeye -= 10 ;
      //println("DEBUG d " + zeye + ", minZ: " + minimumZ + ", maxZ: " + maximumZ);
    } 
    else if (key == 'D') {
      zeye -= 100 ;
      // println("DEBUG D " + zeye + ", minZ: " + minimumZ + ", maxZ: " + maximumZ);
    } 
    else if (key == 'n') {
      yeye -= 1 ;
    } 
    else if (key == 'N') {
      yeye -= 10 ;
    } 
    else if (key == 's') {
      yeye += 1 ;
    } 
    else if (key == 'S') {
      yeye += 10 ;
    } 
    else if (key == 'w') {
      xeye -= 1 ;
    } 
    else if (key == 'W') {
      xeye -= 10 ;
    } 
    else if (key == 'e') {
      xeye += 1 ;
    } 
    else if (key == 'E') {
      xeye += 10 ;
    } else if (key == 'x') {
      worldxrotate += degree ;
      if (worldxrotate >= around) {
        worldxrotate = 0 ;
      }
    } else if (key == 'X') {
      worldxrotate -= degree ;
      if (worldxrotate < -around) {
        worldxrotate = 0 ;
      }
    } else if (key == 'y') {
      worldyrotate += degree ;
      if (worldyrotate >= around) {
        worldyrotate = 0 ;
      }
    } else if (key == 'Y') {
      worldyrotate -= degree ;
      if (worldyrotate < -around) {
        worldyrotate = 0 ;
      }
    
    }
    else if (mousePressed && key == ' ') {
      xeye = mouseX ;
      yeye = mouseY ;
    }
  }
  // Make sure 6th parameter -- focus in the Z direction -- is far, far away
  // towards the horizon. Otherwise, ortho() does not work.
  //camera(xeye, yeye,  zeye, xeye, yeye,  zeye-signum(zeye-minimumZ)*maximumZ*2 , 0,1,0);
  camera(xeye, yeye,  zeye, xeye, yeye,  Float.MIN_VALUE  , 0,1,0);
    
    // Do not use pushMatrix()-popMatrix() instead of the inverse translate,
    // because popMatrix() would discard the rotations.
    ///*
    if (worldxrotate != 0 || worldyrotate != 0) {
      translate(xcenterOfOrbits, ycenterOfOrbits); // 0,0 is at the heart of the sun
      //translate(width/2, height/2, 0);  // rotate from the middle of the world
      if (worldxrotate != 0) {
        rotateX(worldxrotate);
      }
      if (worldyrotate != 0) {
        rotateY(worldyrotate);
      }
      translate(-xcenterOfOrbits, -ycenterOfOrbits); // Apply the inverse of the above translate.
      // Do not use pushMatrix()-popMatrix() instead of the inverse translate,
      // because popMatrix() would discard the rotations.
  }
  // */
 }


// interpretKey can interpret single-character key commands
// from keyPressed() or a single-char OSC message.
void interpretKey(char key, int keyCode) {
  /*if (squared) {
    noFill();
    //stroke(0);
    //strokeWeight(2);
    // Draw orbits as circles for now, just to get the feel.
    double maxWidth = width-10.0 ;
    double linearRatio = maxWidth / orbits[orbits.length-1];
    double sqrtMax = Math.sqrt(orbits[orbits.length-1]);
    for (int i = 0 ; i < orbits.length ; i++) {
      float linearDistance = (float)(linearRatio*orbits[i]);
      float sqrtDistance = (float)((Math.sqrt(orbits[i])/sqrtMax) * maxWidth) ;
      if (usingSqrt) {
        ellipse(0, 0, sqrtDistance, sqrtDistance);
      //  bodies.set(Planet(1)) = sqrtDistance;
      } 
      else {
        ellipse(0, 0, linearDistance, linearDistance);
      }
    }
  } */
  //turns on/off squared scale 
    if (key == 'q') {
      squared = true ;
    }
    else if (key == 'p') {
      size = size + 5;
    }
    else if (key == 'm') {
      size = size - 5;
      if(size <= 0) {
        size = 1;
      }
    }
   else if (key == 'l') {
     squared = false ; 
   }
   else if (key == 'R') { // Reset POV to starting point.
    xeye = width / 2 ;
    yeye = height / 2 ;
    zeye = (height*2) /* / tan(PI*30.0 / 180.0) */ ;
    worldxrotate = worldyrotate = 0 ;
   }
   /* Parson - moving this logic to draw() to get the effects of ots translate()
      and rotate[X|Y|Z]
  if(squared && ! lastsquared) {
    bodies.clear();
    Sqrt();
    lastsquared = true ;
  }
  else if((!squared) && lastsquared) {
    bodies.clear();
    Linear(); 
    lastsquared = false ;
  }
  */
}

// interpretString can interpret multiple-character key commands
// from keyPressed() or a multiple-char OSC message.
// cmd is the command, arguments can be null or 0-length
// for commands with no arguments.
void interpretString(String cmd, Object [] arguments) {
  
}
