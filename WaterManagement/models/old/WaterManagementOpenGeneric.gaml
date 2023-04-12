/**
* Name: Water Management Bac Hung Hai
* Author:  Arnaud Grignard
* Description: 
* Tags: grid, load_file, asc
*/

model watermanegement

global {
	/*TuiLoi 
	file boundShapefile<-shape_file('../includes/TuiLoiData/bounds.shp');
	file riverShapefile<- shape_file('../includes/TuiLoiData/river.shp');
	file gateShapefile<- shape_file('../includes/TuiLoiData/TramMua.shp');
	file landUsefile <- shape_file('../includes/TuiLoiData/land_use.shp');*/
	
	
	file riverShapefile<- shape_file('../../includes/old/OpenData/BACHUNGHAI_River.shp');
	file riverShapePolygonfile<- shape_file('../../includes/old/OpenData/BACHUNGHAI_River_polygon.shp');
	file gateShapefile<- shape_file('../../includes/old/OpenData/BACHUNGHAI_Gate.shp');
	file redriverPOIShapefile<- shape_file('../../includes/old/OpenData/red_river_poi.shp');
	file landUsefile <- shape_file('../../includes/old/OpenData/land_use.shp');
	file riverGraphFile <- shape_file("../../includes/old/TuiLoiData/river_splitted.shp");
	
	
	graph the_river;
	geometry shape <- envelope(riverShapefile);	
	list<string> cellsTypes <- ["Fish", "Rice","Vegetables", "Industrial", "Hospital"];
	map<string, rgb> cellsColors <- [cellsTypes[0]::#darkblue, cellsTypes[1]::#green,cellsTypes[2]::#darkgreen, cellsTypes[3]::#red, cellsTypes[4]::#orange ];
	bool showGrid<-true;
	bool showBlock<-true;
	
	init{
		create river from: riverGraphFile;
		create river from:riverShapePolygonfile;
		create gate from:gateShapefile{
			type<- flip(0.5) ? "source" :"outlet";
		}		

		the_river <- as_edge_graph(river);
		
		ask river {
			ask cell overlapping self {
				type <- "Water";
				color<-#black;//rgb(rnd(100)*1.1,rnd(100)*1.6,200,50);
			}
		}
		create land from:landUsefile;
		
		/*create block{
			location<-{world.shape.width/2-world.shape.width*0.05,world.shape.height/2};
			shape<-square(world.shape.width*0.750);
		}
		save block to:"../results/bounds.shp" type:"shp";*/
	}
	
	reflex c_water  {
		create water {
			location <- one_of(gate where (each.type = "source")).location;
			target <- one_of(gate where (each.type = "outlet")) ;
			color<-#blue;
		}
	}
	
	reflex updateGrid{
		/*ask cell{
			if (flip(0.005) and type!="Water") {
				type<-one_of (cellsTypes);
			}
		}*/
	}
}

species block{
	aspect default{
		draw shape color:#yellow;
	}
}

species land{
	aspect base{
		draw shape;
	}
}
grid cell width: 15*4 height: 15*4 schedules:[]{
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



grid lego width:15 height:15{
	string type;
	aspect base{
		draw shape color:color;
	}
	
}

species water skills: [moving] {
	gate target ;
	rgb color;
	int amount<-250;

	reflex move {
		do goto target: target on: the_river speed: 150.0;
//		do wander on: the_river speed: 300.0;
		if(location=target.location){
			do die;
		}
		//heading<-90;
	}	
	
	aspect default {
//		draw line({location.x-amount*cos(heading-90),location.y-amount*sin(heading-90)},{location.x+amount*cos(heading-90),location.y+amount*sin(heading-90)})  color: color border: color-25;
		draw line({location.x-amount*cos(heading-90),location.y-amount*sin(heading-90)},{location.x+amount*cos(heading-90),location.y+amount*sin(heading-90)})  color: #pink border: color-25;
	}
}

species river{
	aspect base{
		draw shape color:#blue width:2;
	}
}


species gate {
	string type;
	aspect default {
		draw circle(0.75#km) color: (type="source") ? #green : #red border: #black;		
	}	
}


experiment dev type: gui autorun:true{
	output synchronized:true{
		display "As DEM" type: opengl axes:false background:#black  {
		    species block;
		    species cell aspect:base;// transparency:0.5; 
			species river aspect:base;
			species water;
			species gate;
			event "g" {showGrid<-!showGrid;}
			event "b" {showBlock<-!showBlock;}
		}
	} 
}

experiment cityscope type: gui autorun:true{
	output synchronized:true{
		display "As DEM" type: opengl axes:false background:#black fullscreen:1 toolbar:false 
		keystone: [{0.11656421991808863,0.167109629356474,0.0},{0.14285268545600432,0.8143146078580775,0.0},{0.7170183091562854,0.8153797412496441,0.0},{0.735674403288836,0.16759312313473373,0.0}]{	//species land aspect:base;
			species cell aspect:base;// transparency:0.5; 
			species river aspect:base;
			species water;
			species gate;
			event "g" {showGrid<-!showGrid;}
			event "b" {showBlock<-!showBlock;}
		}

	} 
}