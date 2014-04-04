/**
 *  peopleV5
 *  Author: bgaudou
 *  Description: 
 */

model peopleV5  

import "mainV5.gaml"
 
species people {
	int money;
	float guiltAversion;
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
		// Ideality computation
		if(idealComputation = "Rawls"){
			ideality <- self computeRawlsIdeality();
		} else {
			ideality <- self computeHarsanyiIdeality();
		}
		if(debugGame){do displayIdeality;}
					
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

	map<list<string>,int> computeHarsanyiIdeality {
		// game : (list of: string)::(list of: int)
		// short version: ideality <- map(game.pairs collect (each.key::(sum(each.value))));
		ideality <- map([]);
		loop pairGame over: game.pairs {
			list<int> val <- pairGame.value;
			add sum(val) at: pairGame.key to: ideality;
		}
		return ideality;
	}
	map<list<string>,int> computeRawlsIdeality {
		// game : (list of: string)::(list of: int)
		// short version: ideality <- map(game.pairs collect (each.key::(min(each.value))));
		ideality <- map([]);
		loop pairGame over: game.pairs {
			list<int> val <- pairGame.value;
			add min(val) at: pairGame.key to: ideality;
		}
		return ideality;		
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
		// Give the money
		int payoff <- (list(game at s) at 0);
		money <- money + payoff;
		
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
	
	action displayIdeality {
		write 'The Ideality matrix of agent '+self+': ';
		write '   |    C    |    D    |';
		write '---|-------------------|';
		write ' C |    '+ideality at ["C","C"]+'    |    '+ideality at ["C","D"]+'    |';
		write '---|-------------------|';
		write ' D |    '+ideality at ["D","C"]+'    |    '+ideality at ["D","D"]+'    |';
		write '---|-------------------|';	
		write '';			
	}
	action displayGuilt {	
		write 'The Guilt matrix of agent '+self+': ';
		write '   |    C    |    D    |';
		write '---|-------------------|';
		write ' C |    '+guilt at ["C","C"]+'   |    '+guilt at ["C","D"]+'   |';
		write '---|-------------------|';
		write ' D |    '+guilt at ["D","C"]+'   |    '+guilt at ["D","D"]+'   |';
		write '---|-------------------|';	
		write '';			
	}	
	action displayUtilitySTAR {
		write 'The Utility with Guilt matrix of agent '+self+': ';
		write '   |    C    |    D    |';
		write '---|-------------------|';
		write ' C |    '+guiltDependentUtility at ["C","C"]+'   |    '+guiltDependentUtility at ["C","D"]+'   |';
		write '---|-------------------|';
		write ' D |    '+guiltDependentUtility at ["D","C"]+'   |    '+guiltDependentUtility at ["D","D"]+'   |';
		write '---|-------------------|';	
		write '';			
	}				
}
