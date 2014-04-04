/**
 *  bruteconfgenerator
 *  Author: root
 *  Description: 
 */

model bruteconfgenerator

global {
	// Var data file
	string file_name <- "all_conf-1_to_10.csv";
		
	// Vars BF
	list<int> numbers <- [0,1,2,3,4,5,6,7,8,9,10];
	int number_of_panels <- 4; // T R P S
	list<int> panels_index;
	
	init{ do generate_all_configuration(true); }
	
	// Bruteforce //
	action generate_all_configuration(bool shuffle_list_b4_return){
		list<string> valid_configuration <- [];
		
		// Init channel		
		loop from:0 to:number_of_panels - 1{ add(0) to:panels_index; }
		
		// Generate conf
		loop while: !increment_panel(0){
			string new_configuration <- "";
			loop i from:0 to:number_of_panels - 1{ new_configuration <- new_configuration + string(numbers[panels_index[i]]) + " "; }
			if(is_good_conf_for_PD(new_configuration)){ add(new_configuration) to:valid_configuration; }
		}
		
		// Save to a csv file		
		string data <- "";
		loop line over:valid_configuration{
			data <- data + line + ";";
		}
		write data;
		save data type: "csv" to: file_name;
	}
	
	// Tools related to the BF //
	bool is_next_pannel(int index){
		if(index + 1 >= number_of_panels){ return false; }
		return true;
	}
	
	bool is_max_value(int index){
		if(panels_index[index] = numbers[length(numbers) - 1]){ return true; }
		return false;
	}
	
	bool increment_panel(int current_index){
		if(!is_max_value(current_index)){
			 panels_index[current_index] <- panels_index[current_index] + 1;
		}
		else { 
			if(is_next_pannel(current_index)){
				panels_index[current_index] <- 0;
				return increment_panel(current_index + 1); 				
			}
			else{ return true; }	// it's over	
		}
		return false;
	}
	
	// Tools related to prisonner's dilemma //	
	string config_to_string(int T, int R, int P, int S){ return string(T)+" "+string(R)+" "+string(P)+" "+string(S); }
	
	bool is_good_conf_for_PD (string conf){		
		map<string,int> config_map <- string_to_mapTRPS(conf);
		if (config_map["T"] > config_map["R"] and config_map["R"] > config_map["P"] and config_map["P"] > config_map["S"] and ( config_map["R"] > int(config_map["T"]/2) + int(config_map["S"]/2))){ return true; }
		return false;
	}
		
	map<string,int> string_to_mapTRPS(string conf){
		list<string> TRPS <- conf split_with " ";
		
		int T <- int(TRPS at 0);
		int R <- int(TRPS at 1); 
		int P <- int(TRPS at 2);
		int S <- int(TRPS at 3);
		
		return ["T"::T, "R"::R, "P"::P, "S"::S];
	}	
	
}

experiment generate_file type: gui {
	output{
	}
}

