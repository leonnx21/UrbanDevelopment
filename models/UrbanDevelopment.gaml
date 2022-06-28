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
	int x <- 500; //need to get from shape file road
	int y <- 500;

	init{
			create roads from: road_shapefile;
			
			//created dummy for illustration in development
			create homes number: 100;
			create businesses number: 100;
			create greensquare number: 20;
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
		location <- my_plot.location;
		my_plot.is_free <- false;
	}
	

}

//inherits from building
//location bases on happiness level
//property of buildings: number of inhabitants, hapiness level  
species homes parent:buildings{

	aspect default{
        draw square(500) color: #red;
    }
}

//inherits from buildings
//location bases on number of inhabitants
// buiness creates jobs, facility --> increase hapiness --> need formula
//businesses creates pollution -> decrease hapiness
species businesses parent:buildings{
	aspect default{
        draw square(500) color: #blue;
    }
}

//locations are decided by government/users
species greensquare parent:buildings{
	aspect default{
        draw square(500) color: #green;
    }
}


experiment NewModel type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
 		display map {
			species roads;
			species homes;
			species businesses;
			species greensquare;
			grid plot transparency:0.7 border:#red;
			
		}
	}
		
}
