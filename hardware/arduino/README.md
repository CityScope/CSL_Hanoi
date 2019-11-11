# City_Hanoi Exposition set - GAMA Connector

This folder aims to give a plug-n-play stack to connect hardware to the GAMA simulation

## Getting Started

These instructions will get you a copy of the project up and running on your local machine.

### Prerequisites

Before starting and to use this code, you'll need to have all of these softwares:

* [Arduino IDE](https://www.arduino.cc/en/Main/Software)
* [Processing](https://processing.org/download/)
* JDK 10 or above
* [GAMA 1.8.0](https://gama-platform.github.io/download) (with JDK version will avoid JDK conflict)

This code/stack has only been tested with an [Arduino Uno](https://www.arduino.cc/en/Guide/ArduinoUno) board. But the code should work just fine with any other Arduino board.

Also, this setup has been made without Ethernet shield. If you attend to use one, it's possible to skip the _Processing_ software with some tweaks in the arduino code.


### Installing

First of all, you'll have to clone the whole project to have the GAMA project ( ../../WaterManagement/ ), the Arduino code ( ./arduino ) and the Processing code ( ./arduino2gama/ ).

```
git clone git@github.com:CityScope/CSL_Hanoi.git
```

## Deployment

From now I'll tell you step-by-step how to configure everything from the Arduino to GAMA.

#### Arduino

First, plug the Arduino board to your computer with the USB cable.

Second, start the Arduino IDE (with the JDK 10 or above) and open the Arduino file :

```
/path/to/CSL_Hanoi/hardware/arduino/sliderButton-ValueInterface/ 
```

Third, check if the IDE has automatically detect your board and the corresponding serial port.

* Board : Tools > Boards > Arduino/Genuino Uno

> If you don't see your board here, you'll have to install the corresponding core. Let's check [here](https://www.arduino.cc/en/Guide/Cores).

* Serial : Tools > Ports > <yourArduinoBoard>

> If you use Linux and don't see your board, you'll have to add your user to specific groups. Find the Arch Linux doc [here](https://wiki.archlinux.org/index.php/Arduino).

Last, you can compile the script (_Verify_ button on the top left corner) and _Upload_ it on your board.

> Warning, you can check the output with the _Serial Monitor_, but you'll have to close the monitor to connect the Processing software

#### Processing

First, start the Processing IDE (with JDK 10 or above) and open the Processing file :

```
/path/to/CSL_Hanoi/hardware/arduino/arduino2gama/arduino2gama.pde
```

Second, import the UDP library (corresponding to the second import in the code `import hypermedia.net.*;`) :

* Sketch > Add file .. > /path/to/CSL_Hanoi/hardware/arduino/arduino2gama/code/udp.jar

> Be careful, if the model was already imported, reimporting it can remove it from your execution...

> The library comes from here : https://ubaa.net/shared/processing/udp/

Third, run the script with your Arduino code running.

> The _Arduino Serial Monitor_ should be closed otherwise you will have a "Port busy" error

#### GAMA

First, start the GAMA 1.8.0 IDE (with the embedded JDK or the JDK 8) and open the GAMA project :

```
/path/to/CSL_Hanoi/WaterManagement/
```

Second, (in GAMA) open the `BachHungHai_agri_management.gaml` model

Third, run the model with your Arduino and your Processing codes running

## Built With

* [Arduino Uno](https://www.arduino.cc/en/Guide/ArduinoUno) - Open-Source single-board microcontroller
  * One slider
  * One button
* [Arduino IDE](https://www.arduino.cc/en/Main/Software) - Open-Source IDE for Arduino boards
* [Processing](https://processing.org/) - Used for network connection
* [GAMA 1.8.0](https://github.com/gama-platform/gama) - Modeling and simulation platform development

<!-- 
## Authors

See also the list of [contributors](https://github.com/CityScope/CSL_Hanoi/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone whose code was used
* Inspiration
* etc

-->