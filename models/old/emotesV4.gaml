/**
 *  emotesV4
 *  Author: bgaudou
 *  Description: 
 */

model emotesV4

global {
	//int nbAgents;
	float guiltAversionInitMax;
	float guiltAversionInitMin;
	float guiltAversionStep;

	// Debug global variables	
	bool debugGame <- false;
	bool resolveGameDebug <- false;
	bool playWithDebug <- false;
	int numAgentToDisplay <- -1;
	int otherAgentToDisplay <- -1;

	// Agents behavior global variables
	string idealComputation;
	
	// Analysis parameters 
	bool batchMode <- false;
	int cycleToSave;
	int cycleObs;	
	string fileName;
	string fileNameObs;	
	string fileNamePayoff;
		
	// The game 
	// game is a map of (s::listPayoff), i.e. (list of: string)::(list of: int)
	map<list<string>,list> game;
	list<string> possibleActions <- ["C","D"];
	int R;
	int P;
	int T;
	int S;
	
	init {
		int precision <- 0;
		bool trouve <- false;
		loop while: (!trouve){
			if(int(guiltAversionStep * (10 ^ precision)) > 0) {
				trouve <- true;
			} else {
				precision <- precision + 1;
			}
		} 
		write 'precision ' + precision ;
		loop i from: int(guiltAversionInitMin/guiltAversionStep) to: int(guiltAversionInitMax/guiltAversionStep) step: 1 {
			create people number: 1 {
				money <- 0;
				guiltAversion <- i * guiltAversionStep ;
				guiltAversion <- guiltAversion with_precision precision;
			}
		} 
		
		game <- [
			["C","C"]::[R,R],
			["C","D"]::[S,T],
			["D","C"]::[T,S],
			["D","D"]::[P,P]
		];
		
		fileName <- "../results/" + "res" + length(people)+"_"+idealComputation+"_" + cycleToSave+"_"+"R"+R+"P"+P+"T"+T+"S"+S+ '.csv';
		fileNameObs <- "../results" + "stableRes" + length(people)+"_"+idealComputation+"_" +cycleObs+"-"+cycleToSave+"_"+"R"+R+"P"+P+"T"+T+"S"+S + '.csv';
		fileNamePayoff <- "../results/" + "payoff" + length(people)+"_"+idealComputation+"_" + cycleToSave+'.csv';

		do displayGame;
		do displayParameters;
	}
	
	reflex play {
		// pairing
		list<people> rndLstAgent <- shuffle(people);
		loop i from: 0 to: (length(rndLstAgent)/2 - 1){
			people p1 <- (rndLstAgent at (2*i));
			people p2 <- (rndLstAgent at (2*i + 1));

			string s1 <- p1 play_with [p::p2];
			string s2 <- p2 play_with [p::p1];
			
			if(p1.guiltAversion*10 = numAgentToDisplay) and (p2.guiltAversion*10 = otherAgentToDisplay) {
				write ' ' + [s1,s2];
			}
						
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

	reflex saveGame when: (cycle = cycleToSave) and (!batchMode){
		save ([""]+(people collect (each.guiltAversion))) type: "csv" to: fileName rewrite: true; 
		loop peopleAgt over: people {
			list<float> rowLine <- [peopleAgt.guiltAversion];
			loop agt over: people {
				// history : map of agent::[nbCoop, totalInter, utilityGained]
				list<int> cellEltHistory <- list(peopleAgt.history at agt);
				if(cellEltHistory = []){
					add 0 to: rowLine;
				} else {		
					add (cellEltHistory at 2 / cellEltHistory at 1) to: rowLine;
				}
			}
			save rowLine type: csv to: fileName;
		}
		write 'End of the simulation';
		do halt;
	}

	reflex saveGameRecent when: (cycle = cycleToSave) and (!batchMode){
		save ([""]+(people collect (each.guiltAversion))) type: "csv" to: fileNameObs rewrite: true; 
		loop peopleAgt over: people {
			list<float> rowLine <- [peopleAgt.guiltAversion];
			loop agt over: people {
				// history : map of agent::[nbCoop, totalInter, utilityGained]
				list<int> cellEltHistory <- list(peopleAgt.historyRecent at agt);
				if(cellEltHistory = []){
					add 0 to: rowLine;
				} else {		
					add (cellEltHistory at 2 / cellEltHistory at 1) to: rowLine;
				}
			}
			save rowLine type: csv to: fileNameObs;
		}
		write 'End of the simulation';
		do halt;
	}
		
	reflex displayAgents when: (numAgentToDisplay != -1) and (!batchMode){
		write ' ' + numAgentToDisplay + ' ' + otherAgentToDisplay;
		people p1 <- first(people where (each.guiltAversion = (numAgentToDisplay/10)));
		write 'p1 ' + p1;
		people p2 <-first(people where (each.guiltAversion = (otherAgentToDisplay/10)));
		write 'p2 ' + p2;
		ask p1 {
			write '' + self + '  ' + self.history at p2;
		}
		
		ask p2 {
			write '' + self + '  ' + self.history at p1;
		}
	}

//	reflex computeSymptotPoint when: (cycle = cycleToSave) and (!batchMode){
//		bool trouve <- false;
//		float guiltAversCount <- 0;
//		people pMax <- first(people where (each.guiltAversion = guiltAversionInitMax));
//		loop while: (trouve = false) and (guiltAversCount < guiltAversionInitMax){
//			guiltAversCount <- guiltAversCount + 0.1;
//			people pAbove <- first(people where (each.guiltAversion = guiltAversCount - 0.1));
//			people pBelow <- first(people where (each.guiltAversion = guiltAversCount));
//			list<int> cellEltHistoryAbove <- list(pAbove.historyRecent at pMax);
//			list<int> cellEltHistoryBelow <- list(pBelow.historyRecent at pMax);
//			if(cellEltHistoryAbove != []) and (cellEltHistoryBelow != []){
//				if(cellEltHistoryAbove at 2 / cellEltHistoryAbove at 1 = P) and (cellEltHistoryBelow at 2 / cellEltHistoryBelow at 1 != P){
//					trouve <- true;
//				}
//			}
//		}
//	   	if(trouve) {write 'TROUVE Asymptot  ' + guiltAversCount;}
//	}
	
	action computeSymptotPoint {
		bool trouve <- false;
		float guiltAversCount <- 0.0;
		people pMax <- first(people where (each.guiltAversion = guiltAversionInitMax));
		loop while: (trouve = false) and (guiltAversCount < guiltAversionInitMax){
			guiltAversCount <- guiltAversCount + 0.1;
			people pAbove <- first(people where (each.guiltAversion = guiltAversCount - 0.1));
			people pBelow <- first(people where (each.guiltAversion = guiltAversCount));
			list<int> cellEltHistoryAbove <- list(pAbove.historyRecent at pMax);
			list<int> cellEltHistoryBelow <- list(pBelow.historyRecent at pMax);
			if(cellEltHistoryAbove != []) and (cellEltHistoryBelow != []){
				if(cellEltHistoryAbove at 2 / cellEltHistoryAbove at 1 = P) and (cellEltHistoryBelow at 2 / cellEltHistoryBelow at 1 != P){
					trouve <- true;
				}
			}
		}
	   	// if(trouve) {write 'TROUVE Asymptot  ' + guiltAversCount;}
	   	return trouve ? guiltAversCount : 0;
	}	
	
//	reflex computeEquilibriumPoint when: (cycle = cycleToSave) and (!batchMode){
//		bool trouve <- false;
//		float guiltAversCount <- 0;
//		loop while: (trouve = false) and (guiltAversCount < guiltAversionInitMax){
//			guiltAversCount <- guiltAversCount + 0.1;
//			people pCentral <- first(people where (each.guiltAversion = guiltAversCount));
//			people pCentralLeft <- first(people where (each.guiltAversion = guiltAversCount - 0.1));	
//			people pCentralRight <- first(people where (each.guiltAversion = guiltAversCount + 0.1));	
//			list<int> cellEltHistoryLeft <- list(pCentral.historyRecent at pCentralLeft);
//			list<int> cellEltHistoryRight <- list(pCentral.historyRecent at pCentralRight);
//
//			if(cellEltHistoryLeft != []) and (cellEltHistoryRight != []){
//				if(cellEltHistoryLeft at 2 / cellEltHistoryLeft at 1 = P) and (cellEltHistoryRight at 2 / cellEltHistoryRight at 1 != P){
//					trouve <- true;
//				}
//			}
//		}
//	   	if(trouve){
//	   		write 'TROUVE Equilibrium   ' + guiltAversCount;
//	   	}
//	}
	
	action computeEquilibriumPoint {
		bool trouve <- false;
		float guiltAversCount <- 0.0;
		loop while: (trouve = false) and (guiltAversCount < guiltAversionInitMax){
			guiltAversCount <- guiltAversCount + 0.1;
			people pCentral <- first(people where (each.guiltAversion = guiltAversCount));
			people pCentralLeft <- first(people where (each.guiltAversion = guiltAversCount - 0.1));	
			people pCentralRight <- first(people where (each.guiltAversion = guiltAversCount + 0.1));	
			list<int> cellEltHistoryLeft <- list(pCentral.historyRecent at pCentralLeft);
			list<int> cellEltHistoryRight <- list(pCentral.historyRecent at pCentralRight);

			if(cellEltHistoryLeft != []) and (cellEltHistoryRight != []){
				if(cellEltHistoryLeft at 2 / cellEltHistoryLeft at 1 = P) and (cellEltHistoryRight at 2 / cellEltHistoryRight at 1 != P){
					trouve <- true;
				}
			}
		}
//	   	if(trouve){
//	   		write 'TROUVE Equilibrium   ' + guiltAversCount;
//	   	}
		return trouve ? guiltAversCount : 0.0;
	}
	
//	reflex savePayoff when: (cycle = cycleToSave) and (batchMode){
//		
//		save rowLine type: csv to: fileName;
//		
//		
//		save ([""]+(people collect (each.guiltAversion))) type: "csv" to: fileName rewrite: false; 
//		loop peopleAgt over: people {
//			list<float> rowLine <- [peopleAgt.guiltAversion];
//			loop agt over: people {
//				// history : map of agent::[nbCoop, totalInter, utilityGained]
//				list<int> cellEltHistory <- list(peopleAgt.history at agt);
//				if(cellEltHistory = []){
//					add 0 to: rowLine;
//				} else {		
//					add (cellEltHistory at 2 / cellEltHistory at 1) to: rowLine;
//				}
//			}
//			save rowLine type: csv to: fileName;
//		}
//		write 'End of the simulation';
//		do halt;
//	}
	
	
	action displayGame {
		write 'The Prisoner dilemna game: ';
		write '   |    C    |    D    |';
		write '---|-------------------|';
		write ' C |  ('+R+','+R+')  |  ('+S+','+T+')  |';
		write '---|-------------------|';
		write ' D |  ('+T+','+S+')  |  ('+P+','+P+')  |';
		write '---|-------------------|';	
		write '';			
	}
	action displayParameters {
		write 'Ideality compuation mode: ' + idealComputation;
		write 'Number of agents: ' + length(people) + 
				", with GuiltAversion from " + (people min_of (each.guiltAversion)) +
				" to " + (people max_of (each.guiltAversion));
		write 'Files where data will be saved: '; 
		write ' '+ fileName;
		write ' '+ fileNameObs;
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
		map<people,list> historyRecent;
		
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
			// Give the money
			int payoff <- (list(game at s) at 0);
			money <- money + payoff;
			
			// add in the history
			// eltOfHisto is a list : [nbCoop, totalInter, utilityGained]
			list<int> eltOfHisto <- history at p;
			int coopRes <- (s at 1) = "C" ? 1 : 0;
			
			if(eltOfHisto = []){
				add [coopRes,1,payoff] at:p to: history;
			} else {
				add [(eltOfHisto at 0) + coopRes, 
					 (eltOfHisto at 1) + 1,
					 (eltOfHisto at 2) + payoff] at: p to: history;
			}
			if(cycleObs < cycle){
				list<int> eltOfHistoObs <- historyRecent at p;

				if(eltOfHistoObs = []){
					add [coopRes,1,payoff] at: p to: historyRecent;
				} else {
					add [(eltOfHistoObs at 0) + coopRes, 
					     (eltOfHistoObs at 1) + 1,
					     (eltOfHistoObs at 2) + payoff] at: p to: history;
					let listRes type: list <- [coopRes,1,payoff];
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
}

experiment emotesV4 type: gui {
	parameter 'Guilt Aversion Initial' var: guiltAversionInitMax <- 4.1 min: 0.0 max: 1000.0 category:'Init Environment';
	parameter 'Min Guilt Aversion Initial' var: guiltAversionInitMin <- 0.0 min: 0.0 max: 1000.0 category:'Init Environment';
	parameter 'Discretization of the guilt aversion' var: guiltAversionStep <- 0.1 min: 0.01 max: 1.0 category:'Init Environment';
	
	parameter 'Reward (R)' var: R <- 2 min: 0 max:10 category: 'Prisoner dilemna';
	parameter 'Temptation (T)' var: T <- 3 min: 0 max:10 category: 'Prisoner dilemna';
	parameter 'Sucker (S)' var: S <- 0 min: 0 max:10 category: 'Prisoner dilemna';
	parameter 'Punishment (P)' var: P <- 1 min: 0 max:10 category: 'Prisoner dilemna';
	
	parameter 'Display debug Game construction' var: debugGame <- false category: 'debug';
	parameter 'Display debug of play' var: playWithDebug <- false category: 'debug';	
	parameter 'Display debug of game resolution' var: resolveGameDebug <- false category: 'debug';

	parameter 'Agent To display' var: numAgentToDisplay <- -1 category: 'debug';
	parameter 'Agent with whom it interacts' var: otherAgentToDisplay <- -1 category: 'debug';

	parameter 'Ideal computation' var: idealComputation <- "Rawls" among: ["Rawls","Harsanyi"] category: 'Agents';
	
	parameter 'Step to save' var: cycleToSave <- 3000 min: 0 max: 2000000 category:'Analysis';
	parameter 'Step from which to observe' var: cycleObs <- 2000 category: 'Analysis';
	
	output{
		display Display type: opengl{
			graphics 'G' {
				loop i from: 0 to: length(people)-1 {
					// write 'expe i ' + i;
					loop j from: 0 to: length(people)-1 {
						draw square(5) at:{i*5,j*5} color: flip(0.5)?rgb('red'):rgb('green');
					}  
				}
			}
		}	
	}
}

experiment emotesV5Batch repeat: 1 type: batch until: (cycle = cycleToSave) {
	parameter 'Max Guilt Aversion Initial' var: guiltAversionInitMax <- 4.1;
	parameter 'Min Guilt Aversion Initial' var: guiltAversionInitMin <- 0.0;
	parameter 'Discretization of the guilt aversion' var: guiltAversionStep <- 0.1;
	
	parameter 'Sucker (S)' 		var: S <- 0 min: 0 max:10 step:1 ;
	parameter 'Punishment (P)' 	var: P <- 1 min: 0 max:10 step:1 ;	
	parameter 'Reward (R)' 		var: R <- 2 min: 0 max:10 step:1 ;
	parameter 'Temptation (T)' 	var: T <- 3 min: 0 max:10 step:1 ;
	
	parameter 'Ideal computation' var: idealComputation <- "Rawls" ;
	
	parameter 'Batch Mode' var: batchMode <- true;
	parameter 'Step to save' var: cycleToSave <- 10000;
	parameter 'Step from which to observe' var: cycleObs <- 2000 ;
	
	reflex savePayoff when: (cycle = cycleToSave) {		
		list<float> rowLine <- [R,S,T,P];
		ask world {
			add float(self computeSymptotPoint []) to: rowLine;
			add float(self computeEquilibriumPoint []) to: rowLine;
		}
		save rowLine type: csv to: fileNamePayoff;
	}
}