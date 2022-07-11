model NewModel

global {	
	shape_file road_shapefile <- shape_file("../includes/roads15_3.shp");
	
	geometry shape <- envelope(road_shapefile);
	graph road_network;
	path shortest_path;
	float close_down_rate <- 0.00;
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
	
	float total_happiness <- 0.0;
	
	int road_pollution <- 10;
	int home_pollution <- 3;
	int business_pollution <- 20;
	int green_square_pollution_reduction <- 5;
	int pollution_multiplier <- 3;
	int business_proximity_multiplier <- 5;
	
	int shopping_freq <- 30;
	int business_shopping_threshold <- 30;
	float base_happiness <- 100.0;
	float happiness_threshold <- 0.1;

	init{
			create roads from: road_shapefile;
			road_network <- as_edge_graph(roads);
			
			
			//created dummy for illustration in development
			create homes number: 10;
			create businesses number: 10;
			
			loop i from: 0 to: round(y/3) step: 1{
				loop j from: 0 to: x step: 1 {
					plot[i, j].color <- #cornflowerblue;
				}
			}
			loop i from: round(y/3) to: 2 * round(y/3) step: 1{
				loop j from: 0 to: x step: 1 {
					plot[i, j].color <- #white;
				}
			}
			loop i from: 2 * round(y/3) to: 3 * round(y/3) step: 1{
				loop j from: 0 to: x step: 1 {
					plot[i, j].color <- #indianred;
				}
			}
	}
	
	reflex pause_experiment when: time= index*10{
		index <- index +1;
		do pause;
	}
	
	reflex happiness_calculate{
		total_happiness <- 0.0;
		loop i over: homes{
					total_happiness <- total_happiness + i.happiness;
				}
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
		
		loop i from: 2 * district_width to: 3 * district_width step: 1{
			loop j from: 0 to: x step: 1 {
				if (plot[i, j] != nil){
					int temp <- plot[i, j].pol;
					total_pol3 <- total_pol3 + temp;
				}
			}
		}
	}
	
	action create_green
    {
        create greensquare number: 1;
    }
    
    action create_home
    {
        create homes number: 1 with: (my_plot: first(plot overlapping #user_location));
    }
	
	
	action create_business
    {
       create businesses number: 1 with: (my_plot: first(plot overlapping #user_location));
    }
}

//x and y needs to adapt to shape file road dynamically
grid plot height: x width: y neighbors: 8{
	bool is_free <- false;
	string type;
	int pol;
	int pol_from_road;
	int nbpol;
	

	reflex updatepol{
		loop i over: self.neighbors{
			nbpol <- pol + pol_from_road;
			nbpol <- nbpol + i.pol;
		}
	}
	
//	reflex reset_pol{
//		pol <- 0;
//	}
	
	
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
			i.pol_from_road <- road_pollution;
			loop j over: i.neighbors{
				j.is_free <-true;
			}
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
	float happiness <- base_happiness;
	
	
	int inhabitants_number<- rnd(1000);
	
	init {
		if(my_plot = nil){		
			my_plot <- one_of(plot where (each.is_free = true));
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <-"home";
			tax <- tax + 10;
			my_plot.pol <- home_pollution;//parameter
//			write("home at random location");
		} else if (my_plot.is_free = false) {
			do die;
		} else{	
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <- "home";
			tax <- tax + 10;
			my_plot.pol <- home_pollution; //parameter
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
			if (shortest_path != nil){
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
	}
	
		reflex update_happiness{
			//int nbneighbor_business <- count(my_plot.neighbors, each.type = "business");			
//			bool b <- true;
			list<plot> p <- my_plot.neighbors;
			point b_plot <- businesses closest_to my_plot;
			float dist <- distance_to(self.location, b_plot) / size;
//			write("distance:" +dist);
		
			happiness <- base_happiness;
			
			happiness <- base_happiness + dist*business_proximity_multiplier - my_plot.nbpol*pollution_multiplier; 
			write ("hapiness: " + happiness);
		}

	
	
	
	reflex destroy_home when: (cycle mod 3 = 0){
		if (happiness < base_happiness*happiness_threshold){
			my_plot.is_free <- true;
			my_plot.type <- nil;
			do die;
		}
		
	}
	
	reflex shopping{
		loop times:shopping_freq{
			businesses a <- one_of(businesses);
			a.shoppingtime <- a.shoppingtime + 1;
		}
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
//buiness creates jobs, facility --> increase hapiness --> need formula
//businesses creates pollution -> decrease hapiness
species businesses{
	plot my_plot;
	int shoppingtimethreshold <- cycle max:business_shopping_threshold;
	int shoppingtime;
	
		
	init {
		if(my_plot = nil){
			my_plot <- one_of(plot where (each.is_free = true));
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <-"business";
			tax <- tax + 20;
			my_plot.pol <- business_pollution;
//			write("business at random location");
		}else if (my_plot.is_free = false) {
			do die;
		} else{
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <-"business";
			tax <- tax + 20;
			my_plot.pol <- business_pollution;
//			write("business at selected location:"+ my_plot);
		}
	}
		
	reflex new_business{
		plot home_plot <- one_of(plot where(each.type = "home"));
		plot new_plot <- one_of(home_plot.neighbors where(each.is_free = true));
		//plot new_plot <- one_of(plot where(each.is_free = true));
		
		if(new_plot != nil){
			int nbhome <- count(new_plot.neighbors, each.type = "home");
//			write ("number of home: "+nbhome);
			if (nbhome >2)
			{
				create businesses number: 1 with: (my_plot: new_plot);	
			}
		}
		
	}
	
	reflex close_business when: (cycle mod 3 = 0){
		if (shoppingtime<shoppingtimethreshold) {
			my_plot.is_free <- true;
			my_plot.type <- nil;
//			write("number of shopping time: " +shoppingtime);
			do die;
		}
	
	}
	
	
	reflex update_shopping_time{
		shoppingtime <- 0;
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
	list<plot> green_plot;
		
	init{
		my_plot <- first(plot overlapping #user_location);
		if (my_plot.is_free =true){
			if !(tax < 100){
				location <- my_plot.location;
				my_plot.is_free <- false;
				my_plot.type <- "green";
				my_plot.pol <- - green_square_pollution_reduction;
				write("case 1");
				tax <- tax-100;
			}else {
				bool  result <- user_confirm("Alert","You don't have enough money");
					do die;
			}
			if(my_plot.is_free = false and my_plot.type = nil){
				if !(tax < 50){
					location <- my_plot.location;
					my_plot.is_free <- false;
					my_plot.type <- "green";
					my_plot.pol <- -green_square_pollution_reduction;
					write("case 1.1");
					tax <- tax-50;
				}else{
					bool  result <- user_confirm("Alert","You don't have enough money");
					do die;
				}
			}
		}else if(my_plot.is_free = false and my_plot.type ="home"){
			if !(tax - 200 < 0){
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <- "green";
			my_plot.pol <- - green_square_pollution_reduction;
			ask homes overlapping my_plot{
				do die;
			}
				tax <- tax-200;
			}else{
				bool  result <- user_confirm("Alert","You don't have enough money");
				do die;
				write("not enough money!");
			}
		}
		else if(my_plot.is_free = false and my_plot.type ="business"){
			if !(tax - 400 < 0){
			location <- my_plot.location;
			my_plot.is_free <- false;
			my_plot.type <- "green";
			my_plot.pol <- -green_square_pollution_reduction;
			ask businesses overlapping my_plot{
				do die;
			}
				tax <- tax-400;
			}else{
				bool  result <- user_confirm("Alert","You don't have enough money");
				do die;
			}
			write("case 3");
			}
		else{
			write("case 4");
			do die;
		}
		
//		do create_nbgreen;
	}
		
//	action create_nbgreen{
//		green_plot <- my_plot.neighbors;
//		loop i over:green_plot{
//			create greensquare number: 1 with: (my_plot: i);
//		}
//	}
		
		
	aspect default{
        draw square(size) color: #green;
    }
}


experiment BuildCity type: gui {
	/** Insert here the definition of the input and output of the model */

	
	output {
		monitor "Tax amount" value: tax;
 		display map {
			species roads;
			species homes transparency:0.5;
			species businesses transparency:0.5;
			species greensquare transparency:0.5;
			grid plot transparency:0.7 border:#black;
			event 'g' action: create_green;
			event 'h' action: create_home;
			event 'b' action: create_business;
			
		}
		
		display chart_display refresh:every(1#cycles) {
            chart "Urban Development" type: series {
                 data "Number of homes" value: nb_homes style: line color: #red ;
             	 data "Number of businesses" value: nb_businesses style: line color: #blue ;
             	 data "Number of green square" value: nb_greensquare style: line color: #green;
             	 //data "Happiness" value: total_happiness style:line color: #cyan;
         	}
         }
         
         display pollution_chart refresh:every(1#cycles){
         	chart "Pollution of 3 districts" type: series{
         		data "District I" value: total_pol1 color: #red;
         		data "District II" value: total_pol2 color: #green;
         		data "District III" value: total_pol3 color: #yellow;
         	}
         }
		
		
//		monitor "Total happiness" value: total_happiness;
	}
	
	
//	parameter "size of buildings" category: "General" var:size;	
//	
//	parameter "Road pollution" category: "Pollution" var: road_pollution;
//	parameter "Home pollution" category: "Pollution" var: home_pollution;
//	parameter "Business pollution" category: "Pollution" var: business_pollution;
//	parameter "Green square pollution reduction" category: "Pollution" var: green_square_pollution_reduction;
//	
//	parameter "Pollution multiplier" category: "Interaction" var: pollution_multiplier;
//	parameter "Business distance multiplier" category: "Interaction" var: business_proximity_multiplier;
//
//	parameter "base happiness" category: "Interaction" var: base_happiness;
//	parameter "Minimum happiness" category: "Interaction" var: happiness_threshold;
//	parameter "Shopping frequency" category: "Interaction" var: shopping_freq;
//	parameter "Minimum shopping per cycle" category: "Interaction" var: business_shopping_threshold;
	
	
	
}