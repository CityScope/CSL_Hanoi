/***
* Name: TestData
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model TestData

global {
	shape_file Network_BHH0_shape_file <- shape_file("../includes/Network/Network_BHH.shp");
	shape_file BACHUNGHAI_River_Polygon0_shape_file <- shape_file("../includes/OpenData/BACHUNGHAI_River_Polygon.shp");
	shape_file BACHUNGHAI_River0_shape_file <- shape_file("../includes/OpenData/BACHUNGHAI_River.shp");

	geometry shape <- envelope(Network_BHH0_shape_file);

	init {
		create riverMike from: Network_BHH0_shape_file;
		create riverPolygon from: BACHUNGHAI_River_Polygon0_shape_file;
		create river from: BACHUNGHAI_River0_shape_file;
	}
}

species riverMike {
	aspect default {
		draw shape color: #green;
	}
}
species riverPolygon {
	aspect default {
		draw shape color: #red;
	}
}
species river {
	aspect default {
		draw shape color: #blue;
	}	
}

experiment TestData type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display d {
			species riverMike;
			species riverPolygon;
			species river;
		}
	}
}
