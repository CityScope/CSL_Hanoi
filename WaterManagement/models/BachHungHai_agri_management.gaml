/**
* Name: Water Management Bac Hung Hai
* Author:  Arnaud Grignard, Tri Nguyen-Huu, Benoit Gaudou
* Description: Wter Management Bac Hung Hai - MIT CityScope - IRD UMMISCO - WARM
* Tags: grid, load_file, asc
*/

model watermanagement

global {

	file gates_shape_file <- shape_file("../includes/BachHungHaiData/gates.shp");
	file rivers_shape_file <- shape_file("../includes/BachHungHaiData/rivers.shp");
	file main_rivers_shape_file <- shape_file("../includes/BachHungHaiData/main_rivers_simple.shp");
	file river_flows_shape_file <- shape_file("../includes/BachHungHaiData/river_flows.shp");
	file landuse_shape_file <- shape_file("../includes/BachHungHaiData/VNM_adm4.shp");
	
	graph the_river;
	geometry shape <- envelope(main_rivers_shape_file);	
	
	map<int,string> cellsMap<-[1::"Aquaculture", 2::"Rice",3::"Vegetables", 4::"Industrial", -1::"Null"];
	list<string> cells_types <- ["Aquaculture", "Rice","Vegetables", "Industrial", "Null"];
	
	map<string, rgb> cells_colors <- [cells_types[0]::#orange, cells_types[1]::#darkgreen,cells_types[2]::#lightgreen, cells_types[3]::#red, cells_types[4]::#black];
	map<string, float> cells_withdrawal <- [cells_types[0]::0.5, cells_types[1]::3.0,cells_types[2]::0.25, cells_types[3]::4.0];
	map<string, int> cells_pollution <- [cells_types[0]::55, cells_types[1]::0,cells_types[2]::20, cells_types[3]::90];
	map<string,matrix<int>> lego_code <-["Aquaculture"::matrix([[1,1],[1,0]]),"Rice"::matrix([[1,0],[0,0]]),"Vegetables"::matrix([[1,0],[0,1]]),"Industrial"::matrix([[1,0],[1,0]])];

	bool showGrid parameter: 'Show grid' category: "Parameters" <-false;
	bool showWater parameter: 'Show Water' category: "Parameters" <-true;
	bool showLanduse parameter: 'Show LandUse' category: "Parameters" <-true; 
	bool showDryness parameter: 'Show Dryness' category: "Parameters" <-false; 
	
	bool showLegend parameter: 'Show Legend' category: "Legend" <-true;
    bool showOutput parameter: 'Show Output' category: "Legend" <-true;
	
	bool keystoning parameter: 'Show keystone grid' category: "Keystone" <-false;
	
	// Network for scanning and slider
	int scaningUDPPort <- 9877 parameter: "Scanning UDP port" category: "Parameters" ;
	string url <- "localhost";
	bool udpScannerReader <- true;  
	
	int sliderUDPPort <- 9878 parameter: "Arduino UDP port" category: "Parameters" ;
	bool udpSliderArduino <- true; 

	string cityIOUrl;	
	bool load_grid_file_from_cityIO parameter: 'cityIO' category: "Parameters" <-true;
	bool launchpad<-false;
	bool table_interaction <- true;
	bool debug <- false;
	
	list<gate> source;
	list<gate> dest;
	
	map<river,float> probaEdges;
	
	float evaporationAvgTime parameter: 'Evaporation time' category: "Parameters" step: 10.0 min: 2.0 max:10000.0 <- 2500.0 ;
	float StaticPollutionEvaporationAvgTime parameter: 'Pollution Evaporation time' category: "Parameters" step: 10.0 min: 2.0 max:10000.0 <- 500.0 ;
	int grid_height <- 8;
	int grid_width <- 8;
	
	// dryness parameters
	int dryness_removal_amount parameter: 'Water Evaporation time' category: "Parameters" step: 10 min: 10 max:1000 <- 100 ; 
	
	init{
		cityIOUrl <- launchpad ? "https://cityio.media.mit.edu/api/table/launchpad": "https://cityio.media.mit.edu/api/table/urbam";
		create main_river from:main_rivers_shape_file{
			shape<-(simplification(shape,100));
		}
		create river from: rivers_shape_file;
		create gate from: gates_shape_file with: [type:: string(read('Type'))];
		create landuse from: landuse_shape_file with:[type::string(get("SIMPLE"))]{
			shape<-(simplification(shape,100));
		}
		create eye_candy from:river_flows_shape_file with: [type:: int(read('TYPE'))];
		
		ask cell {
			do init_cell;
		}
		
		ask river {
			overlapping_cell <- first(cell overlapping self);
		}
		
		ask landuse {
			if !empty(cell overlapping self) {
				cell c <- (cell overlapping self) with_max_of(inter(each.shape,self.shape).area);
				c.landuse_on_cell <+ self;
			}
		}
		
		source <- gate where (each.type = "source");
		dest <- gate where (each.type = "sink");
		
		ask gate {
			controledRivers <- river overlapping (0.4#km around self.location);
		}
		
		the_river <- as_edge_graph(river);
		probaEdges <- create_map(river as list,list_with(length(river),100.0));
		
		if(udpScannerReader){
			create NetworkingAgent number: 1 {
			 type <-"scanner";	
		     do connect to: url protocol: "udp_server" port: scaningUDPPort ;
		    }
		}
		if(udpSliderArduino){
			create NetworkingAgent number: 1 {
			 type <-"slider";	
		     do connect to: url protocol: "udp_server" port: sliderUDPPort ;
		    }
		}
	}
	
	reflex manage_water  {
		ask river {
			waterLevel <- 0;
		}
		ask water {
			river(self.current_edge).waterLevel <- river(self.current_edge).waterLevel+1;
		}
		ask polluted_water {
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
			cell c <- river(self.current_edge).overlapping_cell;
			if flip(cells_withdrawal[ c.type] * 0.01){
				ask c.landuse_on_cell {
					 self.dryness <- max(self.dryness - dryness_removal_amount,0);	
				}
				if(flip(cells_pollution[ c.type] * 0.01)) {
					create polluted_water {
						location <- myself.location;
						heading <- myself.heading;
						type<-c.type;
					}		
				}	
			do die;
			}
		}	
		
		ask polluted_water where(each.current_edge != nil) {
			if flip(cells_withdrawal[ river(self.current_edge).overlapping_cell.type] * 0.01){
				create static_pollution number: 8{
					dissolution_expectancy<-StaticPollutionEvaporationAvgTime * (0.8 + rnd(0.4));
					color <- myself.color;
					location <- any_location_in(3#km around(myself.location));
				}
				if(flip(cells_pollution[ river(self.current_edge).overlapping_cell.type] * 0.01)) {
					create polluted_water {
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
			//ask landuse overlapping selected_cell{
			ask selected_cell.landuse_on_cell{
			  self.color<-cells_colors[selected_cell.type];
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
			cityMatrixData <- json_file("../includes/urbam.json").contents;
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
			   // write id;
			    if(id =0 or id=1 or id=2 or id=3){
			     cell[x,y].type<-cellsMap.values[id];	
			     if(rot=1 or rot=3){
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
			     ask landuse overlapping cell[x,y]{
			     		self.color<-cells_colors[cell[x,y].type];
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
	list<landuse> landuse_on_cell <- [];
	
	init {
		type<-one_of (cells_types);
	}
	
	action init_cell {
		rivers_on_cell <- river overlapping self;
	}

	aspect base{
		if(showGrid){
			if(type="Water"){
				draw shape color:color border: #white;	
			}else{
			  	draw shape color:cells_colors[type];	
			}	
		}
		if keystoning {
				draw 100.0 around(shape * 0.75) color: #black;
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
		do wander on: the_river speed: 600.0 proba_edges: probaEdges;
		if edge != nil{
			put tmp at: edge in: probaEdges;	
		}
		edge <- river(current_edge);
	}
	
	reflex evaporate when: (flip(1/evaporationAvgTime)){
		do die;
	}
	
	aspect default {
		if(showWater){
		  draw square(0.25#km)  color: color;		
		}
	}
}

species polluted_water parent: water {
	rgb color <- #red;
	string type;
	
	aspect default {
		draw square(0.25#km)  color: cells_colors[type];	
	}
}

species static_pollution{
	rgb color;
	float dissolution_expectancy;
	
	reflex remove_pollution{
		dissolution_expectancy <- dissolution_expectancy - 10;
		if dissolution_expectancy < 0 {
			do die;
		}
		
	}
	
	aspect{
		draw square(0.2#km) color: color;
	}
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
	  draw shape color: is_closed? #red:rgb(235-235*sqrt(min([waterLevel,8])/8),235-235*sqrt(min([waterLevel,8])/8),255) width:3;		
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
			draw circle(0.75#km)-circle(0.4#km) color:  #red  border: #black;
		}else{
			if self.type = "source" {
				draw circle(0.75#km) - circle(0.40#km) color:  #cyan  border: #black;
			}else if self.type = "sink" {
				draw circle(0.75#km) - circle(0.40#km) color:  #white;//  border: #black;
			}else{
				draw circle(0.75#km)-circle(0.4#km) color:  #green  border: #black;
			}
		}
	}
}


species landuse{
	string type;
	rgb color;
	int dryness <- 500;
	
	reflex dry when: (dryness < 1000) {
		dryness <- dryness + int(dryness_removal_amount/100);
	}
	
	aspect base{
	  if(showLanduse){
	  	
	  	if(showDryness){
	  		draw shape color:(dryness>500) ? #red :#green  border:#black;
	  	    //draw string(dryness) color:#white size:50;	
	  	}else{
	  		draw shape color:color border:#black;
	  	}
	  }	
	}
}


species eye_candy{
	int type;
	
	aspect base{
		if mod(cycle,3) = mod(type,3){
			draw shape color:#blue;
		}
		if mod(cycle-1,3) = mod(type,3){
			draw shape color:rgb(50,50,255);
		}
		if mod(cycle-2,3) = mod(type,3){
			draw shape color:rgb(100,100,255);
		}
	}
}

species NetworkingAgent skills:[network] {
	
	string type;
	string previousMess <-"";
	
	reflex fetch when:has_more_message() and type = "slider"{		
		if (length(mailbox) > 0) {
			message s <- fetch_message();
			if(s.contents !=previousMess){	
			  previousMess<-s.contents;
			  evaporationAvgTime<-2.0+float(previousMess)/5.0*5000;			  
			}	
	    }
	}
	
	reflex update_landuse when: has_more_message() and type = "scanner"{
		list<list<int>> scan_result <- [];    
	    
	    if (length(mailbox) > 0) {
			message mes <- fetch_message();				
 			list m <- string(mes.contents) split_with('[, ]');
 			loop i from:0 to: length(m)-2 step: 2 {
 				scan_result <+ [int(m[i]),int(m[i+1])];
			}
			int ncols <- sqrt(length(scan_result)) as int;
			int nrows <- sqrt(length(scan_result)) as int;	    
			int x;
			int y;
			int id;
			int rot;
			if (ncols > 0){ // Debug divide by zero
				loop i from: 0 to: length(scan_result) - 1 {
					if ((i mod nrows) mod 2 = 0 and int(i / ncols) mod 2 = 0) {
						x <- grid_width - 1 - int((i mod nrows) / 2);
						y <- grid_height - 1 - int((int(i / ncols)) / 2);
						if(debug) {
							write "" + i + " - x - " + x + " - y - " + y + " - " + scan_result[i][0];	
						}
						id <- scan_result[i][0];
						rot <- scan_result[i][1];
						// write id;
						if (id = 0 or id = 1 or id = 2 or id = 3) {
							cell[x, y].type <- cellsMap.values[id];
							if (rot = 0 or rot = 2) {
								ask gate overlapping cell[x, y] {
									if (self.type != "source" and self.type != "sink") {
										is_closed <- true;
										ask self.controledRivers {
											self.is_closed <- true;
										}
									}
								}
							} else {
								ask gate overlapping cell[x, y] {
									if (self.type != "source" and self.type != "sink") {
										is_closed <- false;
										ask self.controledRivers {
											self.is_closed <- false;
										}
									}
								}
							}
		
							ask landuse overlapping cell[x, y] {
								self.color <- cells_colors[cell[x, y].type];
							}
						}else{
							cell[x, y].type <- "Null";//cellsMap.values[id];
						}
					}
				} 
			}
		} 
	} 
}


experiment dev type: gui autorun:true{
	output {
		display "Bac" type: opengl draw_env:false background:#black synchronized:true refresh: every(1#cycle)
		{
			species landuse aspect:base transparency:0.65;
			species cell aspect:base transparency: 0.6;	
			species main_river aspect:base;			
			species river aspect:base transparency: 0.2;
			species polluted_water transparency: 0.2;
			species static_pollution transparency: 0.5;
			species water transparency: 0.2;
			
			species eye_candy aspect: base;
			
			species gate;
			
			event mouse_down action:mouse_click;
			event["g"] action: {showGrid<-!showGrid;};
			event["l"] action: {showLegend<-!showLegend;};
			event["w"] action: {showWater<-!showWater;};
			
			graphics 'background'{
				draw shape color:#white at:{location.x,location.y,-10};
			}
			
			overlay position: { 180#px, 250#px } size: { 180 #px, 100 #px } background:#black transparency: 0.0 border: #black rounded: true
            {   
            	if(showLegend){
// previous overlay, kept for rolling back
//            		float x <- -70#px;
//					float y <- -203#px;
//	            	draw "CityScope Hanoi" at: { x, y } color: #white font: font("Helvetica", 32,#bold);
//	            	draw "\nWater Management" at: { x, y } color: #white font: font("Helvetica", 20,#bold);
//		            
					float x <- -70#px;
					float y <- -150#px;
		            draw "CityScope" at: { x, y } color: #white font: font("Helvetica", 32,#bold);
		            draw "\nHanoi" at: { x, y } color: #white font: font("Helvetica", 32,#bold);
	            	draw "\n\nWater Management" at: { x, y + 35#px } color: #white font: font("Helvetica", 17,#bold);
	            	
	            	y <- 190#px;
	            	draw "INTERACTION" at: { x,  y } color: #white font: font("Helvetica", 20,#bold);
	            	y<-y+25#px;
	            	draw "Landuse" at: { x,  y } color: #white font: font("Helvetica", 20,#bold);
	            	y<-y+25#px;
	            	
	                loop type over: cells_types where (each != "Null")
	                {
	                    draw square(20#px) at: { x + 10#px, y } color: #white;
						loop i from: 0 to: lego_code[type].rows - 1{
							loop j from: 0 to: lego_code[type].columns - 1{
								draw square(8#px) at: {x + (5+i*10)#px, y + (-5+j*10)#px} color: lego_code[type][i,j]=1?#black:#white;
							}
						}
	                    draw square(20#px) at: { x + 40#px, y } color: cells_colors[type] border: cells_colors[type]+1;
	                    draw string(type) at: { x + 60#px, y + 7#px } color: #white font: font("Helvetica", 20,#bold);
	                    y <- y + 25#px;
	                }
	                
	                y <- y + 40#px;
	                draw "Gate" at: { x + 0#px,  y+7#px } color: #white font: font("Helvetica", 20,#bold);
	            	y <- y + 25#px;
	                draw circle(10#px)-circle(5#px) at: { x + 20#px, y } color: #green border: #black;
	                draw 'Open' at: { x + 40#px, y + 7#px } color: #white font: font("Helvetica", 20,#bold);
	                y <- y + 25#px;
	                draw circle(10#px)-circle(5#px) at: { x + 20#px, y } color: #red border: #black;
	                draw 'Closed' at: { x + 40#px, y + 7#px } color: #white font: font("Helvetica", 20,#bold);
//	                y <- y + 25#px;
//	                draw circle(10#px)-circle(5#px) at: { x + 20#px, y } color: #cyan border: #black;
//	                draw 'Source' at: { x + 40#px, y + 4#px } color: #white font: font("Helvetica", 20,#bold);
//	                y <- y + 25#px;
//	                draw circle(10#px)-circle(5#px) at: { x + 20#px, y } color: #white border: #black;
//	                draw 'Sink' at: { x + 40#px, y + 4#px } color: #white font: font("Helvetica", 20,#bold);
	                y <- y + 25#px;
	                draw "Turn lego to open" at: { x + 0#px,  y+4#px } color: #white font: font("Helvetica", 20,#bold);
	            	draw "\nand close" at: { x + 0#px,  y+4#px } color: #white font: font("Helvetica", 20,#bold);
	            
            	} 
            	if(showOutput){
            		float xOutput<-1550#px;
	            	
	            	float y <- 300#px;
	            	y<-y+75#px;
	                draw "OUTPUT" at: { xOutput+0#px,  y+4#px } color: #white font: font("Helvetica", 20,#bold);
	                y<-y+25#px;
	                draw "Pollutante" at: { xOutput+0#px,  y+4#px } color: #white font: font("Helvetica", 20,#bold);
	            	y<-y+25#px;
	                loop type over: cells_types
	                {
	                    draw circle(4#px) at: { xOutput+20#px, y } color: cells_colors[type] border: cells_colors[type]+1;
	                    draw string(type) + ": " +length(polluted_water where (each.type= type)) at: { xOutput+40#px, y + 4#px } color: #white font: font("Helvetica", 20,#bold);
	                    y <- y + 15#px;
	                }
	                 y <- y + 25#px;
               	 	draw string("Evaporation rate") at: { xOutput+0#px, y + 4#px } color: #white font: font("Helvetica", 20,#bold);
                	y <- y + 25#px;
                	draw rectangle(200#px,2#px) at: { xOutput+100#px, y } color: #white;
                	draw rectangle(2#px,10#px) at: { xOutput+(evaporationAvgTime/10000.0)*200#px, y } color: #white;
                	
                	y <- y + 50#px;
                	draw string("135 000ha - 2000km of canal") at: { xOutput+0#px, y + 4#px } color: #white font: font("Helvetica", 20,#bold);
            		
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

experiment CityScopeHanoi type: gui autorun:true parent:dev{
	parameter "UDP port" var: scaningUDPPort <- 5000 category: "Parameters" ;
	parameter 'cityIO' var: load_grid_file_from_cityIO category: "Parameters" <-false;
	parameter 'debug mode' var: debug category: "Parameters" <-false;
	 
	output {
		display "Physical Table" type: opengl draw_env:false toolbar:false background:#black synchronized:true refresh: every(1#cycle) fullscreen:1 parent:"Bac"
	keystone: [{-0.09071592866970579,-0.04944466003423331,0.0},{-0.09251960586743271,1.0667782941941648,0.0},{1.0991328705050387,1.0523531694480113,0.0},{1.0953920074671133,-0.0683499712237926,0.0}]
	{}
	}
}
