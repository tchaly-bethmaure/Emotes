/**
 *  peoplePureStrategyV8
 *  Author: cberthaume 
 *  Description: People implemented with pure strategy (used for the replicator dynamic):
 * 		- they have a pure strategy 
 * 		- they are characterized by their strategy and guiltAversion (si, gai)
 * 		- they also play depending on probability of oppenent strategy.
 */

model peoplePureStrategyV8

import "globals.gaml"
import "people.gaml"
import "peoplePureStrategy.gaml"

	species peopleEvolutiveFictitious parent: peoplePureStrategy {
		string strategy;
		
		// History of the interactions : map of agent::[nbCoop, totalInter, lastCoop, nbStepWithoutChange]
		map<people,list<float>> history;
		map<people,list<float>> historyRecent;
		
		string play_with (people p) {
			string choice <- one_of(possibleActions);
			// eltOfHisto : [nbCoop, totalInter, lastCoop, nbStepWithoutChange]
			list<float> eltOfHisto <- history at p;
			map<string,float> listProbaIbarre <- map([]);
			if(playWithDebug) {write 'eltOfHisto ' + eltOfHisto;}
			
			if(eltOfHisto = [] or eltOfHisto = [0, 0, 0, -1, 0]){
				listProbaIbarre <- map(["C"::0.5, "D"::0.5]);
			} else {
				listProbaIbarre <- map(["C"::((eltOfHisto at 0) / (eltOfHisto at 1)),
										"D"::1-((eltOfHisto at 0) / (eltOfHisto at 1))]);
			}
			if(playWithDebug) {write 'listProbaIbarre ' + listProbaIbarre;}
			
			// Expected utility
			map<string,float> expectedUtilities <- map([]);
			// Possible action <- C or D
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
			if(dice <= floor(probaMutation)){
				strategy <- newStrategy;
				// guilt ?
				// ideal ?
			}			
		}
	}
