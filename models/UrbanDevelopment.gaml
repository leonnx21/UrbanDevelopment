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
	int size <- 500;
	int x <- round(shape.height/size); //need to get from shape file road
	int y <- round(shape.width/size);

	init{
			create roads from: road_shapefile;
			
			//created dummy for illustration in development
			//create homes number: 100;
			//create businesses number: 100;
			//create greensquare number: 100;
	}
	
	action my_action
    {
        create greensquare number: 1;
    }
	
}

//x and y needs to adapt to shape file road dynamically
grid plot height: x width: y neighbors: 8{
	bool is_free <- true;
	
	aspect default{
			draw square(100) ;			
		}		
}

//traffic creates pollutions
species roads{
	aspect default {
		draw (shape + 10) color: #black;
	}
}

//Needs to add reflex destroy, build
species buildings{
	plot my_plot;
	
	init {
		my_plot <- one_of(plot where (each.is_free = true));
		//location <- my_plot.location;
		my_plot.is_free <- false;
	}
}

//inherits from building
//location bases on happiness level
//property of buildings: number of inhabitants, hapiness level  
species homes parent:buildings{
	
	reflex{
		//TODO
	}

	aspect default{
        draw square(size) color: #red;
    }
}

//inherits from buildings
//location bases on number of inhabitants
// buiness creates jobs, facility --> increase hapiness --> need formula
//businesses creates pollution -> decrease hapiness
species businesses parent:buildings{
	
	init{
		//TODO
	}
	
	aspect default{
        draw square(size) color: #blue;
    }
}

//locations are decided by government/users
species greensquare parent:buildings{
	plot my_plot;
	//geometry dummysq <- square(size, location::#user_location);
	
	init{
		create pointer with: [location::#user_location];
		my_plot <- first(plot overlapping (first(pointer)));
		if (my_plot.is_free = true){
			location <- my_plot.location;
		}
		ask pointer{
			do die;
		}
	}
		
		
	aspect default{
        draw square(size) color: #green;
    }
}

species pointer {
	geometry shape<- square(size/1000) ;
}


experiment UrbanDevelopment type: gui {
	/** Insert here the definition of the input and output of the model */
	parameter "size of buildings" var:size;

	
	output {
 		display map {
			species roads;
			species homes;
			species businesses;
			species greensquare;
			grid plot transparency:0.7 border:#red;
			event 'g' action: my_action;
			
		}
	}
		
}
