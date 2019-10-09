/**
* Name: Water Management Bac Hung Hai
* Author:  Arnaud Grignard
* Description: 
* Tags: grid, load_file, asc
*/

model watermanegement

global {

	file gates_shape_file <- shape_file("../includes/BachHungHaiData/gates.shp");
	file rivers_shape_file <- shape_file("../includes/BachHungHaiData/rivers.shp");
	file main_rivers_shape_file <- shape_file("../includes/BachHungHaiData/main_rivers.shp");
	
	graph the_river;
	geometry shape <- envelope(main_rivers_shape_file);	
	list<string> cellsTypes <- ["Fish", "Rice","Vegetables", "Industrial", "Hospital"];
	map<string, rgb> cellsColors <- [cellsTypes[0]::#darkblue, cellsTypes[1]::#green,cellsTypes[2]::#darkgreen, cellsTypes[3]::#red, cellsTypes[4]::#orange ];
	bool showGrid<-true;
	bool showBlock<-true;
	
	list<gate> source;
	list<gate> dest;
	
	map<river,float> probaEdges;
	
	int evaporationAvgTime parameter: 'Evaporation time' category: "Parameters" step: 1 min: 1 max:10000 <- 2000 ;
	
	init{
		create main_river from:main_rivers_shape_file;
		create river from: rivers_shape_file;	
		create gate from: gates_shape_file with: [type:: string(read('Type'))];
		
		source <- gate where (each.type = "source");//first(gate where (each.Name = "Song Hong"));
		dest <- gate where (each.type = "sink");//first(gate where (each.Name = "Song Thai Binh")); 
		
		ask gate {
			controledRivers <- river overlapping self;
		}
		
		the_river <- as_edge_graph(river);
		probaEdges <- create_map(river as list,list_with(length(river),100.0));
		
//		ask main_river {
//			ask cell overlapping self {
//				type <- "Water";
//				color<-#black;//rgb(rnd(100)*1.1,rnd(100)*1.6,200,50);
//			}
//		}
	}
	
	reflex manage_water  {
		ask river {
			waterLevel <- 0;
		}
		ask water {
			river(self.current_edge).waterLevel <- river(self.current_edge).waterLevel+1;
		}
		probaEdges <- create_map(river as list, river collect(100/(1+each.waterLevel)));
		ask river where each.is_closed{
			put 0.001 at: self in: probaEdges;
		}
		
		create water {
			location <- (one_of(source)).location;
			//target <- (one_of(dest)).location;
			color<-#blue;
		}
		ask dest {
			do take_water;
		}
	}
	
	action activate_gate {
		gate selected_station <- first(gate overlapping (circle(1) at_location #user_location));
		if selected_station != nil{
			selected_station.is_closed <- !selected_station.is_closed;
			ask selected_station.controledRivers {
				self.is_closed <- !(self.is_closed);
			}
		}
	}
	
}

grid cell width: 15*4 height: 15*4 schedules:[] {
	string type;
	rgb color;
	
	init {
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
//	point target ;
	rgb color;
	int amount<-250;
	river edge;
	float tmp;

	reflex move {
		
		if edge != nil{
			tmp <- probaEdges[edge];
			put 1.0 at: edge in: probaEdges;	
		}
		do wander on: the_river speed: 300.0 proba_edges: probaEdges;
		if edge != nil{
			put tmp at: edge in: probaEdges;	
		}
		edge <- river(current_edge);
//		if(location=target.location){
//			do die;
//		}
	}
	
	reflex evaporate when: (flip(1/evaporationAvgTime)){
		do die;
	}
	
	aspect default {
//		draw line({location.x-amount*cos(heading-90),location.y-amount*sin(heading-90)},{location.x+amount*cos(heading-90),location.y+amount*sin(heading-90)})  color: color border: color-25;
		draw square(0.25#km)  color: #blue ;	
	}
}

species main_river{
	aspect base{
		draw shape color:#blue width:2;
	}
}

species river{
	int waterLevel <- 0;
	bool is_closed <- false;
	
	aspect base{
		draw shape color: is_closed? #red:#blue width:1;
	}
	
	aspect waterLevel {
		draw shape color: is_closed? #red:rgb(255-255*sqrt(min([waterLevel,8])/8),255-255*sqrt(min([waterLevel,8])/8),255) width:3;
	}
}


species gate {
	rgb color <- rnd_color(255);
	string Name;
	string type; // amongst "source", "sink" or "null".
	geometry shape <- circle(0.75#km);	
	bool is_closed<-false;
	list<river> controledRivers <- [];

	action take_water {
		ask water overlapping self{do die;}
	}

	aspect default {
		if self.type = "source" {
			draw circle(0.75#km) color:  #blue  border: #black;
		}else{
			if self.type = "sink" {
				draw circle(0.75#km) color:  #white  border: #black;
			}else{
				if is_closed{
					draw circle(0.75#km) color:  #red  border: #black;
				}else{
					draw circle(0.75#km) color:  #green  border: #black;
				}
			}
		}
	}
}

experiment devVisuAgents type: gui autorun:true{
	output {
		display "As DEM" type: opengl draw_env:false background:#black synchronized:true refresh: every(1#cycle) {
			species main_river aspect:base;			
			species river aspect:base transparency: 0.6;
			species water transparency: 0.2;
			species gate;
			
			event mouse_down action:activate_gate;
			event["g"] action: {showGrid<-!showGrid;};
			event["b"] action: {showBlock<-!showBlock;};
		}
	} 
}

experiment devVisuWaterLevel type: gui autorun:true{
	output {
		display "As DEM" type: opengl draw_env:false background:#black synchronized:true refresh: every(1#cycle) {
			species main_river aspect:base;						
			species river aspect:waterLevel;
			species gate;
			
			event mouse_down action:activate_gate;
			event["g"] action: {showGrid<-!showGrid;};
			event["b"] action: {showBlock<-!showBlock;};
		}
	} 
}

experiment cityscope type: gui autorun:true{
	output {
		display "As DEM" type: opengl draw_env:false background:#black fullscreen: false toolbar:false synchronized:true {
			species cell aspect:base;// transparency:0.5; 
			species main_river aspect:base;
			species river aspect:base;
			species water;
			species gate;

			event mouse_down action:activate_gate;			
			event["g"] action: {showGrid<-!showGrid;};
			event["b"] action: {showBlock<-!showBlock;};
		}

	} 
}