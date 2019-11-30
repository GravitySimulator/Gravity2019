// ResponsiveText holds 1 or more chars in a String and checks boundbox with a mouse press.

class ResponsiveText {
  String mytext ;
  PFont font ;
  int pointSize ;
  int x ;
  int y ;
  Menu menu ;
  ResponsiveText(String mytext, PFont font, int pointSize, int x, int y,
        Menu menu) {
    this.mytext = mytext ;
    this.font = font ;
    this.pointSize = pointSize ;
    this.x = x ;
    this.y = y ;
    this.menu = menu ;
  }
  // Call setMyFont() before printing or pixel width,height measurements.
  void setMyFont() {
    if (font != null) {
      textFont(font, pointSize) ;
    } else {
      textSize(pointSize);
    }
    textAlign(LEFT, TOP);
  }
  void display(boolean highlight) {
    setMyFont();  // set for display
    if (highlight) {  // STUDENT SET YOUR OWN COLOR
      // STUDENT 6: Underline the highlighted text using
      // Processing's line library function in the same color.
      // You have the x,y location of the left,top of the
      // text; call getWidth() and getHeight() to determine
      // the right and bottom coordinates of the text; put
      // the underline a little below the bottom.
      stroke(255,255,0);
      strokeWeight(4);
      fill(255,255,0);
      line(x,y+getHeight()-2,x+getWidth(),y+getHeight()-2);
    } else {
      fill(0,255,255);
    }
    text(mytext, x, y);
  }
  boolean isInBoundingBox(int eventX, int eventY) {
    setMyFont();  // set for determining extents
    int right = x + round(textWidth(mytext));
    int bottom = y + round(textAscent()+textDescent());
    return (eventX >= x && eventX <= right && eventY >= y && eventY <= bottom);
  }
  int getWidth() {
    setMyFont();
    return round(textWidth(mytext));
  }
  int getHeight() {
    setMyFont();
    return (round(textAscent()+textDescent()));
  }
  int getX() {
    return x ;
  }
  int getY() {
    return y ;
  }
  String getText() {
    return mytext ;
  }
  // setText works only if the incoming text has same number of chars
  void setText(String incoming) {
    if (mytext.length() == incoming.length()) {
      mytext = incoming ;
    } else {
      println("WARNING, ResponsiveText failed attempt to replace " + mytext.length()
        + "-character text '" + mytext + "' with " + incoming.length()
        + "-character text '" + incoming + " at " + x + "," + y);
    }
  }
}

/* Menu does most of the work of menu construction & display. */
abstract class Menu {
  String title ;
  boolean isSubmit ;
  boolean isCancel ;
  String [][] columnsOfMulticharFields ;
  // columnsOfMulticharFields is indexed [COLUMN][ROW] because
  // brush names come in one array [1][numberOfBrushes], and
  // commands come in another [2][numberOfCommands]. This
  // approach generalizes to > 0 multi-character commands.
  String [] rowsOfLetters ;
  ResponsiveText submitButton = null ;
  ResponsiveText cancelButton = null ;
  ResponsiveText [][] buttons ;
  int [] activeRowPerColumn ;
  int maxcolumns = 0 ;
  String mytext ;
  PFont font ;
  int pointSize ;
  int leftx = 0 ;
  Menu(String title, boolean isSubmit, boolean isCancel,
      String [][] columnsOfMulticharFields, // May be null!!!
      String [] rowsOfLetters, PFont font, int pointSize,
      float rowSpacing, float colSpacing) {
    this.title = title ;
    this.isSubmit = isSubmit ;
    this.isCancel = isCancel ;
    this.columnsOfMulticharFields = columnsOfMulticharFields ;
    this.rowsOfLetters = rowsOfLetters ;
    this.font = font ;
    this.pointSize = pointSize ;
    setMyFont();
    ResponsiveText fatText = new ResponsiveText("X",font, pointSize, -1, -1, null);
    int fatWidth = fatText.getWidth();
    int verticalHeight = fatText.getHeight();
    leftx = round(textWidth("i")) ;   // start over at left
    int tmpx = leftx, tmpy = round(textAscent()+textDescent()) * 2 ; // Leave room for title
    if (isSubmit) {
      submitButton = new ResponsiveText(" Submit ", font, pointSize, tmpx, tmpy, this);
      tmpx += round(colSpacing * submitButton.getWidth());
    }
    if (isCancel) {
      cancelButton = new ResponsiveText(" Cancel ", font, pointSize, tmpx, tmpy, this);
    }
    if (isSubmit || isCancel) {
      tmpy += round((textAscent()+textDescent())*rowSpacing) ;
    }
    tmpx = leftx ;   // start over at left
    if (columnsOfMulticharFields == null) {
      buttons = new ResponsiveText [ rowsOfLetters.length ][];
      for (int row = 0 ; row < rowsOfLetters.length ; row++) {
        buttons[row] = new ResponsiveText [ rowsOfLetters[row].length() ];
        maxcolumns = max(maxcolumns, rowsOfLetters[row].length());
        for (int column = 0 ; column < rowsOfLetters[row].length() ; column++) {
          buttons[row][column] = new ResponsiveText(""+rowsOfLetters[row].charAt(column),
            font, pointSize, tmpx, tmpy, this);
          tmpx += round(colSpacing * fatWidth);
        }
        tmpx = leftx ;
        tmpy += verticalHeight ;
      }
    } else {
      buttons = new ResponsiveText [ rowsOfLetters.length
            + columnsOfMulticharFields.length ][];
      int rowcount = rowsOfLetters.length;
      String [] padding = new String [ columnsOfMulticharFields.length ];
      String manyspaces =
      "                                                                    ";
      for (int flds = 0 ; flds < columnsOfMulticharFields.length ; flds++) {
        rowcount = max(rowcount, columnsOfMulticharFields[flds].length);
        padding[flds] = manyspaces.substring(0, // pad to fixed length of field
            columnsOfMulticharFields[flds][0].length());
      }
      buttons = new ResponsiveText [ rowcount ][];
      for (int row = 0 ; row < rowcount ; row++) {
        if (row < rowsOfLetters.length) {
          buttons[row] = new ResponsiveText [ rowsOfLetters[row].length()
            + columnsOfMulticharFields.length ];
          maxcolumns = max(maxcolumns, rowsOfLetters[row].length()
            + columnsOfMulticharFields.length);
        } else {
          buttons[row] = new ResponsiveText[ columnsOfMulticharFields.length ];
          maxcolumns = max(maxcolumns, columnsOfMulticharFields.length);
        }
        for (int column = 0 ; column < columnsOfMulticharFields.length ;
            column++) {
          //println("DEBUG1 ROW " + row + " COL " + column);
          if (row < buttons.length && column < buttons[row].length
              && column < columnsOfMulticharFields.length
              && row < columnsOfMulticharFields[column].length) {   // DEBUG 11/11/2018
            buttons[row][column] = new ResponsiveText(
                columnsOfMulticharFields[column][row],
                  font, pointSize, tmpx, tmpy, this);
          }
          //println("AFTER DEBUG1 ROW " + row + " COL " + column);
          tmpx += round(colSpacing * fatWidth * padding[column].length());
        }
        if (row < rowsOfLetters.length) {
          for (int col = 0 ; col < rowsOfLetters[row].length() ; col++) {
            int column = col + columnsOfMulticharFields.length;
            buttons[row][column] = new ResponsiveText(""
              +rowsOfLetters[row].charAt(col),
              font, pointSize, tmpx, tmpy, this);
            tmpx += round(colSpacing * fatWidth);
          }
        }
        tmpx = leftx ;
        tmpy += verticalHeight ;
      }
    }
    activeRowPerColumn = new int [ maxcolumns ] ;
  }
  void setMyFont() {
    if (font != null) {
      textFont(font, pointSize) ;
    } else {
      textSize(pointSize);
    }
    textAlign(LEFT, TOP);
  }
  void display() {
    setMyFont();
    fill(255);
    text(title, leftx, 10);
    if (submitButton != null) {
      submitButton.display(true);
    }
    if (cancelButton != null) {
      cancelButton.display(true);
    }
    for (int row = 0 ; row < buttons.length ; row++) {
      for (int column = 0 ; column < buttons[row].length ; column++) {
        // println("DEBUG2 ROW " + row + " COL " + column);
        if (buttons[row][column] != null) { // DEBUG 11/11/2018
          // println("DEBUG3 activeRowPerColumn.length: " + activeRowPerColumn.length);
          if (activeRowPerColumn[column] == row) {
            buttons[row][column].display(true);
          } else {
            buttons[row][column].display(false);
          }
        }
        // println("DEBUG2 AFTER ROW " + row + " COL " + column);
      }
    }
  }
  abstract void doSubmit();
  abstract void doCancel();
  void respondToMouseEvent(int eventX, int eventY) {
    if (submitButton != null && submitButton.isInBoundingBox(eventX, eventY)) {
      doSubmit();
    } else if (cancelButton != null && cancelButton.isInBoundingBox(eventX, eventY)) {
      doCancel();
    } else {
      for (int row = 0 ; row < buttons.length ; row++) {
        for (int column = 0 ; column < buttons[row].length ; column++) {
          if (buttons[row][column] != null      // DEBUG 11/11/2018
              && buttons[row][column].isInBoundingBox(eventX, eventY)) {
            //println("DEBUG MATCHED BUTTON AT ROW " + row + "," 
              //+ " COL " + column + "," + buttons[row][column].getText());
            activeRowPerColumn[column] = row ;
            //this.display();
            return ;
          }
        }
      }
    }
  }
}

String [] SetServerAddressPortStrings = {  // 4 digit number
  "---.---.---.---:-----", "000.000.000.000:00000", "111.111.111.111:11111", "222.222.222.222:22222",
  "333.333.333.333:33333", "444.444.444.444:44444", "555.555.555.555:55555", "666.666.666.666:66666",
  "777.777.777.777:77777", "888.888.888.888:88888", "999.999.999.999:99999"
};
class SetServerAddressPortMenu extends Menu {
  SetServerAddressPortMenu() {
    super("Set Server IP Address", true, false, // Cancel not acceptable here.
      null, SetServerAddressPortStrings, globalFont, round(globalPointSize*1.0), 1.5, 1.5);
  }
  void doSubmit() {
    println("DEBUG doSubmit for SetServerAddressPortMenu");
    String ipstring = "", portstring = "" ;
    boolean doingPort = false ;
    for (int column = 0 ; column < maxcolumns ; column++) {
      String piece = buttons[activeRowPerColumn[column]][column].getText();
      if (! "-".equals(piece)) {
        if (":".equals(piece)) {
          doingPort = true ;
        } else if (doingPort) {
          portstring += piece ;
        } else {
          ipstring += piece ;
        }
      }
    }
    println("DEBUG SETTING SERVER IP ADDRESS: " + ipstring + ":" + portstring);
    try {
      SERVERIPADDR = ipstring ;
      SERVERPORT = Integer.parseInt(portstring);
      serverRemoteLocation = new NetAddress(SERVERIPADDR,SERVERPORT);
      sendOSCMessage("/Gravity2019_Oct20/client", MYIPADDR, MYPORT);
      // globalMenu = null ; // We hope it worked, this menu no longer needed.
      // NO! Let the first reply from the server do this step.
    } catch (Exception xxx) {
      println("ERROR, cannot parse server port " + SERVERPORT + ", " + xxx.getMessage());
      SERVERIPADDR = null ;
      SERVERPORT = -1 ;
    }
  }
  void doCancel() {
    // no way to cancel this Menu
  }
}

String [] CommandMenuStrings = {
    "Square", "Linear", "Mercury", "Venus", "Earth",
    "Mars", "Jupiter", "Saturn", "Uranus", "Neptune",
    "West", "East", "North", "South", "Forwards", 
    "Backwards", "Reset"
};

String [] FloatStrings = {
   // "+00.00", "-11.11", "+22.22", "-33.33", "+44.44",
   // "-55.55", "+66.66", "-77.77", "+88.88", "-99.99"
};


String [][] combineStringArrays(
      String [] planet, String [] commands) {
  String visoff = "v";
  String [] vis = new String [ planet.length ];
  for (int i = 0 ; i < planet.length ; i++) {
    vis[i] = visoff ;
  }
  String [][] result = { vis, planet, commands } ;
  return result ;
}
int lastActiveBrush = 0 ; // This was getting reset on new CommandMenu
// after planet adds, so cache the most recent selection
class CommandMenu extends Menu {
  CommandMenu() {
    super("Send Command to Server (Cancel Exits)", true, true,
      combineStringArrays(getAllPlanetnames(),CommandMenuStrings),FloatStrings,
        globalFont, round(globalPointSize * .8), 1.5, 1.5);
    activeRowPerColumn[0] = -1 ; // no default highlight for brush visibility
    activeRowPerColumn[1] = lastActiveBrush ;
  }
  void respondToMouseEvent(int eventX, int eventY) {
    super.respondToMouseEvent(eventX, eventY);
    lastActiveBrush = activeRowPerColumn[1] ;
  }
  // Gravity2019_Oct20 uses base class display, addings the visible planets
  // highlights
  // boolean DEBUGdisplay = true ;
  void display() {
    for (int row = 0 ; row < buttons.length ; row++) {
      if (buttons[row] != null && buttons[row].length > 1
          && buttons[row][0] != null && buttons[row][1] != null) {
        String planet = buttons[row][1].getText();
        ResponsiveText highlight = buttons[row][0];
        /*
        if (DEBUGdisplay) {
          println("DEBUG PREDICATE '" + brush + "' ON '" + mapBrushnameToVisibility(brush));
        }
        */
        if (mapPlanetnameToVisibility(planet)) {
          highlight.setText("^");
        } else {
          highlight.setText("v");
        }
      }
    }
    super.display();
    // replot with highlighting color
    for (int row = 0 ; row < buttons.length ; row++) {
      if (buttons[row] != null && buttons[row].length > 1
          && buttons[row][0] != null) {
        ResponsiveText highlight = buttons[row][0];
        if ("^".equals(highlight.getText())) {
          highlight.display(true);
        }
      }
    }
    // DEBUGdisplay = false ;
  }
  void doSubmit() {
    float fval = 0 ;
    String planet = buttons[activeRowPerColumn[2]][2].getText();
    String command = " ";//buttons[activeRowPerColumn[2]][2].getText();
    String floatstring = "" ;
    // Start at 3 to skip over visibility entry
    for (int column = 2 ; column < maxcolumns ; column++) {
      String piece = buttons[activeRowPerColumn[column]][column].getText();
      floatstring += piece ;
    }
    println("DEBUG SETTING COMMAND: " + planet + ":" + command + ":" + floatstring);
    try {
      println("HERE");
      println("What is floatsting: " + floatstring);
      println("What is fval before: " + fval);
      //fval = Float.parseFloat(floatstring);
      println("THERE");
      //sendOSCMessage(command, planet, fval);
      sendOSCMessage(planet, fval);
      println("ANYWHERE ");
    } catch (Exception xxx) {
      println("ERROR, cannot parse command " + planet + ":" + command + ":" + floatstring
        + ", " + xxx.getMessage());
    }
  }
  void doCancel() {
    exit();
  }
}
