/**
 *  peopleV5
 *  Author: bgaudou 
 *  Description: 
 */
model peopleV8

import "globals.gaml"

// People implemented for the replicator dynamic:
// - they have a pure strategy 
// - they are characterized by their strategy and guiltAversion (si, gai)


species people {
	float sumPayoffs;
	float guiltAversion;
	
	string idealMode;	
	
	// ideality is a map of (s::idealValue), i.e. (list of: string)::(int)
	map<list<string>,int> ideality;
	// guilt is a map of (s::guiltValue), i.e. (list of: string)::(int)		
	map<list<string>,int> guilt;
	// guiltDependentUtility
	map<list<string>,int> guiltDependentUtility;
	
	init{ }
	
	// Resolve the bug of those value affectation
	action init{
		
		// A l'initialisation chaque agent calcul son indice d'idéalité.
		// Ideality computation
		if(idealMode = "Rawls"){
			ideality <- self computeRawlsIdeality();
		} else {
			if(idealMode = "Harsanyi"){
				ideality <- self computeHarsanyiIdeality();
			}
			//else{ write "/!\\ Error : no ideality given."; }
		}
		if(debugGame){do displayIdeality;}
		
		// stratIdeal shape : [s1,s2]::IdValue
		loop stratIdeal over: ideality.pairs {
			int gValue <- stratIdeal.value; // game value
			int max <- max(possibleActions collect (ideality at ([each,last(list(stratIdeal.key))])));
			add (gValue-max) at: stratIdeal.key to: guilt;
		}
		if(debugGame){ do displayGuilt; }
		
		// Map utility : (s::utilityValue), i.e. (list of: string)::int
		map<list<string>,int> utility <- map(game.pairs collect (each.key::int(first(each.value))));
		guiltDependentUtility <- map(game.keys collect (each::((utility at each) + guiltAversion*(guilt at each))));
		if(debugGame){do displayUtilitySTAR;}
	}

	map<list<string>,int> computeHarsanyiIdeality {
		// game : (list of: string)::(list of: int)
		// short version: ideality <- map(game.pairs collect (each.key::(sum(each.value))));
		map<list<string>,int> ideality_temp <- map([]);
		
		loop pairGame over: game.pairs {
			list<int> val <- pairGame.value;			
			add sum(val) at: pairGame.key to: ideality_temp;
		}
		return ideality_temp;
	}
	map<list<string>,int> computeRawlsIdeality {
		// game : (list of: string)::(list of: int)
		// short version: ideality <- map(game.pairs collect (each.key::(min(each.value))));
		map<list<string>,int> ideality_temp <- map([]);

		loop pairGame over: game.pairs {
			list<int> val <- pairGame.value;
			add min(val) at: pairGame.key to: ideality_temp;
		}
		return ideality_temp;	
	}
	
	string play_with (people p) {return "";}
		
	action resolve_game (people p, list<string> s) {}
	
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