/**
 *  expMain
 *  Author: bgaudou
 *  Description: 
 */

model expPureStratV8

import "main.gaml"
import "globals.gaml"
import "people.gaml"
import "peoplePureStrategy.gaml"

experiment expPureStratV8 type: gui {
	parameter 'Guilt Aversion Initial' 					var: guiltAversionInitMax <- 4.1 min: 0.0 max: 1000.0 category:'Init Environment';
	parameter 'Min Guilt Aversion Initial' 				var: guiltAversionInitMin <- 0.0 min: 0.0 max: 1000.0 category:'Init Environment';
	parameter 'Discretization of the guilt aversion' 	var: guiltAversionStep <- 0.1 min: 0.01 max: 1.0 category:'Init Environment';
	parameter 'Number of agents per gA' 				var: nbAgentsPerGA <- 1 min: 1 max: 100 category: 'Init Environment';
	
	parameter 'Agents use pure strategy' 	var: peopleStrategy <- 'Pure' among: ['Pure','Fictious play'] category: 'Simulation mode';
	parameter 'Evolution mode' 				var: evolutionMode <- 'Replicator dynamic' among: ['None','Replicator dynamic'] category: 'Simulation mode';
	parameter 'Ideal computation' 			var: idealComputation <- "Rawls" among: ["Rawls","Harsanyi","mixRawlsHarsanyi"] category: 'Simulation mode';

	parameter 'Reward (R)' 		var: R <- 2 min: 0 max:10 category: 'Prisoner dilemna';
	parameter 'Temptation (T)' 	var: T <- 4 min: 0 max:10 category: 'Prisoner dilemna';	
	parameter 'Sucker (S)' 		var: S <- 0 min: 0 max:10 category: 'Prisoner dilemna';
	parameter 'Punishment (P)' 	var: P <- 1 min: 0 max:10 category: 'Prisoner dilemna';
	
	parameter 'Frequence of evolution' 	var: stepEvol <- 10 min: 1 max: 100 category: 'Replicator dynamic';
	parameter 'Nb Agents will evolve' 	var: nbAgentsEvol <- 5 min: 1 max: 100 category: 'Replicator dynamic';
	parameter 'Emotional payoffs' 		var: payoffEmo <- true category: 'Replicator dynamic';
	parameter 'Mutation Probability' 	var: probaMutation <- 0.0 category: 'Replicator dynamic';
	
	parameter 'Display debug Game construction' 	var: debugGame <- false category: 'debug';
	parameter 'Display debug of play' 				var: playWithDebug <- false category: 'debug';	
	parameter 'Display debug of game resolution' 	var: resolveGameDebug <- false category: 'debug';

	parameter 'Agent To display' 				var: numAgentToDisplay <- -1 category: 'debug';
	parameter 'Agent with whom it interacts' 	var: otherAgentToDisplay <- -1 category: 'debug';
	
	parameter 'Step to save' 				var: cycleToSave <- 3000 min: 0 max: 2000000 category:'Analysis';
	parameter 'Step from which to observe' 	var: cycleObs <- 2000 category: 'Analysis';
	
	output{ 
		display guiltAversion {
			chart name: 'guiltAversion repartition' type: histogram background: rgb('lightGray')  {
				loop i from: int(guiltAversionInitMin/guiltAversionStep) to: int(guiltAversionInitMax/guiltAversionStep with_precision precision) step: 1 {
					float gA <- (i * guiltAversionStep) with_precision precision;
					data string((i * guiltAversionStep) with_precision precision) value: peoplePureStrategy count (each.guiltAversion = gA);
				}
			}
		}
		display gA_repartition {
			chart 'gA for D' type: histogram background : rgb('lightGray') position: {0,0} size:{1,0.5} {
				loop i from: int(guiltAversionInitMin/guiltAversionStep) to: int(guiltAversionInitMax/guiltAversionStep with_precision precision) step: 1 {
					float gA <- (i * guiltAversionStep) with_precision precision;
					data string(gA) value: peoplePureStrategy count ((each.guiltAversion = gA) and (each.strategy = "D"));
				}
			}
			chart 'gA for C' type: histogram background : rgb('lightGray') position: {0,0.5} size:{1,0.5} {
				loop i from: int(guiltAversionInitMin/guiltAversionStep) to: int(guiltAversionInitMax/guiltAversionStep with_precision precision) step: 1 {
					float gA <- (i * guiltAversionStep) with_precision precision;
					data string(gA) value: peoplePureStrategy count ((each.guiltAversion = gA) and (each.strategy = "C"));
				}
			}			
		}
		display strategy {
			chart name: 'strategy repartition' type: histogram background: rgb('lightGray')  {
				data name: "C" value: peoplePureStrategy count (each.strategy = "C");
				data name: "D" value: peoplePureStrategy count (each.strategy = "D");
			} 
		}
		display repart {
			chart name: 'repartitions' type: series background: rgb('lightGray')  {
				data name: "avg gA" value: mean(peoplePureStrategy collect (each.guiltAversion));
				data name: "avg gA C" value: mean((peoplePureStrategy where (each.strategy = "C")) collect (each.guiltAversion)) color: rgb('green');
				data name: "avg gA D" value: mean((peoplePureStrategy where (each.strategy = "D")) collect (each.guiltAversion)) color: rgb('red');				
			}
		}
		display payoff {
			chart "payoff" type: series background: rgb('lightGray')  {
				data name: "mean payoff" value: ((cycle mod stepEvol) != 0) ? sumPayoff / (((cycle) mod stepEvol + 2)) : 0.0;
			}
		}
		display sum_payoff {
			chart "sum_payoff" type: series background: rgb('lightGray')  {
				data name: "sum payoff" value: sumPayoff ;
			}
		}		
	}
}

