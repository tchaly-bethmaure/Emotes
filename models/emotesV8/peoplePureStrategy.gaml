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
		int payoff <- 0;
		if(payoffEmo) {
			payoff <- ((guiltDependentUtility at s));
		} else {
			payoff <- (game at s) at 0;
		}
		sumPayoffs <- sumPayoffs + payoff;	
	}
}
