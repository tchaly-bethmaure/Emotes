/**
 *  emotesV5
 *  Author: bgaudou
 *  Description: 
 */

model emotesV4

import "peopleV5.gaml"

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
		
		fileName <- "../../results/" + "res" + length(people)+"_"+idealComputation+"_" + cycleToSave+"_"+"R"+R+"P"+P+"T"+T+"S"+S+ '.csv';
		fileNameObs <- "../../results/" + "stableRes" + length(people)+"_"+idealComputation+"_" +cycleObs+"-"+cycleToSave+"_"+"R"+R+"P"+P+"T"+T+"S"+S + '.csv';
		fileNamePayoff <- "../../results/" + "payoff" + length(people)+"_"+idealComputation+"_" + cycleToSave+'.csv';

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


experiment emotesV5 type: gui {
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
		display Behav type: opengl{
			graphics 'G' {
				loop i from: 0 to: length(people)-1 {
					loop j from: 0 to: length(people)-1 {
						int lastMoveIwJ <- 0; // "D"
						int lastMoveJwI <- 0; // "D"
						ask people(j) {
							// history at i :  [nbCoop, totalInter, utilityGained, lastCoop, nbStepWithoutChange]
							lastMoveIwJ <- (self.history at people(i)) at 3;
						}										
						ask people(i) {
							lastMoveJwI <- (self.history at people(j)) at 3;
						}							
						draw square(5) at:{i*5,j*5} 
							color: (lastMoveIwJ = 0 and lastMoveJwI = 0) ? rgb('red') : 
									((lastMoveIwJ = 1 and lastMoveJwI = 1)? rgb('green') : rgb('black'));
							// flip(0.5)?rgb('red'):rgb('green');
					}  
				}
			}
		}	
		display StableBehav type: opengl{
			graphics 'G' {
				loop i from: 0 to: length(people)-1 {
					loop j from: 0 to: length(people)-1 {
						int lastMoveIwJ <- 0; // "D"
						int nbStepChangeIwJ <- 0;
						int lastMoveJwI <- 0; // "D"
						int nbStepChangeJwI <- 0;
						
						ask people(j) {
							// history at i :  [nbCoop, totalInter, utilityGained, lastCoop, nbStepWithoutChange]
							lastMoveIwJ <- (self.history at people(i)) at 3;
							nbStepChangeIwJ <- (self.history at people(i)) at 4;
						}										
						ask people(i) {
							lastMoveJwI <- (self.history at people(j)) at 3;
							nbStepChangeJwI <- (self.history at people(j)) at 4;		
						}							
						draw square(5) at:{i*5,j*5} 
							color: (lastMoveIwJ = 0 and lastMoveJwI = 0 and nbStepChangeIwJ > 10 and nbStepChangeJwI >10) ? rgb('red') : 
									((lastMoveIwJ = 1 and lastMoveJwI = 1 and nbStepChangeIwJ > 10 and nbStepChangeJwI >10)? rgb('green') : rgb('black'));
							// flip(0.5)?rgb('red'):rgb('green');
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