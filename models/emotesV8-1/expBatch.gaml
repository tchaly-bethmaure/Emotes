/**
 *  expBatch
 *  Author: bgaudou
 *  Description: 
 */

model expBatchV8 

import "main.gaml"
import "globals.gaml"
import "people.gaml"

experiment emotesV8Batch repeat: 2 type: batch until: (cycle = cycleToSave) {		
	parameter 'Guilt Aversion Initial' var: guiltAversionInitMax min: 0.1 max: 4.1 step: 0.1 ;
	parameter 'Min Guilt Aversion Initial' var: guiltAversionInitMin <- 0.0 ;
	parameter 'Discretization of the guilt aversion' var: guiltAversionStep <- 0.1 ;
	parameter 'Number of agents per gA' var: nbAgentsPerGA <- 5 ;

	parameter 'Reward (R)' var: R <- 2;
	parameter 'Temptation (T)' var: T <- 3 ;	
	parameter 'Sucker (S)' var: S <- 0 ;
	parameter 'Punishment (P)' var: P <- 1 ;
	
	parameter 'Frequence of evolution' var: stepEvol <- 10 ;
	parameter 'Nb Agents will evolve' var: nbAgentsEvol <- 5 ;
	parameter 'Emotional payoffs' var: payoffEmo <- true ;
	parameter 'Mutation Probability' var: probaMutation <- 0.0 ;
	
	parameter 'Display debug Game construction' var: debugGame <- false ;
	parameter 'Display debug of play' var: playWithDebug <- false ;	
	parameter 'Display debug of game resolution' var: resolveGameDebug <- false ;

	parameter 'Agent To display' var: numAgentToDisplay <- -1 ;
	parameter 'Agent with whom it interacts' var: otherAgentToDisplay <- -1 ;

	parameter 'Ideal computation' var: idealComputation <- "Rawls"; // among: ["Rawls","Harsanyi"] ;
	
	parameter 'Step to save' var: cycleToSave <- 3000 ;
	parameter 'Step from which to observe' var: cycleObs <- 2000 ;
	
	method exhaustive maximize: sumPayoff;
	
//	reflex saveRes when: (cycle = cycleToSave) {		
//		list<float> rowLine <- [R,S,T,P];
//
//		ask world {
//			add float(self computeSymptotPoint []) to: rowLine;
//			add float(self computeEquilibriumPoint []) to: rowLine;
//		}
//		save rowLine type: csv to: fileName;		
//	}
}


