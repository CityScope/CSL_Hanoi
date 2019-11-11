/*
 * November, 2019
 *  by Arthur Brugiere <RoiArthurB>
 * Reading Arduino analog value from Slider & Button and 
 *  return it semi-structurized serial port (to listening Processing script)
 */

// Set corresponding I/O 
const int sliderIn = A0;
const int buttonIn = A1;

// This value changes according to the position of the Earth...
float maxSliderValue = 400.0; 

void setup(){
  // Pick the serial you'll broadcast on
  //Serial.begin(74880);
  Serial.begin(9600);
}

void loop(){
  int sliderValue = analogRead(sliderIn);                       // Get Slider value

  // Will update the max value to limit impact of the Earth position (l.12)
  if (sliderValue > maxSliderValue) {
    maxSliderValue = (float) sliderValue;
  }
  
  Serial.print( sliderValue / maxSliderValue );                 // Percent <float> value [0, 1]
  Serial.print("-");                                            // semi-structurized log separator
  Serial.println( analogRead(buttonIn) > 300 ? true : false );  // Return 0 or 1 <int>
  
  delay(500);                                                   // 1/2 sec so your display doesnt't scroll too fast
}
