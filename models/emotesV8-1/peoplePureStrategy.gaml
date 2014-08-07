/**
 *  peoplePureStrategyV8
 *  Author: bgaudou 
 *  Description: People implemented with pure strategy (used for the replicator dynamic):
 * 		- they have a pure strategy 
 * 		- they are characterized by their strategy and guiltAversion (si, gai)
 */

model peoplePureStrategyV8

import "globals.gaml"
import "people.gaml"

	species peoplePureStrategy parent: people {
		string strategy;
		
		string play_with (people p) {
			return strategy;
		}
		
		action resolve_game (people p, list<string> s) {
			// s : [s_1,s_2]  (s_i strategy played by agent i, 1 is the current agent)
			float payoff <- 0;
			if(payoffEmo) {
				payoff <- ((guiltDependentUtility at s));			
			} else {
				payoff <- (game at s) at 0;
			}
			stepPayoff <- payoff;
			sumPayoffs <- sumPayoffs + payoff;
		}
		
		action replicate(string newStrategy){
			/* input list<peoplePureStrategy> lp
			 * // The size of the neighborhood is as big as the nb of agents in the system
			list<peoplePureStrategy> most_successful_players <- (lp with_min_of(each.sumPayoffs));
			peoplePureStrategy p <- one_of(most_successful_players);
			
			int dice <- rnd(100);
			if(dice <= floor(probaMutation)){				
				strategy <- p.strategy;
				guiltAversion <- p.guiltAversion;
				if(self.idealMode != p.idealMode){ self.idealMode <- p.idealMode; do computeIdeality(); }				
				return true;
			}
			return false;*/
			
			int dice <- rnd(100);
			if(dice <= floor(probaEvolution)){
				// Noise = mutation
				if(bNoise and rnd(100) <= stratNoise){strategy <- rnd(1)=0?"D":"C";} // Strategy mutation
				else{ strategy <- newStrategy; }	
				// guilt ?
				// ideal ?
			}			
		}
	}
