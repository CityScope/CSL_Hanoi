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


grid cell width: 13 height: 13{
	string type;
	init{
		type<-one_of (cellsTypes);
	}
	aspect base{
		draw shape*0.9 color:cellsColors[type];
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
		display "As DEM" type: opengl draw_env:false background:#black fullscreen:1 toolbar:false
		keystone: [{0.16180121847129988,0.22946079240946138,0.0},{0.18077106522363712,0.7852474747946201,0.0},{0.6771033104328638,0.79365130564027,0.0},{0.692433154671796,0.23466785914628063,0.0}]{
			species cell aspect:base;
			species river aspect:base;
			species gate aspect:base;
		}

	} 
}