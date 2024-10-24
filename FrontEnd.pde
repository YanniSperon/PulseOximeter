color bgColor = color(255, 255, 255);
PFont monoFont;
PFont defaultFont;
PFont boldFont;

float timerTextSize = 48;
float timerLabelTextSize = 24;

void drawTimer() {
  noStroke();
  fill(0, 120, 153);
  rect(0, 0, width, 100);
  fill(255);

  long totalMil = lastTime - startTime;
  int hours = getHours(totalMil);
  int minutes = getMinutes(hours, totalMil);
  int seconds = getSeconds(hours, minutes, totalMil);

  String timerText = "";
  String timerLabelText = "";

  if (hours > 0) {
    timerText += String.valueOf(hours) + ":";
    timerLabelText = "hr";
  }
  if (minutes > 0 || hours > 0) {
    timerText += nf(minutes, 2) + ":";
    if (hours == 0) {
      timerLabelText = "min";
    }
  }
  timerText += nf(seconds, 2);
  if (hours == 0 && minutes == 0) {
    timerLabelText = "sec";
  }

  textSize(timerTextSize);
  float timerWidth = textWidth(timerText);
  textSize(timerLabelTextSize);
  float timerLabelWidth = textWidth(timerLabelText);
  float totalWidth = timerWidth + timerLabelWidth;

  float timerTextX = (width - totalWidth) / 2;
  float timerLabelTextX = timerTextX + timerWidth;


  textSize(timerTextSize);
  text(timerText, timerTextX, 70);
  fill(170);
  textSize(timerLabelTextSize);
  text(timerLabelText, timerLabelTextX, 70);
}

void createUI() {
  initializeEnvironment();

  background(bgColor);
  monoFont = createFont("RobotoMono-Regular.ttf", timerTextSize);
  defaultFont = createFont("Roboto-Regular.ttf", timerLabelTextSize);
  boldFont = createFont("Roboto-Bold.ttf", timerTextSize);
  textFont(monoFont);
  stroke(1);

  drawTimer();

  float cursorY = createZonesChart(125);
  createTotalChart(cursorY);
}

void updateUI() {
  background(bgColor);
  drawTimer();
  float cursorY = createZonesChart(125);
  createTotalChart(cursorY);
}


boolean shouldStartReading = false;
int[] readData = new int[6];

void serialEvent(Serial myPort) {
  String input = myPort.readString();
  println("Reading \"" + input.trim() + "\"");
  if (!shouldStartReading) {
    if (input.charAt(0) == 1) {
      println("Should start reading!");
      shouldStartReading = true;
      return;
    } else {
      println(input);
    }
  } else {
    input = input.trim();

    int index = 0;
    int dataIndex = 0;
    String temp = "";
    boolean anyErrors = false;
    char currChar = input.charAt(index);
    while (currChar != '\0' && currChar != '\n' && dataIndex <= 5) {
      switch (currChar) {
      case ',':
        try {
          readData[dataIndex++] = Integer.parseInt(temp);
        }
        catch (Exception e) {
          anyErrors = true;
        }

        temp = "";
        break;
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        temp += currChar;
        break;
      default:
        break;
      }
      index++;
      if (index < input.length()) {
        currChar = input.charAt(index);
      } else {
        break;
      }
    }
    try {
      readData[dataIndex++] = Integer.parseInt(temp);
    }
    catch (Exception e) {
      anyErrors = true;
    }
    if (!anyErrors) {
      if (updateEnvironment(readData[2]/2, readData[3], readData[4], readData[5])) {
        myPort.write(1);
      }
    }
  }
}
