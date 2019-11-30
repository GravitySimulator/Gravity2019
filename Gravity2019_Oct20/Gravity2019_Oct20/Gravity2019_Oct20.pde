// Gravity2019_Oct20 A. Kozma, T. Lichtenberg, D. Parson
// This B version has Parson's integration of Angela's stage 1
// work with Todd's 3D planets, also added ability to add planets on the fly.
// FPDC-funded research project, interactive gravity simulator
// for planetarium dome, initial rough draft.

import java.lang.Math ;  // use double for precision
import java.util.LinkedList ;  // collection of planets. Should they sort() for display?
import oscP5.*;
import netP5.*;
import java.util.*;
import java.util.concurrent.ConcurrentLinkedQueue;

OscP5 oscP5;
NetAddress myRemoteLocation;

// TreeMap sorts brush names in alphabetical order.
TreeMap<String, SolarBody> allshapes = new TreeMap<String, SolarBody>();
TreeMap<String, SolarBody> showshapes = new TreeMap<String, SolarBody>();

// Use unitCircle to compute ellipses for planetary orbits.
// Stretch space using scale(X,Y) and rotate(angularOffset),
// followed by modelX() and modelY(), to find points in an
// elliptical orbit. Enclose all of that it pushMatrix()/
// popMatrix(). Use doubles for precision.
// for a demo of how this works.
int stepsInUnitCircle = 1440 ;  // for now. Angles are in radians.
double [] unitCircleX = new double [ stepsInUnitCircle ];
double [] unitCircleY = new double [ stepsInUnitCircle ];
int xcenterOfOrbits, ycenterOfOrbits ; // default width/2, height/2
LinkedList<Planet> bodies = new LinkedList<Planet>();

int size = 10;
int numOne, numTwo, numThree, numFour, numFive, numSix, numSeven, numEight;

//Planet Distance in km
float mercury = 59223859.2;
float venus = 108147916.8;
float earth = 149668992.0;
float mars = 227883110.4;
float jupiter = 778278758.4;
float saturn = 1426683456.0;
float uranus = 2870586892.8;
float neptune = 4498438348.8;

double [] orbits = {
  0.0, 59223859.2, 108147916.8, 149668992.0, 227883110.4, 778278758.4, 1426683456.0, 2870586892.8, 4498438348.8
};
float [] diameter = {1392530, 4879, 12104, 12756, 6792, 142984, 120536, 51118, 49528};
boolean usingSqrt = false;

String planetCommand = "";

//camera variables
float xeye, yeye, zeye;
int minimumZ, maximumZ;
// Next 3 variables rotate the world from the camera's point of view.
float worldxrotate = 0.0, worldyrotate = 0.0 ; 
/* , worldzrotate = 0.0 ; ROTATING POV AROUND Z IS CONFUSING */
// Some basic symbolic constants.
final float degree = radians(1.0), around = radians(360.0);

String [] commandStrings = {
    "Square", "Linear", "Mercury", "Venus", "Earth",
    "Mars", "Jupiter", "Saturn", "Uranus", "Neptune",
    "West", "East", "North", "South", "Forwards", 
    "Backwards", "Reset"
};
HashSet<String> commandNames = new HashSet<String>(); // copy of commandStrings
final float noRotateB = Float.MAX_VALUE ; // in this case do not reverse rotation at bound

// oscEvent runs in a different thread, so send its data through a thread-safe queue to draw()
class ClientMessage {
  final String clientIP ;
  final int clientPort ;
  final String command ;  // "client" "noteon" "noteoff"
  // Parson 11/27 add these two fields planetName and planetValue
  final String planetName ;
  final float planetValue ;
  ClientMessage(String clientIP, int clientPort, String command,
    String planetName, float planetValue) {
    this.clientIP = clientIP ;
    this.clientPort = clientPort ;
    this.command = command ;
    this.planetName = planetName ;
    this.planetValue = planetValue ;
  }
  public String toString() {
    return "DEBUG OSC message, clientIP = " + clientIP + ", clientPort = " + clientPort
      + " " + command + ", planetName = " + planetName + ", planetValue = " + planetValue ;
  }
}

// This Queue brings client OSC messages to the Processing GUI thread:
final ConcurrentLinkedQueue<ClientMessage> IncomingOSCqueue = new ConcurrentLinkedQueue<ClientMessage>();
// This set used to keep a set of client IP:port pairs:
final Set<ClientMessage> ClientIPset = Collections.synchronizedSet(new HashSet<ClientMessage>());

void setup() {
  fullScreen(P3D); // Use P3D for modelX(), modelY() to work. 
  xcenterOfOrbits = width/2 ;
  ycenterOfOrbits = height/2 ;
  background(0);
  maximumZ = 8000;  //height / 2 ;  // front of the scene
  minimumZ = -8000;  //- height / 2 ;  // back of the scene
  rectMode(CENTER);    // align all possibilities to center
  ellipseMode(CENTER);
  imageMode(CENTER);
  shapeMode(CENTER);
  colorMode(HSB, 360, 100, 100, 100); // saturate for the dome
  for (int unitstep = 0 ; unitstep < unitCircleX.length ; unitstep++) {
    double angle = unitstep * TWO_PI / unitCircleX.length ;
    // sin(angle) = y / hypotenuse = y / 1.0 for unit circle
    // cos(angle) = x / hypotenuse = x / 1.0 for unit circle
    unitCircleX[unitstep] = Math.cos(angle);
    unitCircleY[unitstep] = Math.sin(angle);
    // println("SETUP angle " + angle + ", unitCircleX[unitstep] " + unitCircleX[unitstep] + ", unitCircleY[unitstep] = " + unitCircleY[unitstep]);
  }
  //camera functions
  xeye = width / 2 ;
  yeye = height / 2 ;
  zeye = (height*2) /* / tan(PI*30.0 / 180.0) */ ;
  // Next two lines added by Parson 11/27/2019
  oscP5 = new OscP5(this,12003);  // Start the OSC/UDP server
  myRemoteLocation = new NetAddress("127.0.0.1",12003);
  
}

void draw() {
  processOSCevents();
  background(0);
  pushMatrix();
  // Parson - I moved these here so they come up first time OK, rebuild only as needed. 
  if(squared && (!lastsquared || updateDisplay)) {
    bodies.clear();
    Sqrt();
    lastsquared = true ;
    updateDisplay = false;
  }
  else if((!squared) && (lastsquared || updateDisplay)) {
    bodies.clear();
    Linear(); 
    lastsquared = false ;
    updateDisplay = false;
  }
  //translate(xcenterOfOrbits, ycenterOfOrbits); // 0,0 is at the heart of the sun
  moveCameraRotateWorldKeys();  // Parson trying to get rotate space working
  translate(xcenterOfOrbits, ycenterOfOrbits); // 0,0 is at the heart of the sun
  // Normally, do real application stuff here.
  for (Planet body : bodies) {
    pushMatrix();
    pushStyle();  // safeguard against planet's grphics spilling out
    body.display();
    body.move();
    popStyle();
    popMatrix();
  }
  
  popMatrix();
  // Apply clipping circle, then end of draw()
}

/* incoming osc message are forwarded to the oscEvent method. */
// oscEvent runs in an OSC thread, so send command via a thread-safe queue
void oscEvent(OscMessage theOscMessage) {
  String addrstr = theOscMessage.addrPattern().trim();
  Object [] args = theOscMessage.arguments();
  if (addrstr != null && addrstr.startsWith("/Gravity2019_Oct20/")
     ) {// && args.length == 4) { // Parson changed from 3 to 4 11/27 per below
    String cmd = addrstr.substring(addrstr.lastIndexOf('/')+1).trim();
    String clientip = (String) args[0];
    int clientport = ((Integer)args[1]).intValue();
    String planetName = (String) args[2];
    float planetValue = ((Float)args[3]).floatValue();
    planetName = planetCommand;
    ClientMessage msg = new ClientMessage(clientip.trim(), clientport,
      cmd.trim(), planetName.trim(), planetValue);
    IncomingOSCqueue.add(msg);
  } else {
    println("SERVER SEES UNKNOWN INCOMING OSC MESSAGE: " + addrstr + ", args.length " + args.length);
  }
}

// processOSCevents() runs in the Processing draw()'s thread
void processOSCevents() {
  while (IncomingOSCqueue.size() > 0) {
    ClientMessage message = IncomingOSCqueue.poll();
    if (message != null) {
      // println("DEBUG CLIENT CONTACT! " + message.toString());
      if ("client".equals(message.command)) {
        println("DEBUG CLIENT REGISTRATION! " + message.toString());
        // TODO register and respond to client device
        sendPlanets(message.clientIP, message.clientPort);
        ClientIPset.add(message);
        // This is the only server-to-client message in Fall 2019 Gravity Sim
        OscMessage myMessage = new OscMessage("/Gravity2019_Oct20/server");
        NetAddress cliRemoteLocation = new NetAddress(message.clientIP,message.clientPort);
        // Added Parson 11/27/2019 Client expects a String planet and an Integer number
        myMessage.add("DEBUG TEST PLANET");  // Parson DEBUG
        myMessage.add(new Integer(1)); // PARSON DEBUG
        oscP5.send(myMessage, cliRemoteLocation);
      } else {
        // Added else clause Parson 11/27/2019
        println("DEBUG FOR ANGELA incoming planet message: " + message);
        //SolarBody planet = allshapes.get(message.planetName);
        String planet= "";
        planetCommand = planet;
        if (planet == null) {
          println("planetName: " + planet);
          println("ERROR, client send command '" + message.command + "' for invalid planet: "
            + message.planetName + " " + message.planetValue);
        } else if (message.command.equals("Square")){
              bodies.clear();
              Sqrt();
              squared = true;
              lastsquared = true ;
              updateDisplay = false;             
        } else if (message.command.equals("Linear")){
              bodies.clear();
              Linear();
              squared = false;
              lastsquared = false ;
              updateDisplay = false;
        }else if (message.command.equals("Mercury")){
            if(one == true){
             one = false; 
             updateDisplay = true;
             numOne = 1;
           }
           else if(one == false) {
             one = true;
             updateDisplay = true;
             numOne = 0;
           }
        }else if (message.command.equals("Venus")){
           if(two == true){
             two = false; 
             updateDisplay = true;
             numTwo = 2;
           }
           else if(two == false) {
             two = true;
             updateDisplay = true;
             numTwo = 0;
           }
        }else if (message.command.equals("Earth")){
           if(three == true){
             three = false;
             updateDisplay = true;
             numThree = 3;
           }
           else if(three == false) {
             three = true;
             updateDisplay = true;
             numThree = 0;
           }
        }else if (message.command.equals("Mars")){
          if(four == true){
             four = false; 
             updateDisplay = true;
             numFour = 4;
           }
         else if(four == false) {
             four = true;
             updateDisplay = true;
             numFour = 0;
           }
       }else if (message.command.equals("Jupiter")){
         if(five == true){
             five = false; 
             updateDisplay = true;
             numFive = 5;
           }
         else if(five == false) {
             five = true;
             updateDisplay = true;
             numFive = 0;
           }
       }else if (message.command.equals("Saturn")){
         if(six == true){
             six = false; 
             updateDisplay = true;
             numSix = 6;
           }
         else if(six == false) {
             six = true;
             updateDisplay = true;
             numSix = 0;
           }
       }else if (message.command.equals("Uranus")){
         if(seven == true){
             seven = false; 
             updateDisplay = true;
             numSeven = 7;
           }
         else if(seven == false) {
             seven = true;
             updateDisplay = true;
             numSeven = 0;
           }
       }else if (message.command.equals("Neptune")){
         if(eight == true){
             eight = false; 
             updateDisplay = true;
             numEight = 8;
           }
         else if(eight == false) {
             eight = true;
             updateDisplay = true;
             numEight = 0;
           }
       }else if (message.command.equals("West")){
         xeye -= 10 ;
       }else if (message.command.equals("East")){
         xeye += 10 ;
       }else if (message.command.equals("North")){
         yeye -= 10 ;
       }else if (message.command.equals("South")){
         yeye += 10 ;
       }else if (message.command.equals("Forwards")){
         zeye -= 100 ;
       }else if (message.command.equals("Backwards")){
         zeye += 100 ;
       }else if (message.command.equals("Reset")){
         xeye = width / 2 ;
         yeye = height / 2 ;
         zeye = (height*2) /* / tan(PI*30.0 / 180.0) */ ;
         worldxrotate = worldyrotate = 0 ;
       }else {
         if (showshapes.get(message.planetName) == null) {
           println("WARNING, client send command '" + message.command + "' for invisible brush: "
             + message.planetName + " " + message.planetValue);
           }
       }
      }
    }
  }
}

void sendPlanets(String clientip, int clientport) {
  // println("DEBUG sendBrushes setup() runs in thread: " + Thread.currentThread().toString());
  NetAddress cliRemoteLocation = new NetAddress(clientip,clientport);
    for (String brname : allshapes.keySet()) {
    // println("DEBUG BRUSH: " + brname);
    String padname = brname ;
    int visible = (showshapes.get(brname) != null) ? 1 : 0 ;
    OscMessage myMessage = new OscMessage("/Gravity2019_Oct20/server");
    myMessage.add(padname);
    myMessage.add(new Integer(visible)); // brush is not visible; 1 would be visible
    oscP5.send(myMessage, cliRemoteLocation);
  }
}

void Sqrt() {
  pushMatrix();
  noFill();
  double maxWidth = width/2 - 50.0; //width-10.0 ;
  double diaWidth = width/80;
  double sqrtMax = Math.sqrt(orbits[orbits.length-1]);
  double diaMax = Math.sqrt(diameter[diameter.length-1]);
  for (int i = 0 ; i < orbits.length ; i++) {
    float sqrtDistance = (float)((Math.sqrt(orbits[i])/sqrtMax) * maxWidth) ;
    float sqrtDiameter = (float)((Math.sqrt(diameter[i])/diaMax)* diaWidth); 
      ellipse(0, 0, sqrtDistance, sqrtDistance);
      /*
      Planet(int Hue, int Sat, int Bright, float mass, float size, float speed,
      float directionx, float directiony, float locationx, float locationy,
      boolean isInOrbit, int stepInOrbit, float xOrbitDistanceFromSun,
      float yOrbitDistanceFromSun, float orbitAngle) {
      */
      if(i == 0) {
      //Sun
      bodies.add(new Planet(57, 95, 99, 1.0, sqrtDiameter, -.75, 1.0, 1.0, 1.0, 1.0,
        true, 0, 0, 0, 0));
      }
      else if(i == 1 && numOne == 1) {
        println("In Mercury Sqrt");
      //Mercury 
      bodies.add(new Planet(31, 61, 66, 1.0, sqrtDiameter, -4.787, 1.0, 1.0, 1.0, 1.0,
        true, 0, sqrtDistance, sqrtDistance, HALF_PI / -20.0));
      }
      else if(i == 2 && numTwo == 2) {
      //Venus
      bodies.add(new Planet(31, 92, 81, 1.0, sqrtDiameter, -3.502, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/4, sqrtDistance, sqrtDistance, HALF_PI / -20.0));
      }
      else if(i == 3 && numThree == 3) {
      //Earth
      bodies.add(new Planet(205, 76, 94, 1.0, sqrtDiameter, -2.978, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/3, sqrtDistance, sqrtDistance, HALF_PI / -20.0));
      }
      else if(i == 4 && numFour == 4) {
      //Mars
      bodies.add(new Planet(10, 90, 80, 1.0, sqrtDiameter, -2.4077, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/2, sqrtDistance, sqrtDistance, HALF_PI / -20.0));
      }
      else if(i == 5 && numFive == 5) {
      //Jupiter
      bodies.add(new Planet(41, 64, 88, 1.0, sqrtDiameter, -1.307, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/3, sqrtDistance, sqrtDistance, HALF_PI / -20.0));
      }
      else if(i == 6 && numSix == 6) {
      //Saturn
      bodies.add(new Planet(53, 75, 91, 1.0, sqrtDiameter, -.969, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/6, sqrtDistance, sqrtDistance, HALF_PI / -20.0));
      }
      else if(i == 7 && numSeven == 7) {
      //Uranus 
      bodies.add(new Planet(181, 35, 97, 1.0, sqrtDiameter, -.681, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/5, sqrtDistance, sqrtDistance, HALF_PI / -20.0));
      }
      else if(i == 8 && numEight == 8) {
      //Neptune
      bodies.add(new Planet(220, 79, 91, 1.0, sqrtDiameter, -.543, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/4, sqrtDistance, sqrtDistance, HALF_PI / -20.0));
      }
    }
  popMatrix();
}

void Linear() {
  pushMatrix();
  noFill();
  double maxWidth = width - 10.0; //width-10.0 ;
  double diaWidth = width/80;
  double linearRatio = maxWidth / orbits[orbits.length-1];
  double diaRatio = diaWidth / diameter[diameter.length-1];
  for (int i = 0 ; i < orbits.length ; i++) {
    float linearDistance = (float)(linearRatio*orbits[i]);
    float linearDiameter = (float)(diaRatio * diameter[i]);
    float sunDiameter = (float)((diaRatio * diameter[0])/2);
      ellipse(0, 0, linearDistance, linearDistance);
      /*
      Planet(int Hue, int Sat, int Bright, float mass, float size, float speed,
      float directionx, float directiony, float locationx, float locationy,
      boolean isInOrbit, int stepInOrbit, float xOrbitDistanceFromSun,
      float yOrbitDistanceFromSun, float orbitAngle) {
      */
      if(i == 0) {
      //Sun
      bodies.add(new Planet(57, 95, 99, 1.0, linearDiameter, -.75, 1.0, 1.0, 1.0, 1.0,
        true, 0, linearDistance, linearDistance, 0));
      }
      if(i == 1 && numOne == 1) {
      //Mercury 
      bodies.add(new Planet(31, 61, 66, 1.0, linearDiameter, -4.787, 1.0, 1.0, 1.0, 1.0,
        true, 0, linearDistance + sunDiameter, linearDistance + sunDiameter, HALF_PI / -20.0));
      }
      if(i == 2 && numTwo == 2) {
      //Venus
      bodies.add(new Planet(31, 92, 81, 1.0, linearDiameter, -3.502, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/4, linearDistance + sunDiameter, linearDistance + sunDiameter, HALF_PI / -20.0));
      }
      if(i == 3 && numThree == 3) {
      //Earth
      bodies.add(new Planet(205, 76, 94, 1.0, linearDiameter, -2.978, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/3, linearDistance + sunDiameter, linearDistance + sunDiameter, HALF_PI / -20.0));
      }
      if(i == 4 && numFour == 4) {
      //Mars
      bodies.add(new Planet(10, 90, 80, 1.0, linearDiameter, -2.4077, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/2, linearDistance + sunDiameter, linearDistance + sunDiameter, HALF_PI / -20.0));
      }
      if(i == 5 && numFive == 5) {
      //Jupiter
      bodies.add(new Planet(41, 64, 88, 1.0, linearDiameter, -1.307, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/3, linearDistance + sunDiameter, linearDistance + sunDiameter, HALF_PI / -20.0));
      }
      if(i == 6 && numSix == 6) {
      //Saturn
      bodies.add(new Planet(53, 75, 91, 1.0, linearDiameter, -.969, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/6, linearDistance + sunDiameter, linearDistance + sunDiameter, HALF_PI / -20.0));
      }
      if(i == 7 && numSeven == 7) {
      //Uranus 
      bodies.add(new Planet(181, 35, 97, 1.0, linearDiameter, -.681, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/5, linearDistance + sunDiameter, linearDistance + sunDiameter, HALF_PI / -20.0));
      }
      if(i == 8 && numEight == 8) {
      //Neptune
      bodies.add(new Planet(220, 79, 91, 1.0, linearDiameter, -.543, 1.0, 1.0, 1.0, 1.0,
        true, stepsInUnitCircle/4, linearDistance + sunDiameter, linearDistance + sunDiameter, HALF_PI / -20.0));
      }
    }
  popMatrix();
}
