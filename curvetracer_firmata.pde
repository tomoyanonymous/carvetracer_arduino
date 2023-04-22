import processing.serial.*;
import cc.arduino.*;
import org.firmata.*;

Arduino arduino;
final int TRI_PIN = 5;  // TriAngle Wave      at D5
final int VG_PIN = 3;   // Voltage step port  at D3
int tri_v = 0;    // Tri value
int step_v = 0;    // Step Value
int LED_PIN = 10;
final int slope_c=4;
int slope = slope_c;
final int SAMPLES = 2048;
int read_point;
boolean reading=false;
final int step_repeat=1;
int step_repeat_cnt = 0;
int hue = 0;


class PlotData {
  float x=0;
  float y=0;
}
//PlotData[] points;
PlotData tmp;

void initArduino() {
  String[] hosts = Arduino.list();
  println(hosts);
  for (int i=0; i<hosts.length; i++) {
    if (hosts[i].contains("tty.usbmodem")) {
      arduino = new Arduino(this, hosts[i], 57600);
      println("connected");
      delay(50);
      arduino.pinMode(TRI_PIN, Arduino.OUTPUT);
      arduino.pinMode(VG_PIN, Arduino.OUTPUT);
      arduino.pinMode(LED_PIN, Arduino.OUTPUT);
    }
  }
  if (arduino==null) {
    println("no hosts, exit");
    noLoop();
  }
}
void setup()
{
  size(800, 800);
  colorMode(HSB);

  initArduino();
  tmp = new PlotData();
  //points = new PlotData[SAMPLES];
}

void draw()
{

  if (reading) {
    tri_v = tri_v + slope;
    arduino.analogWrite(TRI_PIN, tri_v);          // will be PWM 488 Hz
    arduino.analogWrite(VG_PIN, step_v);           // will be PWM 488 Hz
    hue = step_v;
    strokeWeight(2);
    strokeJoin(ROUND);
    stroke(color(hue, 255, 255), 255/(step_repeat+1)); // color to draw

    int collector_v = 0;
    int tri_read = 0;
    final int read_repeat=6;
    for (int i=0; i<read_repeat; i++) {
      collector_v +=arduino.analogRead(0);
      tri_read += arduino.analogRead(1);
      delay(5);
    }
    println("step_v: ", step_v, "collector_v", collector_v, "tri_read", tri_read);
    float x=map(float(tri_read), 0, read_repeat*1023, 0, width*.95);
    float y=map(float(collector_v), 0, read_repeat*1023, 0, height*.95);


    line(tmp.x, height - tmp.y, x, height - y);  // draw the line:
    tmp.x = x;
    tmp.y = y;


    if (tri_v > 251) {
      slope = -slope_c;
    }
    if (tri_v < 1) {
      slope = slope_c;
      step_repeat_cnt+=1;
      if (step_repeat_cnt>step_repeat) {
        step_repeat_cnt=0;
        step_v += int(255 / 5);
      }
    }
    if (step_v > 255) {
      step_v = 0;
      reading=false;
      println("finished");
    }
  }
  //read_point+=1;
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    blendMode(BLEND);

    reading=true;
    background(145);
    fill(0);
    rect(0, height*0.05, width*0.95, height*0.95);
    for (int i=0; i<5; i++) {
      stroke(125);
      strokeWeight(1);
      float y =  height - height*0.95* float(i+1) / 5.0;
      line(0, y, width*0.95, y);
    }

    tmp.x = 0;
    tmp.y = 0;
    println("started");
    blendMode(ADD);
  }
}
