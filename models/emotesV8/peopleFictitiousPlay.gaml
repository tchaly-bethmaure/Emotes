/**
 *  peopleFictitiuousPlayV8
 *  Author: bgaudou 
 *  Description: 
 */

model peopleFictitiuousPlayV8 

import "globals.gaml"
import "people.gaml" 

species peopleFictitiousPlay parent: people {
	// History of the interactions : map of agent::[nbCoop, totalInter, utilityGained, lastCoop, nbStepWithoutChange]
	map<people,list<int>> history; 
	map<people,list<int>> historyRecent;
	
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
		// s : [s_1,s_2]  (s_i strategy played by agent i, 1 is the current agent)
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
