/**
 *  expMain
 *  Author: bgaudou
 *  Description: 
 */

model expFictitiousPlayV8

import "main.gaml"
import "globals.gaml"
import "people.gaml"
import "peopleFictitiousPlay.gaml"

experiment expFictitiousPlayV8 type: gui {
	
	parameter 'Max Guilt Aversion Initial' var: guiltAversionInitMax <- 4.1 min: 0.0 max: 1000.0 category:'Init Environment';
	parameter 'Min Guilt Aversion Initial' var: guiltAversionInitMin <- 0.0 min: 0.0 max: 1000.0 category:'Init Environment';
	parameter 'Discretization of the guilt aversion' var: guiltAversionStep <- 0.1 min: 0.01 max: 1.0 category:'Init Environment';
	parameter 'Number of agents per gA' var: nbAgentsPerGA <- 1 min: 1 max: 100 category: 'Init Environment';
	
	parameter 'Agents use pure strategy' var: peopleStrategy <- 'Fictious play' among: ['Pure','Fictious play'] category: 'Simulation mode';
	parameter 'Evolution mode' var: evolutionMode <- 'None' among: ['None','Replicator dynamic'] category: 'Simulation mode';
	parameter 'Ideal computation' var: idealComputation <- "Rawls" among: ["Rawls","Harsanyi","mixRawlsHarsanyi"] category: 'Simulation mode';

	parameter 'Reward (R)' var: R <- 2 min: 0 max:10 category: 'Prisoner dilemna';
	parameter 'Temptation (T)' var: T <- 3 min: 0 max:10 category: 'Prisoner dilemna';	
	parameter 'Sucker (S)' var: S <- 0 min: 0 max:10 category: 'Prisoner dilemna';
	parameter 'Punishment (P)' var: P <- 1 min: 0 max:10 category: 'Prisoner dilemna';
	
	parameter 'Emotional payoffs' var: payoffEmo <- true category: 'Replicator dynamic';
	
	parameter 'Display debug Game construction' var: debugGame <- false category: 'debug';
	parameter 'Display debug of play' var: playWithDebug <- false category: 'debug';	
	parameter 'Display debug of game resolution' var: resolveGameDebug <- false category: 'debug';

	parameter 'Agent To display' var: numAgentToDisplay <- -1 category: 'debug';
	parameter 'Agent with whom it interacts' var: otherAgentToDisplay <- -1 category: 'debug';
	
	parameter 'Step to save' var: cycleToSave <- 3000 min: 0 max: 2000000 category:'Analysis';
	parameter 'Step from which to observe' var: cycleObs <- 2000 category: 'Analysis';	
	
	output{ 					
		display Behav type: opengl{
			graphics 'G' {
				loop i from: 0 to: length(peopleFictitiousPlay)-1 {
					loop j from: 0 to: length(peopleFictitiousPlay)-1 {
						int lastMoveIwJ <- 0; // "D"
						int lastMoveJwI <- 0; // "D"
						ask peopleFictitiousPlay(j) {
							// history at i :  [nbCoop, totalInter, utilityGained, lastCoop, nbStepWithoutChange]
							lastMoveIwJ <- (self.history at peopleFictitiousPlay(i)) at 3;
						}										
						ask peopleFictitiousPlay(i) {
							lastMoveJwI <- (self.history at peopleFictitiousPlay(j)) at 3;
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
				loop i from: 0 to: length(peopleFictitiousPlay)-1 {
					loop j from: 0 to: length(peopleFictitiousPlay)-1 {
						int lastMoveIwJ <- 0; // "D"
						int nbStepChangeIwJ <- 0;
						int lastMoveJwI <- 0; // "D"
						int nbStepChangeJwI <- 0;
						
						ask peopleFictitiousPlay(j) {
							// history at i :  [nbCoop, totalInter, utilityGained, lastCoop, nbStepWithoutChange]
							lastMoveIwJ <- (self.history at peopleFictitiousPlay(i)) at 3;
							nbStepChangeIwJ <- (self.history at peopleFictitiousPlay(i)) at 4;
						}										
						ask peopleFictitiousPlay(i) {
							lastMoveJwI <- (self.history at peopleFictitiousPlay(j)) at 3;
							nbStepChangeJwI <- (self.history at peopleFictitiousPlay(j)) at 4;		
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

