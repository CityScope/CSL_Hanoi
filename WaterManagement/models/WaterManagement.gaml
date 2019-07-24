/**
* Name: Water Management Bac Hung Hai
* Author:  Arnaud Grignard
* Description: 
* Tags: grid, load_file, asc
*/

model watermanegement

global {
	file riverShapefile<- shape_file('../includes/River/BACHUNGGAI_River.shp');
	geometry shape <- envelope(riverShapefile);	
	list<string> cellsTypes <- ["Gate", "Fish", "Rice","Vegetables", "Industrial", "Hospital"];
	map<string, rgb> cellsColors <- ["Gate"::#black, "Fish"::#blue, "Rice"::#green,"Vegetables"::#darkgreen, "Industrial"::#red, "Hospital"::#orange ];
	
	init{
		create river from:riverShapefile;

	}
	
	reflex update when: cycle>1{
		save cell to:"./../results/grid.asc" type:"asc";
	}
}


grid cell width: 16 height: 16{
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

experiment gridloading type: gui {
	output {
		display "As DEM" type: opengl{
			species cell aspect:base;
			species river aspect:base;
		}

	} 
}