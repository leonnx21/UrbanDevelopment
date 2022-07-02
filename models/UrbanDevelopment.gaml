/**
* Name: NewModel
* Based on the internal skeleton template. 
* Author: LeonNguyen
* Tags: 
*/

model NewModel

global {	
	shape_file road_shapefile <- shape_file("../includes/roads15_3.shp");
	
	geometry shape <- envelope(road_shapefile);
	graph road_network;
	path shortest_path;
	
	int size <- 500;
	int x <- round(shape.height/size); //need to get from shape file road
	int y <- round(shape.width/size);

	init{
			create roads from: road_shapefile;
			road_network <- as_edge_graph(roads);
			
			//created dummy for illustration in development
			create homes number:500;
			create businesses number: 2;
			//create households;
			//create inhabitants number: 10000;
			//create greensquare number: 200;
	}
	
	action my_action
    {
        create greensquare number: 1;
    }
	
}

//x and y needs to adapt to shape file road dynamically
grid plot height: x width: y neighbors: 8{
	bool is_free <- false;
	string type;
	
	aspect default{
			draw square(size);			
		}		
}



//traffic creates pollutions
species roads{
	//plot my_plot;
	
	init {
		list<plot> my_plots <- plot overlapping self;
			loop i over: my_plots{
				loop j over: i.neighbors{
					j.is_free <-true;
				}
//			i.is_free <- false;				
			}
	}	
	
	aspect default {
		draw (shape+100) color: #black;
	}
}

			
//inherits from building
//location bases on happiness level
//property of buildings: number of inhabitants, hapiness level  
species homes {
	plot my_plot;
	point source;
	point target;
	geometry g;
	
	int inhabitants_number<- rnd(1000);
	
	init {
		if(my_plot = nil){
			my_plot <- one_of(plot where (each.is_free = true));
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <-"home";
//			write("home at random location");
		}else{
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <-"home";
//			write("home at selected location");
		}
	}
		
//	action build_home {
//			location <- my_plot.location;
//			my_plot.is_free <- false;
//			write("build home at: "+location);
//	}

	reflex new_home{
		source <- businesses[0];
		target <- businesses[1];
		
		if (source != target)
		{
//			write ("source: "+ source);
//			write ("target: "+ target);
			
			shortest_path <- path_between(road_network, source,target);
			
			geometry sp <- shortest_path.shape;	
//			write("shortest path: " +sp);
					
			list<plot> pl <- plot overlapping sp;
//			write("plot: "+ pl);	
			
			plot p <- one_of(one_of(pl).neighbors);
			
			if (p.is_free = true){
				create homes number: 1 with: (my_plot: p);
			}
			
			}
			
	}

	aspect default{
        draw square(size) color: #red;
    }
}



//inherits from buildings
//location bases on number of inhabitants
// buiness creates jobs, facility --> increase hapiness --> need formula
//businesses creates pollution -> decrease hapiness
species businesses{
	
	plot my_plot;
		
	init {
		my_plot <- one_of(plot where (each.is_free = true));
		location <- my_plot.location;
		my_plot.is_free <- false;
	}	
	
	reflex new_business{
		plot new_plot <- one_of(plot where (each.is_free = true));
		int nbhomes;
		loop i over: new_plot.neighbors{
			if(i.type = "home"){
				nbhomes <- nbhomes +1;
			}
		write("number of homes:"+ nbhomes);
		}
		
	}
	
	
	aspect default{
        draw square(size) color: #blue;
    }
}

//locations are decided by government/users
species greensquare {
	plot my_plot;
		
	init{
		my_plot <- first(plot overlapping #user_location);
		if (my_plot.is_free = true){
			location <- my_plot.location;
			my_plot.is_free <- false;
		}else{
			do die;
		}
	}
		
		
	aspect default{
        draw square(size) color: #green;
    }
}


experiment UrbanDevelopment type: gui {
	/** Insert here the definition of the input and output of the model */
	parameter "size of buildings" var:size;
	
	output {
 		display map {
			species roads;
			species homes transparency:0.5;
			species businesses transparency:0.5;
			species greensquare transparency:0.5;
			grid plot transparency:0.7 border:#black;
			event 'g' action: my_action;
			
		}
	}
		
}
