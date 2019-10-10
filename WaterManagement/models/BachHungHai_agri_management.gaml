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
	
	list<string> cells_types <- ["Fish", "Rice","Vegetables", "Industrial", "Urban"];
	map<string, rgb> cells_colors <- [cells_types[0]::#darkblue, cells_types[1]::#green,cells_types[2]::#darkgreen, cells_types[3]::#red, cells_types[4]::#orange ];
	//map<string, int> cells_withdrawal <- [cells_types[0]::10, cells_types[1]::100,cells_types[2]::50, cells_types[3]::5, cells_types[4]::20];
//	map<string, float> cells_withdrawal <- [cells_types[0]::1.0, cells_types[1]::1.0,cells_types[2]::0.5, cells_types[3]::0.5, cells_types[4]::2.0];
//	map<string, int> cells_pollution <- [cells_types[0]::100, cells_types[1]::25,cells_types[2]::20, cells_types[3]::50, cells_types[4]::30];
	map<string, float> cells_withdrawal <- [cells_types[0]::1.0, cells_types[1]::4.0,cells_types[2]::0.5, cells_types[3]::8.0, cells_types[4]::2.0];
	map<string, int> cells_pollution <- [cells_types[0]::25, cells_types[1]::0,cells_types[2]::20, cells_types[3]::90, cells_types[4]::30];


	bool showGrid parameter: 'Show grid' category: "Parameters" <-true;
	bool showBlock parameter: 'Show blocks' category: "Parameters" <-true; //unused for now
	
	list<gate> source;
	list<gate> dest;
	
	map<river,float> probaEdges;
	
	int evaporationAvgTime parameter: 'Evaporation time' category: "Parameters" step: 1 min: 1 max:10000 <- 2000 ;
	
	init{
		create main_river from:main_rivers_shape_file;
		create river from: rivers_shape_file;
		create gate from: gates_shape_file with: [type:: string(read('Type'))];
		
		ask cell {
			do init_cell;
		}
		
		ask river {
			overlapping_cell <- first(cell overlapping self);
		}
		
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
		
		
		ask source where(!each.is_closed){
			create water {
				location <- myself.location;
				color<-#blue;
			}
		}
		
		ask dest {
			do take_water;
		}
	}
	
	reflex water_consumption_and_pollution{
		ask water where(each.current_edge != nil) {
			if flip(cells_withdrawal[ river(self.current_edge).overlapping_cell.type] * 0.01){
				if(flip(cells_pollution[ river(self.current_edge).overlapping_cell.type] * 0.01)) {
					create pollution {
						location <- myself.location;
					}		
				}	
			do die;
			}
		}	
	}
	
	// if the user clicks on a gate, it will close or open it. If the user clicks on a land plot, it will change the land use. If when clicking when the mouse is over
	// a gate and a land plot, it will only perform the action on the gate.
	action mouse_click {
		gate selected_station <- first(gate overlapping (circle(1) at_location #user_location));
		if selected_station != nil{
			selected_station.is_closed <- !selected_station.is_closed;
			ask selected_station.controledRivers {
				self.is_closed <- !(self.is_closed);
			}
		} else {
			cell selected_cell <- first(cell overlapping (circle(1) at_location #user_location));
			if selected_cell != nil{
				int old_type <- index_of(cells_types, selected_cell.type);
				selected_cell.type <- cells_types[mod(index_of(cells_types, selected_cell.type)+1,length(cells_types))];
			}
		}
	}
	
}

grid cell width: 5 height: 5 {//width: 15*4 height: 15*4 {
	string type;
	rgb color;
	list<river> rivers_on_cell;
	
	init {
		type<-one_of (cells_types);
	}
	
	action init_cell {
		rivers_on_cell <- river overlapping self;
	}
	
//	reflex water_consumption when: true{//lent. Déplacé dans un reflex dans le global
//		river r <- one_of(rivers_on_cell);
//		list<water> ws <- water where (river(each.current_edge) = r);
//		ask ws {
//			if flip(cells_withdrawal[myself.type] * 0.01){
//				if(flip(cells_pollution[myself.type] * 0.01)) {
//					create pollution {
//						location <- any(r.shape.points);// any_location_in(r);
//					}		
//				}	
//			do die;
//			}
//		}	
//	}


/* 
 * autre modèle de pollution ajouté dans le global (moins de consommation d'eau, rejet d'eau polluée ne peut être supérieur à la quantité d'eau prélevée)
 * 
 * 
	reflex water_withdraw when: false {
		river r <- one_of(rivers_on_cell);
		list<water> ws <- water where (river(each.current_edge) = r);
		ask (cells_withdrawal[type]/100 * length(ws)) among ws {
			do die;
		}
	}
	
	reflex pollution_emission when: false {
		river r <- one_of(rivers_on_cell);
		
		if(r != nil) {
			if(flip(cells_pollution[type] * 0.01)) {
				// TODO : review the entry points 
				create pollution {
					location <- last(r.shape.points);// any_location_in(r);
				}	
			}			
		}
	}	
*/
	aspect base{
		if(showGrid){
			if(type="Water"){
				draw shape*0.8 color:color;	
			}else{
			  	draw shape*0.8 color:cells_colors[type];	
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
	rgb color <- #blue;
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
		draw square(0.25#km)  color: color ;	
	}
}

species pollution parent: water {
	rgb color <- #red;
}

species main_river{
	aspect base{
		draw shape color:#blue width:2;
	}
}

species river{
	int waterLevel <- 0;
	bool is_closed <- false;
	cell overlapping_cell;
	
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
		//ask water overlapping self{do die;}
		ask (agents of_generic_species water) overlapping self{do die;}
	}
	
	aspect default {
		if is_closed{
			draw circle(0.75#km) color:  #red  border: #black;
		}else{
			if self.type = "source" {
				draw circle(0.75#km) color:  #blue  border: #black;
			}else if self.type = "sink" {
				draw circle(0.75#km) color:  #white  border: #black;
			}else{
				draw circle(0.75#km) color:  #green  border: #black;
			}
		}
	}

//	aspect default {
//		if self.type = "source" {
//			draw circle(0.75#km) color:  #blue  border: #black;
//		}else{
//			if self.type = "sink" {
//				draw circle(0.75#km) color:  #white  border: #black;
//			}else{
//				if is_closed{
//					draw circle(0.75#km) color:  #red  border: #black;
//				}else{
//					draw circle(0.75#km) color:  #green  border: #black;
//				}
//			}
//		}
//	}
}

experiment devVisuAgents type: gui autorun:true{
	output {
		display "As DEM" type: opengl draw_env:false background:#black synchronized:true refresh: every(1#cycle) {
			species cell aspect:base transparency: 0.2;	
			species main_river aspect:base;			
			species river aspect:base transparency: 0.6;
			species pollution transparency: 0.2;
			species water transparency: 0.2;
			
			species gate;
			
			event mouse_down action:mouse_click;
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
			
			event mouse_down action:mouse_click;
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

			event mouse_down action:mouse_click;			
			event["g"] action: {showGrid<-!showGrid;};
			event["b"] action: {showBlock<-!showBlock;};
		}

	} 
}