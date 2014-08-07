/**
 *  peopleFictitiuousPlayV8
 *  Author: bgaudou 
 *  Description: 
 */

model peopleFictitiuousPlayV8 

import "globals.gaml"
import "people.gaml" 

species peopleRationalPlay parent: people {
	map<people, string> lastMove_with_people <- map([]);
	
	// This kind of people playing rationally concider that the opponent will ether play C or D with the same probability,
	// there is no history or behavioural memorisation of the opponent.
	string play_with (people p) {
		string choice <- one_of(possibleActions);
		
		// Expected utility
		map<string,float> expectedUtilities <- map([]);
		// Possible action <- C or D
		loop pchoice over: possibleActions {
			float expectedUtility <- 0.0;
			loop jchoice over:possibleActions {
				expectedUtility <- expectedUtility + float(guiltDependentUtility at [pchoice,jchoice]);
			}
			add expectedUtility at: pchoice to: expectedUtilities;
		}
		if(playWithDebug) {write 'expectedUtilities star    ' + expectedUtilities; }
		
		if((expectedUtilities at "C") = (expectedUtilities at "D")){
			choice <- one_of(expectedUtilities.keys);
			if(playWithDebug) {write 'choice (random) ' + choice;}
		}
		else {
			choice <- (expectedUtilities.pairs with_max_of each.value).key;
			if(playWithDebug) {write 'choice (from expected utilities) ' + choice;}
		}
		
		return choice;
	}
	
	action resolve_game (people p, list<string> s) {
		// s : [s_1,s_2]  (s_i strategy played by agent i, 1 is the current agent)
		int payoff <- 0;
		if(payoffEmo) {
			payoff <- (guiltDependentUtility at s);
		} else {
			payoff <- (game at s) at 0;
		}
		stepPayoff <- payoff;
		sumPayoffs <- sumPayoffs + payoff; // Ne sert pas , si ? @@@@@@@
		lastMove_with_people[p] <- ((s at 1) = "C") ? 1 : ((s at 1) = "D" ? 0 : -1);
	}
}