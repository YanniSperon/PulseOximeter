import org.gicentre.utils.stat.*;

int beepHRCutoff = 180;
float avgHR = 60.0f;

// Zones Chart
float peakZoneWidth = 75.0f;
float cardioZoneWidth = 50.0f;
float fatBurnZoneWidth = 25.0f;
float maxZonesWidth = width * 0.75f;

// Current Sampling Period
FloatList dataThisPeriod;
float totalHRThisPeriod = 0.0;
int numSamplesThisPeriod = 0;
int maxSamplesThisPeriod = 50;

// Total Data
FloatList totalDataX;
FloatList totalDataY;
float totalHR = 0;
int numSamplesTotal = 0;

float zoneChartBarHeight = 50.0f;

int millisInPeakZone = 0;
int millisInCardioZone = 0;
int millisInFatBurnZone = 0;

int peakZoneMin = 150;
int cardioZoneMin = 120;
int fatBurnZoneMin = 90;

long lastTime = 0;
long currTimeDelta = 0;
long startTime = 0;
int lastHR = 0;
int lastOx = 0;
int lastConf = 0;

XYChart totalChart;

int getHours(long millis) {
  return int(((float)millis / 1000.0f)/60.0f/60.0f);
}

int getMinutes(long hours, long millis) {
  return int(((float)millis / 1000.0f)/60.0f - (hours * 3600.0f));
}

int getSeconds(long hours, long minutes, long millis) {
  return int(((float)millis / 1000.0f) - (minutes * 60.0f) - (hours * 3600.0f));
}

void drawTimeLabel(int millis, float cursorX, float cursorY) {
  int hours = getHours(millis);
  int minutes = getMinutes(hours, millis);
  int seconds = getSeconds(hours, minutes, millis);

  fill(0);

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

  textSize(12);
  float timerWidth = textWidth(timerText);

  textSize(12);
  text(timerText, cursorX, cursorY);
  fill(120);
  cursorX += timerWidth;
  textSize(8);
  text(timerLabelText, cursorX, cursorY);
}

void initializeEnvironment() {
  startTime = millis();
  lastTime = millis();
  totalDataX = new FloatList();
  totalDataY = new FloatList();
  dataThisPeriod = new FloatList();

  totalHRThisPeriod += 60;
  dataThisPeriod.append(60);
  numSamplesThisPeriod = 1;

  totalChart = new XYChart(this);
  totalChart.showXAxis(true);
  totalChart.showYAxis(true);
  totalChart.setMinY(0);
  totalChart.setXAxisLabel("Time");
  totalChart.setYAxisLabel("HR (BPM)");
  totalChart.setLineColour(color(255, 0, 0));
  totalChart.setXFormat("###");
  totalChart.setPointSize(0);
  totalChart.setLineWidth(2);
}

float createZonesChart(float startY) {
  float spacingX = 25.0f;
  float spacingY = 25.0f;
  float cursorX = spacingX;
  float cursorY = spacingY + startY;

  // Label
  fill(0);
  textFont(boldFont);
  textSize(24);
  cursorY += 24;
  String exerciseZonesLabel = "EXERCISE ZONES";
  text(exerciseZonesLabel, cursorX, cursorY);
  cursorY += spacingY;

  float maxWidth = width - (spacingX*2.0);

  // Grey line
  noStroke();
  fill(127, 80);
  rect(cursorX, cursorY, maxWidth, 3);
  cursorY += 3 + spacingY;

  fill(0);
  textFont(boldFont);
  textSize(18);
  cursorY += 18;
  String hrLabel = String.valueOf(int(avgHR)) + " BPM - " + String.valueOf(lastOx) + "% O2 SAT - " + String.valueOf(lastConf) + "% confident";
  text(hrLabel, cursorX, cursorY);
  cursorY += spacingY;

  fill(127, 80);
  rect(cursorX, cursorY, maxWidth, 3);
  cursorY += 3 + spacingY;


  // Peak Zone
  fill(255, 0, 0);

  long totalMillis = lastTime - startTime + 1;
  peakZoneWidth = (float(millisInPeakZone) / totalMillis) * (maxWidth - 50 + spacingX) + 50;
  rect(cursorX, cursorY, peakZoneWidth, zoneChartBarHeight);
  cursorX += peakZoneWidth;
  drawTimeLabel(millisInPeakZone, cursorX, cursorY + (zoneChartBarHeight / 2.0f));
  cursorX = spacingX;
  cursorY += zoneChartBarHeight + spacingY;

  // Cardio Zone
  fill(255, 115, 0);
  cardioZoneWidth = (float(millisInCardioZone) / totalMillis) * (maxWidth - 50 + spacingX) + 50;
  rect(cursorX, cursorY, cardioZoneWidth, zoneChartBarHeight);
  cursorX += cardioZoneWidth;
  drawTimeLabel(millisInCardioZone, cursorX, cursorY + (zoneChartBarHeight / 2.0f));
  cursorX = spacingX;
  cursorY += zoneChartBarHeight + spacingY;

  // Fat Burn Zone
  fill(252, 186, 3);
  fatBurnZoneWidth = (float(millisInFatBurnZone) / totalMillis) * (maxWidth - 50 + spacingX) + 50;
  rect(cursorX, cursorY, fatBurnZoneWidth, zoneChartBarHeight);
  cursorX += fatBurnZoneWidth;
  drawTimeLabel(millisInFatBurnZone, cursorX, cursorY + (zoneChartBarHeight / 2.0f));
  cursorX = spacingX;
  cursorY += zoneChartBarHeight + spacingY;

  return cursorY;
}

void createTotalChart(float startY) {
  totalChart.setData(totalDataY.toArray(), totalDataX.toArray());
  textSize(10);
  float spacingX = 25.0f;

  totalChart.draw(spacingX, startY, width - spacingX, height / 3.0f);
}

// Returns whether or not it should beep
boolean updateEnvironment(int newHR, int confidence, int oxygen, int status) {
  // Update Timings
  currTimeDelta = millis() - lastTime;
  lastTime = millis();

  if (status == 3) {
    if (newHR != 0) {
      lastHR = newHR;

      // Sample
      totalHRThisPeriod += lastHR;
      totalHR += lastHR;
      dataThisPeriod.append(lastHR);
      if (numSamplesThisPeriod >= maxSamplesThisPeriod) {
        totalHRThisPeriod -= dataThisPeriod.get(0);
        totalDataX.append(dataThisPeriod.get(0));
        totalDataY.append(totalDataX.size());
        dataThisPeriod.remove(0);
        numSamplesThisPeriod--;
      }
      numSamplesThisPeriod++;
    }
    if (oxygen != 0) {
      lastOx = oxygen;
    }
    if (confidence != 0) {
      lastConf = confidence;
    }
  }

  avgHR = totalHRThisPeriod / numSamplesThisPeriod;
  if (avgHR >= peakZoneMin) {
    millisInPeakZone += currTimeDelta;
  } else if (avgHR >= cardioZoneMin) {
    millisInCardioZone += currTimeDelta;
  } else if (avgHR >= fatBurnZoneMin) {
    millisInFatBurnZone += currTimeDelta;
  }

  return avgHR >= beepHRCutoff;
}

void updateZonesChart(float startY) {
  lastTime = millis();
  avgHR = totalHRThisPeriod / numSamplesThisPeriod;
  if (avgHR >= peakZoneMin) {
    millisInPeakZone += currTimeDelta;
  } else if (avgHR >= cardioZoneMin) {
    millisInCardioZone += currTimeDelta;
  } else if (avgHR >= fatBurnZoneMin) {
    millisInFatBurnZone += currTimeDelta;
  }
  createZonesChart(startY);
}

// FUNCTION 3 --> SERIAL
//void graph_serialEvent_lungs(float val) {

//  testLineChartX.append(count);
//  testLineChartY.append(val);

//  if (testLineChartX.size() > 100 && testLineChartY.size() > 100) {
//    testLineChartX.remove(0);
//    testLineChartY.remove(0);
//  }
//  testLineChart.setData(testLineChartX.array(), testLineChartY.array());
//}
