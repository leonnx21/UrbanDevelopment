model NewModel

global {	
	shape_file road_shapefile <- shape_file("../includes/roads15_3.shp");
	
	geometry shape <- envelope(road_shapefile);
	graph road_network;
	path shortest_path;
	float close_down_rate <- 0.08;
	int tax;
	int index <- 1;
	
	int size <- 500;
	int x <- round(shape.height/size); //need to get from shape file road
	int y <- round(shape.width/size);
	
	int nb_homes -> {length(homes)};
	int nb_businesses -> {length(businesses)};
	int nb_greensquare -> {length(greensquare)};
	
	int total_pol1 <- 0;
	int total_pol2 <- 0;
	int total_pol3 <- 0;
	int total_pol4 <- 0;

	init{
			create roads from: road_shapefile;
			road_network <- as_edge_graph(roads);
			
			
			//created dummy for illustration in development
			create homes number: 10;
			create businesses number: 10;
	}
	
	reflex pause_experiment when: time= index*10{
		index <- index +1;
		do pause;
	}
	
	reflex pollution_caculate{
		int district_width <- round(y/3);
		
		loop i from: 0 to: district_width step: 1{
			loop j from: 0 to: x step: 1 {
				if (plot[i, j] != nil){
					int temp <- plot[i, j].pol;
					total_pol1 <- total_pol1 + temp;
				}
			}
		}
		
		loop i from: district_width to: 2 * district_width step: 1{
			loop j from: 0 to: x step: 1 {
				if (plot[i, j] != nil){
					int temp <- plot[i, j].pol;
					total_pol2 <- total_pol2 + temp;
				}
			}
		}
		
		loop i from: 2 * district_width to: x step: 1{
			loop j from: 0 to: x step: 1 {
				if (plot[i, j] != nil){
					int temp <- plot[i, j].pol;
					total_pol3 <- total_pol3 + temp;
				}
			}
		}
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
	int pol;
	int nbpol;
	
	reflex updatepol{
		loop i over: self.neighbors{
			nbpol <- pol;
			nbpol <- nbpol + i.pol;	
//			write(i.nbpol);
		}
	}
	
	aspect default{
		draw square(size);			
	}		
}



//traffic creates pollutions
species roads{
	list<plot> my_plots;
	init {
		my_plots <- plot overlapping self;
			loop i over: my_plots{
//				i.color <- #red;
				loop j over: i.neighbors{
					j.is_free <-true;
//					j.pol <-1;
				}
//				i.pol <-2;
			}	
//		write my_plots;
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
			tax <- tax+10;
			my_plot.pol <- 3;
//			write("home at random location");
		}else{
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <-"home";
			tax <- tax+10;
			my_plot.pol <- 3;
//			write("home at selected location "+ my_plot);
		}
	}
		

	reflex new_home{
		source <- one_of(businesses);
		target <- one_of(businesses);
		
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
	
	reflex destroy_home when: flip(close_down_rate){
		my_plot.is_free <- true;
		my_plot.type <- nil;
		do die;
	}
	
	
//	reflex new_random_home when: flip(close_down_rate){
//		create homes number: 1 with: (my_plot: one_of(my_plot.neighbors));
//	}

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
		if(my_plot = nil){
			my_plot <- one_of(plot where (each.is_free = true));
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <-"business";
			tax <- tax+20;
			
			my_plot.pol <- 5;
//			write("business at random location");
		}else{
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <-"business";
			tax <- tax+20;
			my_plot.pol <- 5;
//			write("business at selected location:"+ my_plot);
		}
	}
	
	reflex new_business{
		plot home_plot <- one_of(plot where(each.type = "home"));
		plot new_plot <- one_of(home_plot.neighbors where(each.is_free = true));
		
		if(new_plot != nil){
			int nbhome <- count(new_plot.neighbors, each.type = "home");
//			write ("number of home: "+nbhome);
			if (nbhome >2)
			{
				create businesses number: 1 with: (my_plot: new_plot);	
			}
		}
		
	}
	
	reflex close_business when: flip(close_down_rate){
		my_plot.is_free <- true;
		my_plot.type <- nil;
		do die;
	}
	
//	reflex new_random_business when: flip(close_down_rate){
//		create businesses number: 1 with: (my_plot: one_of(my_plot.neighbors));
//	}
	
	aspect default{
        draw square(size) color: #blue;
    }
}

//locations are decided by government/users
species greensquare {
	plot my_plot;
		
	init{
		my_plot <- first(plot overlapping #user_location);
		if (my_plot.is_free =true){
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <- "green";
			my_plot.pol <- -5;
			write("case 1");
			tax <- tax-100;
		}else if(my_plot.is_free = false and my_plot.type = nil){
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <- "green";
			my_plot.pol <- -5;
			write("case 1.1");
			tax <- tax-50;
		}else if(my_plot.is_free = false and my_plot.type ="home"){
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <- "green";
			my_plot.pol <- -5;
			ask homes overlapping my_plot{
				do die;
			}
			tax <- tax-200;
			write("case 2");
		}
		else if(my_plot.is_free = false and my_plot.type ="business"){
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <- "green";
			my_plot.pol <- -5;
			ask businesses overlapping my_plot{
				do die;
			}
			if !(tax - 400 < 0){
				tax <- tax-400;
			}else{
				write("not enough money!");
			}
			
			write("case 3");
			}
		else{
			write("case 4");
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
		
		display chart_display refresh:every(1#cycles) {
            chart "Urban Development" type: series {
                 data "Number of homes" value: nb_homes style: line color: #blue ;
             	 data "Number of businesses" value: nb_businesses style: line color: #red ;
             	 data "Number of green square" value: nb_greensquare style: line color: #green;
         	}
         }
         
         display pollution_chart refresh:every(1#cycles){
         	chart "Pollution of 4 districts" type: series{
         		data "District I" value: total_pol1 color: #red;
         		data "District II" value: total_pol2 color: #green;
         		data "District III" value: total_pol3 color: #yellow;
//         		data "District IV" value: total_pol4 color: #blue;
         	}
         }
		
		monitor "Tax amount" value: tax refresh: true;
	}
}