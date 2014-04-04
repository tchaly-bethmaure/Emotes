/**
 *  peopleV5
 *  Author: bgaudou 
 *  Description: 
 */

model peopleFictitiuousPlayV1 

import "globals.gaml"
import "people.gaml" 

species peopleFictitiousPlay parent: people {
	string strategy;
	// History of the interactions : map of agent::[nbCoop, totalInter, utilityGained, lastCoop, nbStepWithoutChange]
	map<people,list<int>> history; 
	map<people,list<int>> historyRecent;
	
	// ideality is a map of (s::idealValue), i.e. (list of: string)::(int)
	map<list<string>,int> ideality;
	// guilt is a map of (s::guiltValue), i.e. (list of: string)::(int)		
	map<list<string>,int> guilt;
	// guiltDependentUtility
	map<list<string>,int> guiltDependentUtility;
	
	init {					
		// stratIdeal shape : [s1,s2]::IdValue
//		loop stratIdeal over: ideality.pairs {
//			int gValue <- stratIdeal.value;
//			int max <- max(possibleActions collect (ideality at ([each,last(list(stratIdeal.key))])));
//			add (gValue-max) at: stratIdeal.key to: guilt;
//		}
//		if(debugGame){do displayGuilt;}
//		
//		// Map utility : (s::utilityValue), i.e. (list of: string)::int
//		map<list<string>,int> utility <- map(game.pairs collect (each.key::int(first(list(each.value)))));
//		guiltDependentUtility <- map(game.keys collect (each::((utility at each) + guiltAversion*(guilt at each))));
//		if(debugGame){do displayUtilitySTAR;}
	}
	
	string play_with (people p) {			
		string choice <- one_of(possibleActions);
		// eltOfHisto : [nbCoop, totalInter, lastCoop, nbStepWithoutChange]
		list<int> eltOfHisto <- history at p;
		map<string,float> listProbaIbarre <- map([]);
		if(playWithDebug) {write 'eltOfHisto ' + eltOfHisto;}
		
		if(eltOfHisto = []){
			listProbaIbarre <- map(["C"::0.5, "D"::0.5]);
		} else {
			listProbaIbarre <- map(["C"::((eltOfHisto at 0) / (eltOfHisto at 1)),
									"D"::1-((eltOfHisto at 0) / (eltOfHisto at 1))]);
		}
		if(playWithDebug) {write 'listProbaIbarre ' + listProbaIbarre;}
		
		// Expected utility
		map<string,float> expectedUtilities <- map([]);
		loop pchoice over: possibleActions {
			float expectedUtility <- 0.0;
			loop jchoice over:listProbaIbarre.pairs {
				expectedUtility <- expectedUtility + float(jchoice.value) * float(guiltDependentUtility at [pchoice,jchoice.key]);
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
		// s : [s1,s2]
		int payoff <- 0;
		if(payoffEmo) {
			payoff <- ((guiltDependentUtility at s));
		} else {
			payoff <- (game at s) at 0;
		}
		sumPayoffs <- sumPayoffs + payoff;	
		
		// add in the history
		// eltOfHisto is a list : [nbCoop, totalInter, utilityGained, lastCoop, nbStepWithoutChange]	
		list<int> eltOfHisto <- history at p;
		int coopRes <- (s at 1) = "C" ? 1 : 0;
		
		if(eltOfHisto = []){
			add [coopRes,1,payoff, coopRes, 0] at:p to: history;
		} else {
			add [(eltOfHisto at 0) + coopRes, 
				 (eltOfHisto at 1) + 1,
				 (eltOfHisto at 2) + payoff,
				 coopRes,
				 ((eltOfHisto at 3) = coopRes) ? (eltOfHisto at 4) + 1 : 0] at: p to: history;
		}
		if(cycleObs < cycle){
			list<int> eltOfHistoObs <- historyRecent at p;
			
			if(eltOfHistoObs = []){
				add [coopRes,1,payoff] at: p to: historyRecent;
			} else {
				add [(eltOfHistoObs at 0) + coopRes, 
				     (eltOfHistoObs at 1) + 1,
				     (eltOfHistoObs at 2) + payoff] at: p to: historyRecent;
			}				
		}		
			
	}	
}
