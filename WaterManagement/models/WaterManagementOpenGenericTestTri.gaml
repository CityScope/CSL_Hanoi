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
	
	
	file riverShapefile<- shape_file('../includes/OpenData/BACHUNGHAI_River.shp');
	file riverShapePolygonfile<- shape_file('../includes/OpenData/BACHUNGHAI_River_polygon.shp');
	file riverGraphFile <- shape_file("../includes/TuiLoiData/river_splitted.shp");
	file tram_mua_shapefile <- file("../includes/TuiLoiData/TramMua.shp");
	file gateShapefile<- shape_file('../includes/OpenData/BACHUNGHAI_Gate.shp');
	file redriverPOIShapefile<- shape_file('../includes/OpenData/red_river_poi.shp');
	file landUsefile <- shape_file('../includes/OpenData/land_use.shp');
	
	
	graph the_river;
	graph river_graph;
	geometry shape <- envelope(riverShapefile);	
	list<string> cellsTypes <- ["Fish", "Rice","Vegetables", "Industrial", "Hospital"];
	map<string, rgb> cellsColors <- [cellsTypes[0]::#darkblue, cellsTypes[1]::#green,cellsTypes[2]::#darkgreen, cellsTypes[3]::#red, cellsTypes[4]::#orange ];
	bool showGrid<-true;
	bool showBlock<-true;
	
	Station source;
	Station dest;
	
	map<riverG,float> probaEdges;
//	list<riverG> closedRivers;
	
	float evaporationRate <- 10.0;
	
	init{
		create river from:riverShapefile;
		create river from:riverShapePolygonfile;
		create riverG from:riverGraphFile;
		create gate from:gateShapefile{
			type<- flip(0.5) ? "source" :"outlet";
		}		
		create Station from: tram_mua_shapefile ;
		source <- first(Station where (each.Name = "Song Hong"));
		dest <- first(Station where (each.Name = "Song Thai Binh")); 
		ask Station{
			controledRivers <- riverG overlapping self;
		}
		
		the_river <- as_edge_graph(riverG);
		probaEdges <- create_map(riverG as list,list_with(length(riverG),100.0));
		
		ask river {
			ask cell overlapping self {
				type <- "Water";
				color<-#black;//rgb(rnd(100)*1.1,rnd(100)*1.6,200,50);
			}
		}
		create land from:landUsefile;
		
//		// here, we create dummy check points where water enter the system ("in") or leave the system ("out")
//		// it will be updated when we have a proper shapefile
//		list<point> vertices <- the_river.vertices;
//		loop v over: vertices where (each.x < 3000 or each.x > 80000 or each.location.y < 5000 or each.location.y > 82000){
//			if the_river degree_of v <= 1{
//				create flowRegulator{
//					self.location <- v.location;
//					if (v.x > 80000) or (v.y > 82000){
//						type <- "outlet";
//					}
//				} 
//			}		
//		}
		
		/*create block{
			location<-{world.shape.width/2-world.shape.width*0.05,world.shape.height/2};
			shape<-square(world.shape.width*0.750);
		}
		save block to:"../results/bounds.shp" type:"shp";*/
	}
	
	reflex manage_water  {
		ask riverG{
			waterLevel <- 0;
		}
		ask water{
			riverG(self.current_edge).waterLevel <- riverG(self.current_edge).waterLevel+1;
		}
		probaEdges <- create_map(riverG as list, riverG collect(100/(1+each.waterLevel)));
		ask riverG where each.is_closed{
			put 0.001 at: self in: probaEdges;
		}
		
		create water {
			location <- source.location;//one_of(flowRegulator where (each.type = "source")).location;
			target <- dest.location;//one_of(flowRegulator where (each.type = "outlet")) ;
			color<-#blue;
		}
		ask dest {
			do take_water;
		}
	}
	
	
	reflex updateGrid{
		/*ask cell{
			if (flip(0.005) and type!="Water") {
				type<-one_of (cellsTypes);
			}
		}*/
	}
	
	action activate_act {
		Station selected_station <- first(Station overlapping (circle(1) at_location #user_location));
		if selected_station != nil{
			selected_station.is_closed <- !selected_station.is_closed;
			ask selected_station.controledRivers {
				self.is_closed <- !(self.is_closed);
//				put 0.01 at: self in: probaEdges;
			}
		}
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
	point target ;
	rgb color;
	int amount<-250;
//	map<riverG,float> probaEdgesSelf ;
	riverG edge;
	float tmp;

	reflex move {
//		do goto target: target on: the_river speed: 150.0;

//		probaEdgesSelf <- copy(probaEdges);
//		if edge != nil{
//			put 1.0 at: edge in: probaEdgesSelf;	
//		}
//		do wander on: the_river speed: 300.0 proba_edges: probaEdgesSelf;
		
		if edge != nil{
			tmp <- probaEdges[edge];
			put 1.0 at: edge in: probaEdges;	
		}
		do wander on: the_river speed: 300.0 proba_edges: probaEdges;
		if edge != nil{
			put tmp at: edge in: probaEdges;	
		}
		edge <- riverG(current_edge);
		if(location=target.location){
			do die;
		}
	}	
	
	aspect default {
//		draw line({location.x-amount*cos(heading-90),location.y-amount*sin(heading-90)},{location.x+amount*cos(heading-90),location.y+amount*sin(heading-90)})  color: color border: color-25;
//		draw line({location.x-amount*cos(heading-90),location.y-amount*sin(heading-90)},{location.x+amount*cos(heading-90),location.y+amount*sin(heading-90)})  color: #pink border: color-25;
		draw circle(0.25#km)  color: #blue ;
	}
}

species river{
	aspect base{
		draw shape color:#blue width:2;
	}
}

species riverG{
	int waterLevel <- 0;
	bool is_closed <- false;
	
	aspect base{
		draw shape color: is_closed? #red:#blue width:1;
	}
}


species gate {
	string type;
	aspect default {
		draw circle(0.75#km) color: (type="source") ? #green : #red border: #black;		
	}	
}

//species flowRegulator{
//	string type <- "source" among:["source","outlet"];
//		aspect default {
//			draw circle(0.75#km) color: (type="source") ? #white:#grey;		
//	}	
//}

species Station skills: [moving] {
	rgb color <- rnd_color(255);
	string Name;
	geometry shape <- circle(0.75#km);	
	bool is_closed<-false;
	list<riverG> controledRivers <- [];

//	user_command "Switch" {
//		is_closed<-!is_closed;
//	}

	action take_water {
		ask water overlapping self{do die;}
	}

	aspect default {
		if self = source {
			draw circle(0.75#km) color:  #blue  border: #black;
		}else{
			if self = dest {
				draw circle(0.75#km) color:  #white  border: #black;
			}else{
				if is_closed{
					draw circle(0.75#km) color:  #red  border: #black;
				}else{
					draw circle(0.75#km) color:  #green  border: #black;
				}
			}
		}
		
		
//		draw cube(0.01) color: #red;
//		draw circle(rad) color: #red empty: true;
//		draw Name + " " + " " + TL_level + " " + HL_level size: 10 at: {location.x,location.y,0.015} color: #red perspective:false; 
//		if (TL_area != nil) {
//			draw TL_area color: #green;
//		}
//
//		if (HL_area != nil) {
//			draw HL_area color: #green;
//		}
	}

}


experiment dev type: gui autorun:true{
	output {
		display "As DEM" type: opengl draw_env:false background:#black synchronized:true {
//		    species block;
//		    species cell aspect:base;// transparency:0.5; 
//			species river aspect:base;
			species riverG aspect:base transparency: 0.6;
			species water transparency: 0.5;
//			species gate;
//			species flowRegulator;
			species Station;
			//species land aspect:base;
			event mouse_down action:activate_act;
			event["g"] action: {showGrid<-!showGrid;};
			event["b"] action: {showBlock<-!showBlock;};
		}
	} 
}

experiment cityscope type: gui autorun:true{
	output {
		display "As DEM" type: opengl draw_env:false background:#black fullscreen:1 toolbar:false synchronized:true
		keystone: [{0.11656421991808863,0.167109629356474,0.0},{0.14285268545600432,0.8143146078580775,0.0},{0.7170183091562854,0.8153797412496441,0.0},{0.735674403288836,0.16759312313473373,0.0}]{	//species land aspect:base;
			species cell aspect:base;// transparency:0.5; 
			species river aspect:base;
			species riverG aspect:base;
			species water;
			species gate;
//			species flowRegulator;
			event["g"] action: {showGrid<-!showGrid;};
			event["b"] action: {showBlock<-!showBlock;};
		}

	} 
}