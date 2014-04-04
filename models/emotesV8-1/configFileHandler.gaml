/**
 *  configGenerator
 *  Author: root
 *  Description: 
 */

model configFileHandler // ?

// Génère max_conf_same_scale*9
global {
	// The file extension is not supported yet in the function
	list<string> read_file_containing_config(string file_name, string file_path){		
		//container file_csv <- loaded_file contents("csv");
		return string(read(text(file_path+ "/" +file_name))) split_with ";";
	}
	
	bool is_good_conf_for_PD (string conf){		
		map<string,int> config_map <- string_to_mapTRPS(conf);
		if (config_map["T"] > config_map["R"] and config_map["R"] > config_map["P"] and config_map["P"] > config_map["S"] and ( 2 * config_map["R"] > config_map["T"] + config_map["S"])){ return true; }
		return false;
	}
	
	map<string, int> string_to_mapTRPS(string conf){
		list<string> TRPS <- conf split_with " ";
		
		int T <- int(TRPS at 0);
		int R <- int(TRPS at 1);
		int P <- int(TRPS at 2);
		int S <- int(TRPS at 3);
		
		return ["T"::T, "R"::R, "P"::P, "S"::S];
	}
}
	
