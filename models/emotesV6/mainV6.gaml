/**
 *  emotesV6
 *  Author: bgaudou
 *  Description: 
 */

model emotesV6

import "peopleV6.gaml"

global {
	//int nbAgents;
	float guiltAversionInitMax;
	float guiltAversionInitMin;
	float guiltAversionStep;
	int precision;
	
	// Debug global variables	
	bool debugGame <- false;
	bool resolveGameDebug <- false;
	bool playWithDebug <- false;
	int numAgentToDisplay <- -1;
	int otherAgentToDisplay <- -1;

	// Agents behavior global variables
	string idealComputation;
	
	// Replicator dynamic parameters
	int stepEvol;
	int nbAgentsEvol;
	bool payoffEmo;
	
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
	
	float sumPayoff <- 0.0; 
	 
	init { 
		bool trouve <- false;
		precision <- 0;
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
				money <- 0.0;
				strategy <- "C";
				guiltAversion <- i * guiltAversionStep ;
				guiltAversion <- guiltAversion with_precision precision;
			}
			create people number: 1 {
				money <- 0.0;
				strategy <- "D";
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
		sumPayoff <- sum(people collect (each.money)); 
		write "cycle " + cycle + " payOff " + sumPayoff + " cycle modulo  " + ((cycle) mod stepEvol + 2);
		write "" + sumPayoff / (((cycle) mod stepEvol + 2));
	}
	
	reflex evolve when: (cycle mod stepEvol = 0) {
		// Replicator dynamic v0
		list<people> lstToEvolve <- (2*nbAgentsEvol) among (shuffle(people));
		loop i from: 0 to: (length(lstToEvolve)/2 - 1){
			people p1 <- (lstToEvolve at (2*i));
			people p2 <- (lstToEvolve at (2*i + 1));
			
			if(p1.money > p2.money){
				p2.strategy <- p1.strategy;
				p2.guiltAversion <- p1.guiltAversion;
			} else {
				if(p1.money < p2.money){
					p1.strategy <- p2.strategy;
					p1.guiltAversion <- p2.guiltAversion;
				} // if money are equals, do not change anything
			}
		}
		loop onePeople over: people {
			onePeople.money <- 0.0;
		}
	}
	
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
	}
}


experiment emotesV6 type: gui {
	parameter 'Guilt Aversion Initial' var: guiltAversionInitMax <- 4.1 min: 0.0 max: 1000.0 category:'Init Environment';
	parameter 'Min Guilt Aversion Initial' var: guiltAversionInitMin <- 0.0 min: 0.0 max: 1000.0 category:'Init Environment';
	parameter 'Discretization of the guilt aversion' var: guiltAversionStep <- 0.1 min: 0.01 max: 1.0 category:'Init Environment';
	
	parameter 'Reward (R)' var: R <- 2 min: 0 max:10 category: 'Prisoner dilemna';
	parameter 'Temptation (T)' var: T <- 3 min: 0 max:10 category: 'Prisoner dilemna';
	parameter 'Sucker (S)' var: S <- 0 min: 0 max:10 category: 'Prisoner dilemna';
	parameter 'Punishment (P)' var: P <- 1 min: 0 max:10 category: 'Prisoner dilemna';
	
	parameter 'Frequence of evolution' var: stepEvol <- 10 min: 1 max: 100 category: 'Replicator dynamic';
	parameter 'Nb Agents will evolve' var: nbAgentsEvol <- 5 min: 1 max: 100 category: 'Replicator dynamic';
	parameter 'Emotional payoffs' var: payoffEmo <- true category: 'Replicator dynamic';
	
	parameter 'Display debug Game construction' var: debugGame <- false category: 'debug';
	parameter 'Display debug of play' var: playWithDebug <- false category: 'debug';	
	parameter 'Display debug of game resolution' var: resolveGameDebug <- false category: 'debug';

	parameter 'Agent To display' var: numAgentToDisplay <- -1 category: 'debug';
	parameter 'Agent with whom it interacts' var: otherAgentToDisplay <- -1 category: 'debug';

	parameter 'Ideal computation' var: idealComputation <- "Rawls" among: ["Rawls","Harsanyi"] category: 'Agents';
	
	parameter 'Step to save' var: cycleToSave <- 3000 min: 0 max: 2000000 category:'Analysis';
	parameter 'Step from which to observe' var: cycleObs <- 2000 category: 'Analysis';
	
	output{ 
		display guiltAversion {
			chart name: 'guiltAversion repartition' type: histogram background: rgb('lightGray')  {
				loop i from: int(guiltAversionInitMin/guiltAversionStep) to: int(guiltAversionInitMax/guiltAversionStep) step: 1 {
					float gA <- (i * guiltAversionStep) with_precision precision;
					// write "" + gA;
					data string((i * guiltAversionStep) with_precision precision) value: people count (each.guiltAversion = gA);
					// write "" + people count (each.guiltAversion = gA);
				}
			} 
		}	
		display strategy {
			chart name: 'strategy repartition' type: histogram background: rgb('lightGray')  {
				data name: "C" value: people count (each.strategy = "C");
				data name: "D" value: people count (each.strategy = "D");
			} 
		}	
		display repart {
			chart name: 'repartitions' type: series background: rgb('lightGray')  {
				data name: "avg gA" value: mean(people collect (each.guiltAversion));
				data name: "avg gA C" value: mean((people where (each.strategy = "C")) collect (each.guiltAversion)) color: rgb('green');
				data name: "avg gA D" value: mean((people where (each.strategy = "D")) collect (each.guiltAversion)) color: rgb('red');				
			}
		}
		display payoff {
			chart "payoff" type: series background: rgb('lightGray')  {
				data name: "mean payoff" value: ((cycle mod stepEvol) != 0) ? sumPayoff / (((cycle) mod stepEvol + 2)) : 0.0;
			}
		}
	}
}

