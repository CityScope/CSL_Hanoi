/**
* Name: Water Management Bac Hung Hai
* Author:  Arnaud Grignard
* Description: 
* Tags: grid, load_file, asc
*/

model watermanegement
import "BacHungHai Irrigation System.gaml"

global {	
	list<string> cellsTypes <- ["Fish", "Rice","Vegetables", "Industrial", "Hospital"];
	list<float> consuming_water<-[3.0,2.0,1.0,1.5,0.5];
	map<string, rgb> cellsColors <- [cellsTypes[0]::#darkblue, cellsTypes[1]::#green,cellsTypes[2]::#darkgreen, cellsTypes[3]::#red, cellsTypes[4]::#orange ];
	bool showGrid<-true;
	bool showBlock<-true;
	
	init{
	 	do init_BHH; 	
		ask river {
			ask cell overlapping self {
				type <- "Water";
				color<-#white;//rgb(rnd(100)*1.1,rnd(100)*1.6,200,50);
			}
		}
	}
}

species block{
	string type;
	aspect base{
		if(showBlock){
		  draw shape*0.9 color:cellsColors[type];	
		}
	}
}

grid cell width: 13*4 height: 13*4 schedules:[]{
	string type;
	rgb color;
	init{
		type<-one_of (cellsTypes);
	}
	aspect base{
		if(showGrid){
		if(type="Water"){
			draw shape*0.9 color:color;	
			}else{
			  draw shape*0.9 color:cellsColors[type];	
			}	
		}
	}
} 

experiment dev type: gui autorun:false{
	output synchronized:true{
		display "As DEM" type: opengl axes:false background:#black  {
		    species block aspect:base;
		    species cell aspect:base;// transparency:0.5; 
			species river ; 
			species Station;
			event "g" {showGrid<-!showGrid;}
			event "b" {showBlock<-!showBlock;}
		}
	} 
}

experiment cityScopeTable type: gui autorun:true{
	output synchronized:true{
		display "As DEM" type: opengl axes:false background:#black fullscreen:false toolbar:false 
		keystone: [{0.16180121847129988,0.22946079240946138,0.0},{0.18077106522363712,0.7852474747946201,0.0},{0.6771033104328638,0.79365130564027,0.0},{0.692433154671796,0.23466785914628063,0.0}]{
			species block aspect:base;
		    species cell aspect:base;// transparency:0.5; 
			species river;
			species poi;
			event "g" {showGrid<-!showGrid;}
			event "b" {showBlock<-!showBlock;}
		}

	} 
}