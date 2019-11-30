import java.net.*;
import java.util.* ;
import java.util.concurrent.ConcurrentSkipListMap ;
import oscP5.*;
import netP5.*;

final int networkInterfaceIndex = -1 ;
final String CommandPrefix = "/paintdome18B/" ;
OscP5 oscP5 = null ;        // null until client gets a UDP listen port.
NetAddress myRemoteLocation;
NetAddress serverRemoteLocation;
String MYIPADDR = null ;
int MYPORT = 12000 ;  /* Adjust if it fails. */
String SERVERIPADDR = null ;
int SERVERPORT = -1 ; /* Have to enter as data. */
boolean printingScreenSize = true ;
PFont globalFont = null ;
int globalPointSize = 64 ; // 64 works OK for Android Galaxy of 1536 x 2048 pixels

// TreeMap (and Java Map objects in general):
// put(Key, Value) is like map[Key] = Value in an array.
// get(Key) is like reading map[Key] in an expression.
// Parson is supplying mapBrushnameToVisibility() below to help you.
// See https://docs.oracle.com/javase/8/docs/api/index.html java.util.TreeMap
// I am using TreeMap instead of HashMap because it sorts the brush names.
// Version B changes TreeMap to ConcurrentSkipListMap and changes these fields
// accessed in oscEvent() to volatile because oscEvent() runs in the OSC thread.
final ConcurrentSkipListMap<String,Integer> brushnameToVisibility = new ConcurrentSkipListMap<String,Integer>();
// mapBrushnameToVisibility returns -1 if brush name is not valid.
volatile int timeToMakeCommandMenu = 0 ;  // CommandMenu gets made 1 sec. after last brush datagram
volatile Menu globalMenu = null ;

boolean mapBrushnameToVisibility(String brushname) {
  Integer result = brushnameToVisibility.get(brushname);
  return(result != null && result.intValue() != 0);
}
// Return an array of brush names in sorted order.
String [] getAllBrushnames() {
  return brushnameToVisibility.keySet().toArray(new String [0]);
}

void setup() {
   size(800,1000); // Set to Android size on PC, fullScreen on Android.
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

// Send a brush command to server. command is like setX without
// the CommandPrefix, which gets prepended here. Both command
// and brushName are trim()d here, and may contain padding spaces.
void sendOSCMessage(String command, String brushName, float value) {
  if (oscP5 != null && SERVERIPADDR != null && SERVERPORT > -1) {
    OscMessage myMessage = new OscMessage(CommandPrefix + command.trim());
    myMessage.add(MYIPADDR);
    myMessage.add(new Integer(MYPORT));
    myMessage.add(brushName.trim()); 
    myMessage.add(new Float(value));
    oscP5.send(myMessage, serverRemoteLocation);
  }
}

// This function is only for initially registering the client with
// the server.
void sendOSCMessage(String command, String clientIP, int clientPort) {
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
  if ("/paintdome18B/server".equals(addr)) {
    String brushname = ((String) args[0]);
    int visibility = ((Integer) args[1]).intValue();
    brushnameToVisibility.put(brushname,visibility);
    printDEBUG("DEBUG RECVD OSC: " + addr + ":" + brushname
      + ":" + visibility);
    if (globalMenu instanceof SetServerAddressPortMenu) {
      globalMenu = null ;  // a reply came from server, so it's address is set
    }
    timeToMakeCommandMenu = round(frameCount + frameRate) ; // wait a second before making command menu
  } else {
    println("UNKNOWN OSC MESSAGE: " + addr);
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
  
