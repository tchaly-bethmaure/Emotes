/**
 *  peoplePureStrategyV8
 *  Author: bgaudou 
 *  Description: People implemented with pure strategy (used for the replicator dynamic):
 * 		- they have a pure strategy 
 * 		- they are characterized by their strategy and guiltAversion (si, gai)
 */

model peoplePureStrategyV8

import "globals.gaml"
import "people.gaml"

species peoplePureStrategy parent: people {
	string strategy;
	
	string play_with (people p) {
		return strategy;
	}
	
	action resolve_game (people p, list<string> s) {
		// s : [s_1,s_2]  (s_i strategy played by agent i, 1 is the current agent)
		float payoff <- 0;
		if(payoffEmo) {
			payoff <- ((guiltDependentUtility at s));			
		} else {
			payoff <- (game at s) at 0;
		}
		stepPayoff <- payoff;
		sumPayoffs <- sumPayoffs + payoff;
	}
	
	action replicate(peoplePureStrategy p){
		string newStrategy <- p.strategy;
		float newGuilt <- p.guiltAversion;
		string newIdealMode <- p.idealMode;
		
		int dice <- rnd(100);
		if(dice <= floor(probaEvolution)){
			// Noise = mutation
			// -> replication and rnd() mutation of strategy.
			if(bNoise and rnd(100) <= stratNoise){strategy <- rnd(1)=0?"D":"C";} // Strategy mutation
			else{ strategy <- newStrategy; }	
			// -> replication and rnd() mutation of guilt aversion.
			if(bMimicGuilt){if(bNoise and rnd(100) <= guiltNoise){guiltAversion <- one_of(people).guiltAversion;} // Strategy mutation
			else{ guiltAversion <- guiltAversion; }}
			// -> replication and rnd() mutation of ideality.
			if(bMimicIdeal){if(bNoise and rnd(100) <= idealityNoise){idealMode <- one_of(people).idealMode; do computeIdeality();} // Strategy mutation
			else{ idealMode <- newIdealMode; do computeIdeality();}}
		}			
	}
}
