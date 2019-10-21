/**
* Name: Water Management Bac Hung Hai
* Author:  Arnaud Grignard, Tri Nguyen-Huu, Benoit Gaudou
* Description: Wter Management Bac Hung Hai - MIT CityScope - IRD UMMISCO - WARM
* Tags: grid, load_file, asc
*/

model watermanegement

global {

	file gates_shape_file <- shape_file("../includes/BachHungHaiData/gates.shp");
	file rivers_shape_file <- shape_file("../includes/BachHungHaiData/rivers.shp");
	file main_rivers_shape_file <- shape_file("../includes/BachHungHaiData/main_rivers.shp");
	
	graph the_river;
	geometry shape <- envelope(main_rivers_shape_file);	
	
	map<int,string> cellsMap<-[1::"Fish", 2::"Rice",3::"Vegetables", 4::"Industrial", 5::"Urban"];
	list<string> cells_types <- ["Fish", "Rice","Vegetables", "Industrial", "Urban"];
	map<string, rgb> cells_colors <- [cells_types[0]::#darkblue, cells_types[1]::#green,cells_types[2]::#darkgreen, cells_types[3]::#red, cells_types[4]::#orange ];
	map<string, float> cells_withdrawal <- [cells_types[0]::1.0, cells_types[1]::4.0,cells_types[2]::0.5, cells_types[3]::8.0, cells_types[4]::2.0];
	map<string, int> cells_pollution <- [cells_types[0]::25, cells_types[1]::0,cells_types[2]::20, cells_types[3]::90, cells_types[4]::30];

    bool showLegend parameter: 'Show Legend' category: "Parameters" <-true;
	bool showGrid parameter: 'Show grid' category: "Parameters" <-true;
	bool showWaterLevel parameter: 'Show Water Level' category: "Parameters" <-false; 
	
	list<gate> source;
	list<gate> dest;
	
	map<river,float> probaEdges;
	
	int evaporationAvgTime parameter: 'Evaporation time' category: "Parameters" step: 1 min: 1 max:10000 <- 2000 ;
	
	bool load_grid_file_from_cityIO <-true;
	bool launchpad<-false;
	bool table_interaction <- true;
	int grid_height <- 8;
	int grid_width <- 8;
	string cityIOUrl;
	
	init{
		cityIOUrl <- launchpad ? "https://cityio.media.mit.edu/api/table/launchpad": "https://cityio.media.mit.edu/api/table/urbam";
		create main_river from:main_rivers_shape_file;
		create river from: rivers_shape_file;
		create gate from: gates_shape_file with: [type:: string(read('Type'))];
		
		ask cell {
			do init_cell;
		}
		
		ask river {
			overlapping_cell <- first(cell overlapping self);
		}
		
		source <- gate where (each.type = "source");
		dest <- gate where (each.type = "sink");
		
		ask gate {
			controledRivers <- river overlapping self;
		}
		
		the_river <- as_edge_graph(river);
		probaEdges <- create_map(river as list,list_with(length(river),100.0));
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
						heading <- myself.heading;
						color <- cells_colors[river(myself.current_edge).overlapping_cell.type] ;
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
	
    reflex test_load_file_from_cityIO when: table_interaction and load_grid_file_from_cityIO and every(10#cycle) {
		if(launchpad){
	      do load_cityIO_v2(cityIOUrl);
		}else{
		  do load_cityIO_v2_urbam(cityIOUrl);
		}
		
	}
	
	action load_cityIO_v2(string cityIOUrl_) {
		map<string, unknown> cityMatrixData;
	    list<map<string, int>> cityMatrixCell;
	    	
		try {
			cityMatrixData <- json_file(cityIOUrl_).contents;
		} catch {
			//cityMatrixData <- json_file("../includes/cityIO_gama.json").contents;
			write #current_error + "Connection to Internet lost or cityIO is offline - CityMatrix is a local version from cityIO_gama.json";
		}
		int nbCols <- int(map(map(cityMatrixData["header"])["spatial"])["ncols"]);
		int nbRows <- int(map(map(cityMatrixData["header"])["spatial"])["nrows"]);
		loop i from: 0 to: nbCols-1 {
			loop j from: 0 to: nbRows -1{
				int id <-int(list(list(cityMatrixData["grid"])[j*nbCols+i])[0]);
				if(id!=-1){
			     cell[i,j].type<-cellsMap.values[id];	
			    }  
			}
        } 	
	}
	
	action load_cityIO_v2_urbam(string cityIOUrl_) {
		map<string, unknown> cityMatrixData;
	    list<map<string, int>> cityMatrixCell;	
		try {
			cityMatrixData <- json_file(cityIOUrl_).contents;
		} catch {
			cityMatrixData <- json_file("../includes/cityIO_Urbam.json").contents;
			write #current_error + "Connection to Internet lost or cityIO is offline - CityMatrix is a local version from cityIO_gama.json";
		}
		int ncols <- int(map(map(cityMatrixData["header"])["spatial"])["ncols"]);
		int nrows <- int(map(map(cityMatrixData["header"])["spatial"])["nrows"]);
		int x;
		int y;
		int id;
		int rot;
		loop i from:0 to: (ncols*nrows)-1{ 
			if((i mod nrows) mod 2 = 0 and int(i/ncols) mod 2 = 0){   
				x<- grid_width-1-int((i mod nrows)/2);
			    y<-grid_height-1-int((int(i/ncols))/2);
			    id<-int(list<list>(cityMatrixData["grid"])[i][0]);
			    rot<-int(list<list>(cityMatrixData["grid"])[i][1]);
			    if(id!=-1){
			     cell[x,y].type<-cellsMap.values[id];	
			     if(rot=0 or rot=3){
			     	ask gate overlapping cell[x,y]{
			     		if(self.type != "source" and self.type != "sink"){
			     			is_closed<-true;
			     			ask self.controledRivers {
								self.is_closed <- true;
						  	}
			     		}
			     		
			     	}
			     }else{
			        ask gate overlapping cell[x,y]{
			     		if(self.type != "source" and self.type != "sink"){
			     		 	is_closed<-false;
			     			ask self.controledRivers {
								self.is_closed <- false;
							}
			     		}
			     	}	
			     }
			    }  
			 } 		
       }	
	}	
}

grid cell width: 8 height: 8 {
	string type;
	rgb color;
	list<river> rivers_on_cell;
	
	init {
		type<-one_of (cells_types);
	}
	
	action init_cell {
		rivers_on_cell <- river overlapping self;
	}

	aspect base{
		if(showGrid){
			if(type="Water"){
				draw shape color:color;	
			}else{
			  	draw shape color:cells_colors[type];	
			}	
		}
	}
}

species water skills: [moving] {
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
		if(showWaterLevel){
			draw shape color: is_closed? #red:rgb(255-255*sqrt(min([waterLevel,8])/8),255-255*sqrt(min([waterLevel,8])/8),255) width:3;
		}else{
		draw shape color: is_closed? #red:#blue width:1;	
		}
		
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
}


experiment dev type: gui autorun:true{
	output {
		display "Bac" type: opengl draw_env:false background:#black synchronized:true refresh: every(1#cycle)
		{
			species cell aspect:base transparency: 0.2;	
			species main_river aspect:base;			
			species river aspect:base transparency: 0.6;
			species pollution transparency: 0.2;
			species water transparency: 0.2;
			
			species gate;
			
			event mouse_down action:mouse_click;
			event["g"] action: {showGrid<-!showGrid;};
			event["l"] action: {showLegend<-!showLegend;};
			event["w"] action: {showWaterLevel<-!showWaterLevel;};
			
			overlay position: { 180#px, 250#px } size: { 180 #px, 100 #px } background: # black transparency: 0.5 border: #black rounded: true
            {   if(showLegend){
            	draw "CityScope Hanoi \nWater Management" at: { 0#px,  4#px } color: #white font: font("Helvetica", 20,#bold);
            	
            	float y <- 70#px;
            	draw "Landuse" at: { 0#px,  y+4#px } color: #white font: font("Helvetica", 20,#bold);
            	y<-y+25#px;
                loop type over: cells_types
                {
                    draw square(20#px) at: { 20#px, y } color: cells_colors[type] border: cells_colors[type]+1;
                    draw string(type) at: { 40#px, y + 4#px } color: #white font: font("Helvetica", 20,#bold);
                    y <- y + 25#px;
                }
                y <- y + 50#px;
                draw "Gate" at: { 0#px,  y+4#px } color: #white font: font("Helvetica", 20,#bold);
            	y <- y + 25#px;
                draw circle(10#px) at: { 20#px, y } color: #green border: #black;
                draw 'Open' at: { 40#px, y + 4#px } color: #white font: font("Helvetica", 20,#bold);
                y <- y + 25#px;
                draw circle(10#px) at: { 20#px, y } color: #red border: #black;
                draw 'Closed' at: { 40#px, y + 4#px } color: #white font: font("Helvetica", 20,#bold);
                y <- y + 25#px;
                draw "Turn lego to open and close" at: { 0#px,  y+4#px } color: #white font: font("Helvetica", 20,#bold);
            	
            	}
                
            }
		}
	} 
}


experiment CityScope type: gui autorun:true parent:dev{
	output {
		display "Physical Table" type: opengl draw_env:false toolbar:false background:#black synchronized:true refresh: every(1#cycle) fullscreen:1 parent:"Bac"
		keystone: [{0.10098673129882907,0.05004077744224389,0.0},{0.13085030058460204,0.8869230259426092,0.0},{0.7411067492484581,0.8996998306504457,0.0},{0.7684598972967126,0.05583045771934214,0.0}]
		{}
	} 
}

//////////////////////////////////////////////////////////// TO CLEAN //////////////////////////////////////////////////////////

//TODO: DO we keep this?
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