/**
 *  emotesV7
 *  Author: bgaudou
 *  Description: 
 */

model emotesV8

import "globals.gaml"
import "people.gaml"
import "peoplePureStrategy.gaml"
import "peopleFictitiousPlay.gaml"
import "iteratedGame.gaml"

import "expPureStrat.gaml"
import "expFictitiousPlay.gaml"
import "expBatch.gaml"
import "expSequentialGame.gaml"

global	{
	// Initialization
	int nbAgentsPerGA;
	float guiltAversionInitMax <- 2.0;
	float guiltAversionInitMin <- 0.0;
	float guiltAversionStep <- 0.1;
	// -> Distribution
	float guiltAversionMean;
	float guiltDispersion;
	string guiltLaw; // Uniform or Normal
	int nbOfAgtOfSample;
	
	int precision; // ?
	
	// Noise
	float guiltNoise; // Situationnal noise
	float rationalNoise; // Rationality noise
	float idealityNoise; // Belief noise
	float stratNoise; // Impulsiv strategy change
	
	// Mode of simulation
	string peopleStrategy <- 'Pure';   	// ['Pure','Fictious play']
	string evolutionMode <- 'None';		// ['None','Replicator dynamic']
	string idealComputation <- 'Rawls';	// ["Rawls","Harsanyi","mixRawlsHarsanyi"]
	
	// Debug global variables
	int numAgentToDisplay <- -1;
	int otherAgentToDisplay <- -1;
	
	// The game values	 
	int R;
	int P;
	int T; 
	int S;
	
	float sumPayoff <- 0.0;
	
	list<people> peoples -> {agents of_generic_species people};
	
	init {
		do create_game_instance(["T"::T,"R"::R,"P"::P,"S"::S]);
	}
	
	action reset_game{
		// Kill the agent game and agent peoples (this is obviously a contextual comment ... :D)
		ask iterated_game_instance {
			ask peoples_in_instance { do die; }
			do die;
		}
		
		// Init the next instance of the PD game
		game_configuration_index <- game_configuration_index + 1;
		map<string, int> next_config <- self stringConfToMapTRPS(valid_configuration at game_configuration_index);
		do create_game_instance(next_config);
		
		cycle_to_sub <- cycle;
	}
	
	action create_game_instance(map configuration){
		create iterated_game_instance {
			do init_manually(configuration);
		}
	}
}