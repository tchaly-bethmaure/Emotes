/**
 *  globals
 *  Author: bgaudou
 *  Description: 
 */

model globalsV8

global {
	// Debug global variables	
	bool debugGame <- false;
	bool resolveGameDebug <- false;
	bool playWithDebug <- false;	
	bool check_fairplay <- true; // à supr
	bool bNoise;
	
	// Replicator dynamic parameters
	int stepEvol;
	int nbAgentsEvol;
	bool payoffEmo;
	float probaEvolution;
	float probaMutation;
	// -> mutation (or noise)
	float idealityNoise;
	float guiltNoise;
	float stratNoise;
	float rationalNoise;
	
	// Analysis parameters 
	// bool batchMode <- false;
	int cycleToSave;
	int cycleObs;	
	string fileName <- "../../results/resBatch.csv";
//	string fileNameObs;	
//	string fileNamePayoff;
	
	// The game 
	// game is a map of (s::listPayoff), i.e. (list of: string)::(list of: int)
	map<list<string>,list> game;
	list<string> possibleActions <- ["C","D"];
	
	
	// Tools related to prisonner's dilemma config checking //	
	string configToString(int T, int R, int P, int S){ return string(T)+" "+string(R)+" "+string(P)+" "+string(S); }

	bool isGoodConfigForPD (string conf){		
		map<string,int> config_map <- stringConfToMapTRPS(conf);
		if (config_map["T"] > config_map["R"] and config_map["R"] > config_map["P"] and config_map["P"] > config_map["S"] and ( config_map["R"] > int(config_map["T"]/2) + int(config_map["S"]/2))){ return true; }
		return false;
	}
	
	map<string,int> stringConfToMapTRPS(string conf){
		list<string> TRPS <- conf split_with " ";
		
		int T <- int(TRPS at 0);
		int R <- int(TRPS at 1);
		int P <- int(TRPS at 2);
		int S <- int(TRPS at 3);
		
		return ["T"::T, "R"::R, "P"::P, "S"::S];
	}
}