/**
 *  peopleV5
 *  Author: bgaudou 
 *  Description: 
 */

model peoplePureStrategyV1  

import "globals.gaml"
import "people.gaml"
 
// People implemented for the replicator dynamic:
// - they have a pure strategy 
// - they are characterized by their strategy and guiltAversion (si, gai)

species peoplePureStrategy parent: people {
	float money;
	float guiltAversion;
	string strategy;
	
	// ideality is a map of (s::idealValue), i.e. (list of: string)::(int)
	map<list<string>,int> ideality;
	// guilt is a map of (s::guiltValue), i.e. (list of: string)::(int)		
	map<list<string>,int> guilt;
	// guiltDependentUtility
	map<list<string>,int> guiltDependentUtility;
	
	init {					
		// stratIdeal shape : [s1,s2]::IdValue
		loop stratIdeal over: ideality.pairs {
			int gValue <- stratIdeal.value;
			int max <- max(possibleActions collect (ideality at ([each,last(list(stratIdeal.key))])));
			add (gValue-max) at: stratIdeal.key to: guilt;
		}
		if(debugGame){do displayGuilt;}
		
		// Map utility : (s::utilityValue), i.e. (list of: string)::int
		map<list<string>,int> utility <- map(game.pairs collect (each.key::int(first(list(each.value)))));
		guiltDependentUtility <- map(game.keys collect (each::((utility at each) + guiltAversion*(guilt at each))));
		if(debugGame){do displayUtilitySTAR;}
	}
	
	string play_with (people p) {			
		return strategy;
	}
	
	action resolve_game (people p, list<string> s) {
		// s : [s1,s2]
		int payoff <- 0;
		if(payoffEmo) {
			payoff <- ((guiltDependentUtility at s));
		} else {
			payoff <- (game at s) at 0;
		}
		sumPayoffs <- sumPayoffs + payoff;	
	}
}
