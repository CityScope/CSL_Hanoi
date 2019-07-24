/**
* Name: Water Management Bac Hung Hai
* Author:  Arnaud Grignard
* Description: 
* Tags: grid, load_file, asc
*/

model watermanegement

global {
	file riverShapefile<- shape_file('../includes/River/BACHUNGGAI_River.shp');
	file riverShapePolygonfile<- shape_file('../includes/River/BACHUNGGAI_River_polygon.shp');
	file gateShapefile<- shape_file('../includes/River/BACHUNGGAI_Gate.shp');
	geometry shape <- envelope(riverShapefile);	
	list<string> cellsTypes <- ["Fish", "Rice","Vegetables", "Industrial", "Hospital"];
	map<string, rgb> cellsColors <- ["Gate"::#black, "Fish"::#darkblue, "Rice"::#green,"Vegetables"::#darkgreen, "Industrial"::#red, "Hospital"::#orange ];
	
	init{
		create river from:riverShapefile;
		create river from:riverShapePolygonfile;
		create gate from:gateShapefile; 
		
		ask gate {
			ask cell overlapping self {
				type <- "Gate";
			}
		}

	}
	

	reflex update when: cycle>1{
		save cell to:"./../results/grid.asc" type:"asc";
	}
}


grid cell width: 20 height: 20{
	string type;
	init{
		type<-one_of (cellsTypes);
	}
	aspect base{
		draw shape color:cellsColors[type];
	}
}

species river{
	aspect base{
		draw shape color:#blue;
	}
}

species gate{
	aspect base{
		draw circle(1#km) color:#blue;
	}
}

experiment gridloading type: gui {
	output {
		display "As DEM" type: opengl{
			species cell aspect:base;
			species river aspect:base;
			species gate aspect:base;
		}

	} 
}