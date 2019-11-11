/* /////////////////////////////////////
  April, 2019    - November, 2019
  Gabriela Bila  - Updated by Arthur Brugiere <RoiArthurB>
  Reading serial port from Arduino at Processing
*/ /////////////////////////////////////
import processing.serial.*;
import hypermedia.net.*;

//Arduino arduino;
Serial myPort;
private UDP udp; //Create UDP object for recieving
private int PORT = 9878;
private String HOST_IP = "localhost"; //IP Address of the PC in which this App is running
String val; // variable that is passed from processing to arduino

void setup() {
  // Set the COM Port
  String portName = Serial.list()[0]; ///*** change the port and CLOSE arduino serial monitor
//  myPort = new Serial(this, portName, 74880);
  myPort = new Serial(this, portName, 9600); 
  udp = new UDP(this);  
  udp.log(true);
}

void draw() { 
  if (myPort.available() > 0) {  
    val = myPort.readStringUntil('\n');
    print(val);
    if(val !=null){
      udp.send(val, HOST_IP, PORT);
    }
    println("====");
  }
}
