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
	
	reflex updateGrid{
		ask cell{
			if (flip(0.005) and type!="Water") {
				type<-one_of (cellsTypes);
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
		    //species land aspect:base;
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
		keystone: [{0.11656421991808863,0.167109629356474,0.0},{0.14285268545600432,0.8143146078580775,0.0},{0.7170183091562854,0.8153797412496441,0.0},{0.735674403288836,0.16759312313473373,0.0}]{	//species land aspect:base;
			species cell aspect:base;// transparency:0.5; 
			species river aspect:base;
			species water;
			species poi;
			event["g"] action: {showGrid<-!showGrid;};
			event["b"] action: {showBlock<-!showBlock;};
		}

	} 
}