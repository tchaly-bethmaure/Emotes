/**
 *  emotesV7
 *  Author: bgaudou
 *  Description: 
 */

model emotesV7

import "globals.gaml" 
import "people.gaml"
import "peoplePureStrategy.gaml"
import "peopleFictitiousPlay.gaml"

import "expPureStrat.gaml"
import "expFictitiousPlay.gaml"
import "expBatch.gaml"


global {
	// Initialization
	int nbAgentsPerGA;
	float guiltAversionInitMax <- 2.0;
	float guiltAversionInitMin <- 0.0;
	float guiltAversionStep <- 0.1;
	int precision;
	
	// Mode of the simulation
	string peopleStrategy <- 'Pure';      	// ['Pure','Fictious play']
	string evolutionMode <- 'None';			// ['None','Replicator dynamic']
	string idealComputation <- 'Rawls';		// ["Rawls","Harsanyi","mixRawlsHarsanyi"]

	// Debug global variables	
	int numAgentToDisplay <- -1;
	int otherAgentToDisplay <- -1;
		 
	// The game values	 
	int R;
	int P;
	int T; 
	int S;		 
	
	float sumPayoff <- 0.0; 
		 
	init { 
		// Init of the game
		game <- [
			["C","C"]::[R,R],
			["C","D"]::[S,T],
			["D","C"]::[T,S],
			["D","D"]::[P,P]
		];		
		
		bool trouve <- false;
		precision <- 0;
		loop while: (!trouve){
			if(int(guiltAversionStep * (10 ^ precision)) > 0) {
				trouve <- true;
			} else {
				precision <- precision + 1;
			}
		} 
		
		// Creation of agents
		if(peopleStrategy = 'Pure') {
			loop i from: int(guiltAversionInitMin/guiltAversionStep) to: int(guiltAversionInitMax/guiltAversionStep) step: 1 {
				create peoplePureStrategy number: nbAgentsPerGA {
					sumPayoffs <- 0.0;
					strategy <- "C";
					guiltAversion <- i * guiltAversionStep ;
					guiltAversion <- guiltAversion with_precision precision;
					idealMode <- idealComputation;
				}
				create peoplePureStrategy number: nbAgentsPerGA {
					sumPayoffs <- 0.0;
					strategy <- "D";
					guiltAversion <- i * guiltAversionStep ;
					guiltAversion <- guiltAversion with_precision precision;
					idealMode <- idealComputation;					
				}
			} 			
		} 
		if(peopleStrategy = 'Fictious play'){
			loop i from: int(guiltAversionInitMin/guiltAversionStep) to: int((guiltAversionInitMax/guiltAversionStep) with_precision precision) step: 1 {
				create peopleFictitiousPlay number: nbAgentsPerGA {
					sumPayoffs <- 0.0;
					guiltAversion <- i * guiltAversionStep ;
					guiltAversion <- guiltAversion with_precision precision;
					idealMode <- idealComputation;					
				}
			} 				
		}
				
		do displayGame;
		do displayParameters;
	}
	
	reflex play {
		// pairing
		list<people> rndLstAgent <- shuffle(agents of_generic_species people);
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
		sumPayoff <- sum(people collect (each.sumPayoffs)); 
		// write "cycle " + cycle + " payOff " + sumPayoff + " cycle modulo  " + ((cycle) mod stepEvol + 2);
		// write "" + sumPayoff / (((cycle) mod stepEvol + 2));
	}
	
	reflex evolve when: ((evolutionMode = 'Replicator dynamic') and (cycle mod stepEvol = 0)) {
		// Replicator dynamic v0
		list<peoplePureStrategy> lstToEvolve <- (2*nbAgentsEvol) among (shuffle(peoplePureStrategy));
		loop i from: 0 to: (length(lstToEvolve)/2 - 1){
			peoplePureStrategy p1 <- (lstToEvolve at (2*i));
			peoplePureStrategy p2 <- (lstToEvolve at (2*i + 1));
			
			if(p1.sumPayoffs > p2.sumPayoffs){
				p2.strategy <- p1.strategy;
				p2.guiltAversion <- p1.guiltAversion;
			} else {
				if(p1.sumPayoffs < p2.sumPayoffs){
					p1.strategy <- p2.strategy;
					p1.guiltAversion <- p2.guiltAversion;
				} // if money are equals, do not change anything
			}
		}
		loop onePeople over: people {
			onePeople.sumPayoffs <- 0.0;
		}
	}
	
	reflex mutation when: ((evolutionMode = 'Replicator dynamic') and (flip(probaMutation))) {
		ask one_of(peoplePureStrategy) {
			guiltAversion <- rnd((guiltAversionInitMax - guiltAversionInitMin)/guiltAversionStep)*guiltAversionStep + guiltAversionInitMin;
			guiltAversion <- guiltAversion with_precision precision;
			
			// strategy <- one_of(["C","D"]);
			write "Mutation of " + self + " gA " + guiltAversion; // + " strategy " + strategy;
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
		write 'Ideality computation mode: ' + idealComputation;
		list<people> list_of_people <- (agents of_generic_species people);
		write 'Number of agents: ' + length(list_of_people) + 
				", with GuiltAversion from " + (list_of_people min_of (each.guiltAversion)) +
				" to " + (list_of_people max_of (each.guiltAversion));
	}
}





