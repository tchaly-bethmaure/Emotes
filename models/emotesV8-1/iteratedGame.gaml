/**
 *  emotesV8
 *  Author: bgaudou
 *  Modified by : cberthaume
 *  Description: agent as an iterated prisonner's dilemma instance with a specific configuration given at agent init().
 */
 
model iteratedgame

import "globals.gaml"
import "people.gaml"
import "peopleFictitiousPlay.gaml"
import "peoplePureStrategy.gaml"
import "main.gaml"

species iterated_game_instance {
	map<string, int> instance_configuration;
	list<people> peoples_in_instance;
	
	int R_instance;
	int P_instance;
	int T_instance;
	int S_instance;
		
	action init_manually(map configuration){		
		instance_configuration <- configuration;
		R_instance <- instance_configuration["R"];
		P_instance <- instance_configuration["P"];
		T_instance <- instance_configuration["T"]; 
		S_instance <- instance_configuration["S"];
		
		// Init of the game
		game <- [
			["C","C"]::[R_instance,R_instance],
			["C","D"]::[S_instance,T_instance],
			["D","C"]::[T_instance,S_instance],
			["D","D"]::[P_instance,P_instance]
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
					guiltAversion <- (i * guiltAversionStep) with_precision precision;
					idealMode <- idealComputation;
					do init();
				}
			}
		}
	
		// self can't read agent people created via agent of_generic_species people, so pass via a global var : peoples.
		peoples_in_instance <- peoples;

		do displayGame;
		do displayParameters;
	}
	
	reflex play {	
		// pairing
		list<people> rndLstAgent <- shuffle(peoples_in_instance);
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
			
			//if (count_debug >= 0){ write string("[ "+(peopleFictitiousPlay(p1).history at p2) at 3)+ "("+p1.guiltAversion +")" +", " + string((peopleFictitiousPlay(p2).history at p1) at 3) + "("+p2.guiltAversion +")" + " ]"; }	
		}
		sumPayoff <- sum((agents of_generic_species people) collect (each.sumPayoffs)); 

		// loop p over: (agents of_generic_species people) {
		//	write " people " + p + " sumPayoffs " + p.sumPayoffs;
		// }
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
		loop onePeople over: peoplePureStrategy {
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
		write 'The Prisoner dilemma game: ';
		write '   |    C    |    D    |';
		write '---|-------------------|';
		write ' C |  ('+R_instance+','+R_instance+')  |  ('+S_instance+','+T_instance+')  |';
		write '---|-------------------|';
		write ' D |  ('+T_instance+','+S_instance+')  |  ('+P_instance+','+P_instance+')  |';
		write '---|-------------------|';
		write '';
	}
	action displayParameters {
		write 'Ideality computation mode: ' + idealComputation;
		write 'Number of agents: ' + length(peoples_in_instance) + 
				", with GuiltAversion from " + (peoples_in_instance min_of (each.guiltAversion)) +
				" to " + (peoples_in_instance max_of (each.guiltAversion));
	}
}

