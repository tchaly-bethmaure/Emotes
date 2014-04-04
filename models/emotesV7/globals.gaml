/**
 *  globals
 *  Author: bgaudou
 *  Description: 
 */

model globals

global {
	// Debug global variables	
	bool debugGame <- false;
	bool resolveGameDebug <- false;
	bool playWithDebug <- false;	
	
	// Replicator dynamic parameters
	int stepEvol;
	int nbAgentsEvol;
	bool payoffEmo;
	float probaMutation;
	
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

}

