import processing.serial.*;
import org.gicentre.utils.stat.*;

Serial myPort;

void setup() {

  print(Serial.list());
  String portName = Serial.list()[0];
  print(portName);

  myPort = new Serial(this, portName, 115200);
  myPort.bufferUntil('\n');

  size(900, 1000);

  createUI();
}

void draw() {
  updateUI();
}
