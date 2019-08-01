/**
* Name: Water Management Bac Hung Hai
* Author:  Arnaud Grignard
* Description: 
* Tags: grid, load_file, asc
*/

model watermanegement

global {
	file riverShapefile<- shape_file('../includes/OpenData/BACHUNGHAI_River.shp');
	file riverShapePolygonfile<- shape_file('../includes/OpenData/BACHUNGHAI_River_polygon.shp');
	file gateShapefile<- shape_file('../includes/OpenData/BACHUNGHAI_Gate.shp');
	file redriverPOIShapefile<- shape_file('../includes/OpenData/red_river_poi.shp');
	file gridShapefile<- shape_file('../includes/OpenData/cell.shp');
	file landUsefile <- shape_file('../includes/OpenData/land_use.shp');
	
	
	graph the_river;
	geometry shape <- envelope(riverShapefile);	
	list<string> cellsTypes <- ["Fish", "Rice","Vegetables", "Industrial", "Hospital"];
	map<string, rgb> cellsColors <- [cellsTypes[0]::#darkblue, cellsTypes[1]::#green,cellsTypes[2]::#darkgreen, cellsTypes[3]::#red, cellsTypes[4]::#orange ];
	bool showGrid<-true;
	bool showBlock<-true;
	
	init{
		create land from: landUsefile;
		create river from:riverShapefile;
		create river from:riverShapePolygonfile;
		create poi from:gateShapefile{
			type<- flip(0.5) ? "source" :"outlet";
		}		
		create block from: gridShapefile with:[type::string(get("TYPE"))]{
		}
		the_river <- as_edge_graph(river);
		
		ask river {
			ask cell overlapping self {
				type <- "Water";
				color<-#black;//rgb(rnd(100)*1.1,rnd(100)*1.6,200,50);
			}
		}
	}
	
	reflex c_water  {
		create water {
			location <- one_of(poi where (each.type = "source")).location;
			target <- one_of(poi where (each.type = "outlet")) ;
			color<-#blue;
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
species water skills: [moving] {
	poi target ;
	rgb color;

	reflex move {
		do goto target: target on: the_river speed: 150.0;
		if(location=target.location){
			do die;
		}
	}	
	
	aspect default {
		draw circle(250) color: color border: color-25;
	}
}

species river{
	aspect base{
		draw shape color:#blue width:2;
	}
}


species poi {
	string type;
	
	aspect default {
		draw circle(0.75#km) color: (type="source") ? #green : #red border: #black;		
	}	
}


experiment dev type: gui autorun:true{
	output {
		display "As DEM" type: opengl draw_env:false background:#black synchronized:true {
		    species land aspect:base;
		    species block aspect:base;
		    species cell aspect:base;// transparency:0.5; 
			species river aspect:base;
			species water;
			species poi;
			
			event["g"] action: {showGrid<-!showGrid;};
			event["b"] action: {showBlock<-!showBlock;};
		}
	} 
}

experiment gridloading type: gui autorun:true{
	output {
		display "As DEM" type: opengl draw_env:false background:#black fullscreen:1 toolbar:false synchronized:true
		keystone: [{0.11789471987553607,0.17655677527359326,0.0},{0.14152218549855694,0.8209276100000611,0.0},{0.7190140590924565,0.8238821725750515,0.0},{0.733678653352665,0.17609555446014113,0.0}]{    
			species land aspect:base;
			species cell aspect:base;// transparency:0.5; 
			species river aspect:base;
			species water;
			species poi;
			event["g"] action: {showGrid<-!showGrid;};
			event["b"] action: {showBlock<-!showBlock;};
		}

	} 
}