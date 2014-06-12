/**
 *  configTool
 *  Author: root
 *  Description: 
 */

model configTool

global {
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