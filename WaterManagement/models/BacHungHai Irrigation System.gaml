/***
* Name: Water flow in a river graph, using water flow in rivers
* Author: Benoit Gaudou and Patrick Taillandier
* Description: In this model, the flow of water is modeled through the exchange of water between elements of rivers.
* 	The only water input comes (every 20 steps) from the source points. Then the water flows toward the outlet point.
* Tags: shapefile, gis, graph, gui, hydrology, water flow
***/

model Waterflowrivergraph

global {
	file river_shape_file <- shape_file("../includes/TuiLoiData/river_splitted.shp");
	file tram_mua_shapefile <- file("../includes/TuiLoiData/TramMua.shp");
	file land_use_file <- shape_file('../includes/TuiLoiData/land_use.shp');
	
	geometry shape <- envelope(river_shape_file) +0.01;
	Station source;
	Station dest;
	graph the_river;
	float max_buffer<-0.004;
	action init_BHH {
//		create region from:BHH_shape_file;
		create river from: river_shape_file;
		create land from: land_use_file with:[code::int(read("CODE")),
			land_use::string(read("LANDUSE")),simple::string(read("SIMPLE")),area::float(read("AREA_HA")),id::int(read("ID"))
		];
		ask river{
//			buffer_shape<-shape;
			neighbor_river<-river where (each intersects self);
		}
		create Station from: tram_mua_shapefile ;
		source <- first(Station where (each.Name = "Song Hong"));
		dest <- first(Station where (each.Name = "Song Thai Binh")); 
		the_river <- as_edge_graph(river); 
	}
	
	reflex water_flow { 
		 if (every(1000#cycles)) {
			ask source  {
				do give_water;
			}	
			ask dest{
				do give_water;
			}
		 }
//		  else {	

//		 if (every(2#cycles)) {	
			ask river {
				do water_flow;
			}
			ask river {
				do update_water_level;
			}			
//		}
	}
}

species poi {
	string type;
	river closest_river ;
	
//	action give_water {
//		closest_river.water_volume <- 200.0;
//	}
	
	aspect default {
		draw circle(0.005) color: (type="source") ? #green : #red border: #black;		
	}	
}
species Station skills: [moving] {
	rgb color <- rnd_color(255);
//	list<float> heso <- [];
	float hh <- 0.0;
	float rad <- 0.01;
	string Name;
	int ll <- 0;
	geometry shape <- rectangle(0.005, 0.0025);
	float perception_distance <- rad;
	geometry TL_area;
	geometry HL_area;
	float TL_level <- 0.0;
	float HL_level <- 0.0;
	
	bool is_closed<-false;
//	list<int> pa;
	
	user_command "Switch" {
		is_closed<-!is_closed;
	}
	action give_water {
//		write "give water";
		ask river overlapping self{water_volume <-water_volume+ 0.002;}
	}

	action take_water {
		ask river overlapping self{water_volume <-water_volume -0.0004;}
	}

	aspect default {
		draw cube(0.01) color: #red;
		draw circle(rad) color: #red empty: true;
		draw Name + " " + " " + TL_level + " " + HL_level size: 10 at: {location.x,location.y,0.015} color: #red perspective:false; // heso[cycle mod 4388] + 
		if (TL_area != nil) {
			draw TL_area color: #green;
		}

		if (HL_area != nil) {
			draw HL_area color: #green;
		}

	}

}
species land{
	int code;
	string land_use;
	string simple;
	float area;
	int id;
	
	action change_landuse{
		
	}
	action update_status{
		
	}
	aspect base{
		draw shape color:#brown border:#black;
	}
}
species region{
	aspect default{
		draw shape color:#darkgray border:#black;
	}
}
species river {
	list<river> neighbor_river ;
	float water_volume;
	float water_volume_from_other;
	float evapo_rate<-0.25;
	action water_flow {
		float avg<-water_volume / length(neighbor_river);
		list<river> inactive<-[];
		ask neighbor_river{
			Station mine<-first(Station where (each intersects self));
			if(mine!=nil and mine.is_closed){
				inactive<+self;				
			}
		} 
		ask	neighbor_river - self -inactive {			
			water_volume_from_other <- water_volume_from_other + 1.4*avg;//0.5*myself.water_volume;
		}
	}
	
	action update_water_level {
		float avg<-water_volume / length(neighbor_river);
		water_volume <- avg + water_volume_from_other;
		water_volume<-water_volume>max_buffer?max_buffer:water_volume;
		water_volume_from_other <- 0.0;
	}
	reflex evapo{
		water_volume<-water_volume-evapo_rate*(rnd(15)/10)*water_volume;
	}
	
	aspect default {
		draw shape color: #blue;	
		draw shape + water_volume color: #blue;
		
			
	}
}

experiment flow type: gui {
	init{
		ask world{
			do init_BHH;
		}
	}
	output {
	 	display "Water Unit" type:opengl{ 
//	 		species region;
			species river ; 
//			species poi;
			species Station;	
			species land aspect:base transparency:0.8 ;		
		}
	}
}
