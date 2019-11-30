// Gravity2019_Oct20_Android A. Kozma, T. Lichtenberg, D. Parson
// This version is for creating a display screen 
// for the android devices

import java.net.*;
import java.util.* ;
import java.util.concurrent.ConcurrentSkipListMap ;
import oscP5.*;
import netP5.*;

final int networkInterfaceIndex = -1 ;
final String CommandPrefix = "/Gravity2019_Oct20/" ;
OscP5 oscP5 = null ;        // null until client gets a UDP listen port.
NetAddress myRemoteLocation;
NetAddress serverRemoteLocation;
String MYIPADDR = null ;
int MYPORT = 12002 ;  /* Adjust if it fails. */
String SERVERIPADDR = null ;
int SERVERPORT = -1 ; /* Have to enter as data. */
boolean printingScreenSize = true ;
PFont globalFont = null ;
int globalPointSize = 64 ; // 64 works OK for Android Galaxy of 1536 x 2048 pixels

// I am using TreeMap instead of HashMap because it sorts the planet names.
// Version B changes TreeMap to ConcurrentSkipListMap and changes these fields
// accessed in oscEvent() to volatile because oscEvent() runs in the OSC thread.
final ConcurrentSkipListMap<String,Integer> planetnameToVisibility = new ConcurrentSkipListMap<String,Integer>();
// mapPlanetnameToVisibility returns -1 if planet name is not valid.
volatile int timeToMakeCommandMenu = 0 ;  // CommandMenu gets made 1 sec. after last brush datagram
volatile Menu globalMenu = null ;

boolean mapPlanetnameToVisibility(String planetname) {
  Integer result = planetnameToVisibility.get(planetname);
  return(result != null && result.intValue() != 0);
}
// Return an array of brush names in sorted order.
String [] getAllPlanetnames() {
  return planetnameToVisibility.keySet().toArray(new String [0]);
}


void setup() {
   //size(800,1000); // Set to Android size on PC, fullScreen on Android.
   fullScreen();
   globalPointSize = height / 48 ; // Use this for Parson's laptop
  // The CSC Galaxy tablets use 1536 x 2048 pixels, need bigger pointsize
  //fullScreen();
  //globalPointSize = 28;  //64 ; // height / 32 ; // point size 64 on the CSC Android tablet's         //CHANGE THIS PART BACK!!!
  // Get the IP address of this client.
  try {
    int nix = 0 ;
    Enumeration e = NetworkInterface.getNetworkInterfaces();
    while(e.hasMoreElements()) {
      NetworkInterface n = (NetworkInterface) e.nextElement();
      Enumeration ee = n.getInetAddresses();
      while (ee.hasMoreElements()) {
        InetAddress i = (InetAddress) ee.nextElement();
        String ipaddr = i.getHostAddress().toString();
        if (ipaddr.indexOf(".") > 0) {  // It is an IP address, not a MAC address.
          println("One client IPADDR: " + ipaddr);
          if (! (MYIPADDR != null || ipaddr.equals("127.0.0.1")
                || ipaddr.indexOf("localhost") > -1)
                || networkInterfaceIndex > nix) {
            println("SETTING MYIPADDR to " + ipaddr);
            printDEBUG("SETTING MYIPADDR to " + ipaddr);
            MYIPADDR = ipaddr ;
          }
          nix++ ;
        }
      }
    }
  } catch (SocketException sx) {
    printDEBUG("ERROR, SocketException checking IP addresses: " + sx.getMessage());
  }
  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
  if (MYIPADDR != null) {
    myRemoteLocation = new NetAddress(MYIPADDR,MYPORT);
    /* start oscP5, listening for incoming messages at port 12000 */
    try {
      oscP5 = new OscP5(this,MYPORT/*12000*/);
    } catch (Exception xxx) {
      printDEBUG("ERROR, cannot open port " + MYPORT);
      printDEBUG("Change global MYPORT to another value & try again.");
      if (oscP5 != null) {
        oscP5.stop();
      }
      oscP5 = null ;
    }
  } else {
    printDEBUG("ERROR, Cannot get IP address for this client device.");
  }
  background(0);
  oscP5 = new OscP5(this,12002); // Make port 12002 to avoid csc220 conflict.
  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device,
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
  myRemoteLocation = new NetAddress("127.0.0.1",12002);
}

void draw() {
  background(0);
  if (printingScreenSize) {
    displayScreenSize();
    return ;
  }
  if (MYIPADDR == null) {
    printDEBUG("NO CLIENT IP ADDRESS, CANNOT RUN.");
    return ;
  } else if (oscP5 == null) {
    printDEBUG("CANNOT USE MYPORT, CHANGE SETTING & TRY AGAIN: " + MYPORT);
    return ;
  } else if (SERVERIPADDR == null) {
    setServerAddressPort();
  }
  if (timeToMakeCommandMenu != 0 && frameCount >= timeToMakeCommandMenu) {
    globalMenu = new CommandMenu();
    timeToMakeCommandMenu = 0 ;
  }
  if (globalMenu != null) {
    globalMenu.display();
  }
}

void mousePressed() {
  if (printingScreenSize) {
    printingScreenSize = false ;
    return ;
  }
  if (globalMenu != null) {
   //printDEBUG("DEBUG CALL globalMenu.respondToMouseEvent: " + mouseX + "," + mouseY);
   globalMenu.respondToMouseEvent(mouseX, mouseY);
  } else {
    text(" Mouse ignored. ", width/2, height/2);
  }
}

// Send a planet command to server. command is like setX without
// the CommandPrefix, which gets prepended here. Both command
// and plaentName are trim()d here, and may contain padding spaces.
void sendOSCMessage(/* String command,*/ String planetName, float value) {
 /* if (command == null) {
    println("ERROR, missing command in Client sendOSCMessage 1");
    command = "ERROR, missing command in Client sendOSCMessage 1";
  }
  */
  if (planetName == null) {
    println("ERROR, missing planetName in Client sendOSCMessage 1");
    planetName = "ERROR, missing planetName in Client sendOSCMessage 1";
  }
  if (oscP5 != null && SERVERIPADDR != null && SERVERPORT > -1) {
    OscMessage myMessage = new OscMessage(CommandPrefix + planetName.trim());
    myMessage.add(MYIPADDR);
    myMessage.add(new Integer(MYPORT));
    myMessage.add(planetName.trim()); 
    myMessage.add(new Float(value));
    oscP5.send(myMessage, serverRemoteLocation);
  }
}

// This function is only for initially registering the client with
// the server.
void sendOSCMessage(String command, String clientIP, int clientPort) {
  if (command == null) {
    println("ERROR, missing command in Client sendOSCMessage 1");
    command = "ERROR, missing command in Client sendOSCMessage 1";
  }
  if (oscP5 != null && SERVERIPADDR != null && SERVERPORT > -1) {
    OscMessage myMessage = new OscMessage(command);
    myMessage.add(clientIP); 
    myMessage.add(new Integer(clientPort));
    myMessage.add("client connecting");  // ignored
    myMessage.add(new Float(0.0)); // ignored
    oscP5.send(myMessage, serverRemoteLocation);
  }
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  Object [] args = theOscMessage.arguments();
  // oscEvent runs in its own OSC thread, so be careful!!!
  String addr = theOscMessage.addrPattern();
  if ("/Gravity2019_Oct20/server".equals(addr)) {
    String planetname = ((String) args[0]);
    int visibility = ((Integer) args[1]).intValue();
    planetnameToVisibility.put(planetname,visibility);
    println("DEBUG RECVD OSC: " + addr + ":" + planetname
      + ":" + visibility);
    if (globalMenu instanceof SetServerAddressPortMenu) {
      globalMenu = null ;  // a reply came from server, so it's address is set
    }
    timeToMakeCommandMenu = round(frameCount + frameRate) ; // wait a second before making command menu
  } else {
    println("CLIENT SEES UNKNOWN OSC MESSAGE: " + addr);
  }
}

void displayScreenSize() {
  textAlign(LEFT);
  textSize(64);
  text("display size: " + width + " x " + height, 10, height/2);
}

void setServerAddressPort() {
  if (! (globalMenu instanceof SetServerAddressPortMenu)) {
    globalMenu = new SetServerAddressPortMenu();
  }
}

void printDEBUG(String txt) {  // proxy for println on tablet
  textSize(globalPointSize);
  textAlign(LEFT, TOP);
  text(txt,10,height/2);
  println(txt);
}
  



/*ScrollBar scrollbar;
int numItems = 8;
int[] numPlanet = new int[8];

void setup() {
 fullScreen(P2D);
 orientation(PORTRAIT);
 scrollbar = new ScrollBar(0.2 * height * numItems, 0.1 * width);
 numPlanet[0] = 1;
 numPlanet[1] = 2;
 numPlanet[2] = 3;
 numPlanet[3] = 4;
 numPlanet[4] = 5;
 numPlanet[5] = 6;
 numPlanet[6] = 7;
 numPlanet[7] = 8;
 noStroke();
}

void draw() {
 background(255);
 pushMatrix();
 translate(1, scrollbar.translateX);
 for(int i = 0; i < numItems; i++) {
 // fill(map(i, 0, numItems - 1, 200, 0));
  fill(27,245,214);
  rect(20, i * 0.2 * height + 20, width - 40, 0.2 * height - 20);
 }
 popMatrix();
 scrollbar.draw();
}

public void mousePressed() {
 scrollbar.open(); 
}

public void mouseDragged() {
 scrollbar.update(mouseY - pmouseY); 
}

void mouseReleased() {
 scrollbar.close(); 
}

class ScrollBar {
 float totalHeight;
 float translateX;
 float opacity;
 float barWidth;
 
 ScrollBar(float h, float w) {
  totalHeight = h;
  barWidth = w;
  translateX = 0;
  opacity = 0;
 }
 
 void open() {
   opacity = 150;
 }
 
 void close() {
  opacity = 0; 
 }
 
 void update(float dx) {
  if(totalHeight + translateX + dx > height) {
   translateX += dx;
   if(translateX > 0) {
    translateX = 0; 
   }
  }
 }
  void draw() {
   if(0 < opacity) {
    float frac = (height / totalHeight);
    float x = width - 1.5 * barWidth;
    float y = PApplet.map(translateX / totalHeight, -1, 0, height, 0);
    float w = barWidth;
    float h = frac * height;
    pushStyle();
    fill(150, opacity);
    rect(x, y, w, h, 0.2 *w);
    popStyle();
   }  
 } 
} 
*/
