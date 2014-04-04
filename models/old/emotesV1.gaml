/**
 *  emotesV1
 *  Author: bgaudou
 *  Description: 
 */

model emotesV1

global {
	int nbAgents;
	int moneyInit;
	float guiltAversionInit;
	
	// The game 
	// game is a map of (s::listPayoff), i.e. (list of: string)::(list of: int)
	map<list<string>,list> game;
	list<string> possibleActions <- ["C","D"];
	int coop;
	int defect;
	int betrayer;
	int betrayed;
	
	init {
		create people number: nbAgents {
			money <- moneyInit;
			guiltAversion <- guiltAversionInit;
		}
		set game <- [
			["C","C"]::[coop,coop],
			["C","D"]::[betrayed,betrayer],
			["D","C"]::[betrayer,betrayed],
			["D","D"]::[defect,defect]
		];
		
		do displayGame;
	}
	
	reflex play {
		// pairing
		list<people> rndLstAgent <- shuffle(people);
		loop i from: 0 to: (length(rndLstAgent)/2 - 1){
			people p1 <- (rndLstAgent at (2*i));
			people p2 <- (rndLstAgent at (2*i + 1));
			write "*****************************";
			write "" + p1 + " plays with " + p2;
			//let s type: list of: string <- [p1 play_with [p::p2],p2 play_with [p::p1]];			
			string s1 <- p1 play_with [p::p2];
			string s2 <- p2 play_with [p::p1];
			write "         " + p1 + " has played " + s1;		
			write "         " + p2 + " has played " + s2;				
			// do resolve_game ;
			ask p1 {
				do resolve_game p: p2 s: [s1,s2];
			}
			ask p2 {
				do resolve_game p: p1 s: [s2,s1];
			}			
		}
	}
	reflex evolve {
		// With contant population:
		//// - algo ge
		//// - evolution of the guilt aversion
		//// - when agent has money < 0, remove it ... possible ?
	}
	
	action displayGame {
		write 'The Prisoner dilemna game: ';
		write '   |    C    |    D    |';
		write '---|-------------------|';
		write ' C |  ('+coop+','+coop+')  |  ('+betrayed+','+betrayer+')  |';
		write '---|-------------------|';
		write ' D |  ('+betrayer+','+betrayed+')  |  ('+defect+','+defect+')  |';
		write '---|-------------------|';	
		write '';			
	}
}

environment {}

entities {
	species people {
		int money;
		float guiltAversion;
		// History of the interactions : map of agent::[nbCoop, totalInter]
		map<people,list> history;
		// ideality is a map of (s::idealValue), i.e. (list of: string)::(int)
		map<list<string>,int> ideality;
		// guilt is a map of (s::guiltValue), i.e. (list of: string)::(int)		
		map<list<string>,int> guilt;
		// guiltDependentUtility
		map<list<string>,int> guiltDependentUtility;
		
		init {
			// game : (list of: string)::(list of: int)
			// short version: ideality <- map(game.pairs collect (each.key::(sum(each.value))));
			ideality <- map([]);
			loop pairGame over: game.pairs {
				list<int> val <- pairGame.value;
				add sum(val) at: pairGame.key to: ideality;
			}
			do displayIdeality;
						
			// stratIdeal shape : [s1,s2]::IdValue
			loop stratIdeal over: ideality.pairs {
				int gValue <- stratIdeal.value;
				int max <- max(possibleActions collect (ideality at ([each,last(list(stratIdeal.key))])));
				add (gValue-max) at: stratIdeal.key to: guilt;
			}
			do displayGuilt;
			
			// Map utility : (s::utilityValue), i.e. (list of: string)::int
			map<list<string>,int> utility <- map(game.pairs collect (each.key::int(first(list(each.value)))));
			guiltDependentUtility <- map(game.keys collect (each::((utility at each) + guiltAversion*(guilt at each))));
			do displayUtilitySTAR;
		}
		
		action play_with {
			arg p type: people;
			
			string choice <- one_of(["C","D"]);
			list<int> eltOfHisto <- history at p;
			map<string,float> listProbaIbarre <- map([]);
			
			if(eltOfHisto = []){
				listProbaIbarre <- map(["C"::0.5, "D"::0.5]);
			} else {
				listProbaIbarre <- map(["C"::((eltOfHisto at 0) / (eltOfHisto at 1)),
										"D"::1-((eltOfHisto at 0) / (eltOfHisto at 1))]);
			}
			write 'History ' + history;
			write 'proba coop: ' + listProbaIbarre;
			
			// Expected utility
			map<string,float> expectedUtilities <- map([]);
			loop pchoice over: possibleActions {
				// write '****** '+ pchoice;
				float expectedUtility <- 0.0;
				loop jchoice over:listProbaIbarre.pairs {
					expectedUtility <- expectedUtility + float(jchoice.value) * float(guiltDependentUtility at [pchoice,jchoice.key]);
				}
				add expectedUtility at: pchoice to: expectedUtilities;
			}
			write 'expectedUtilities star    ' + expectedUtilities;
			
			if((expectedUtilities at "C") = (expectedUtilities at "D")){
				choice <- one_of(expectedUtilities.keys);
			}
			else {
				choice <- pair(expectedUtilities.values with_max_of each).key;
			}
			return choice;
		}
		
		
		action resolve_game {
			arg p type: people;
			arg s type: list;
			
			// Give the money
			int payoff <- (list(game at s) at 0);
			money <- money + payoff;
			// add in the history
			list<int> eltOfHisto <- history at p;
			int coopRes <- (s at 1) = "C" ? 1 : 0;
			if(eltOfHisto = []){
				add [coopRes,1] at:p to: history;
			} else {
				// let eltOfHisto type: list of: int <- history at p;
				add [(eltOfHisto at 0) + coopRes, (eltOfHisto at 1) + 1] at: p to: history;
//				list<int> listRes <- [coopRes,1];
//				loop i from: 0 to: length(eltOfHisto)-1 {
//					put ((eltOfHisto at i) + (listRes at i)) at: i in: eltOfHisto;
//				}
			}
			write ' ' + self + ' payoff ' + payoff;
			write '' + history;
		}
		
		action displayIdeality {
	//		write '   |    C    |    D    |';
	//		write '---|-------------------|';
	//		write ' C |  (3,3)  |  (0,5)  |';
	//		write '---|-------------------|';
	//		write ' D |  (5,0)  |  (1,1)  |';
	//		write '---|-------------------|';	
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
	//		write '   |    C    |    D    |';
	//		write '---|-------------------|';
	//		write ' C |  (3,3)  |  (0,5)  |';
	//		write '---|-------------------|';
	//		write ' D |  (5,0)  |  (1,1)  |';
	//		write '---|-------------------|';	
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
	//		write '   |    C    |    D    |';
	//		write '---|-------------------|';
	//		write ' C |  (3,3)  |  (0,5)  |';
	//		write '---|-------------------|';
	//		write ' D |  (5,0)  |  (1,1)  |';
	//		write '---|-------------------|';	
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
}

experiment emotesV1 type: gui {
	parameter 'Number of people' var: nbAgents <- 2 min: 1 max: 200 category:'Init Environment';
	parameter 'Money Init' var: moneyInit <- 100 min: 1 max: 200 category:'Init Environment';
	parameter 'Guilt Aversion Initial' var: guiltAversionInit <- 1.0 min: 0.0 max: 10.0 category:'Init Environment';
	
	parameter 'Both cooperate' var: coop <- 2 min: 0 max:10 category: 'Prisoner dilemna';
	parameter 'Betrayer' var: betrayer <- 3 min: 0 max:10 category: 'Prisoner dilemna';
	parameter 'Betrayed' var: betrayed <- 0 min: 0 max:10 category: 'Prisoner dilemna';
	parameter 'Both defect' var: defect <- 1 min: 0 max:10 category: 'Prisoner dilemna';
	
}
