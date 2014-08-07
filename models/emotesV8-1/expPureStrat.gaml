/**
 *  expMain
 *  Author: bgaudou
 *  Description: 
 */

model expPureStratV8

import "main.gaml"
import "iteratedGame.gaml"
import "globals.gaml"
import "people.gaml"
import "peoplePureStrategy.gaml"

global{
	float sumPO <- 0.0;
	
	reflex computeSumPayoff{
		sumPO <- sum(agents of_generic_species(peoplePureStrategy) collect(each.sumPayoffs));
	}
	
	action view_agent_info {
		map values <- user_input(["Agent to expose ?"::1]);
		int index <- int(values at "Agent to expose ?");
		people ppl <- peoples[index];
		ask ppl{
			do displayUtilitySTAR;
			write "Ideal : "+ idealMode;
			write "gA : "+ guiltAversion;
			write "SumPayOffs : "+sumPayoffs;
		}
	}
}

experiment expPureStratV8 type: gui {
	user_command get_agent_info action: view_agent_info;
	
	parameter 'Agents distribution law'				var: guiltLaw <- 'Unifrom' among: ['Unifrom','Normal'] category: 'Distribution';
	parameter 'Guilt Aversion Mean'					var: guiltAversionMean <- 2.88 min: -9999.0 max: 9999.0 category:'Distribution';
	parameter 'Guilt Aversion Dispersion'			var: guiltDispersion <- 0.495 min: 0.0 max: 1000.0 category:'Distribution';
	parameter 'Number of agents'					var: nbOfAgtOfSample <- 82 min: 1 max: 1000 category:'Distribution';
	
	parameter 'Guilt Aversion Initial' 					var: guiltAversionInitMax <- 4.1 min: 0.0 max: 1000.0 category:'Init Environment';
	parameter 'Min Guilt Aversion Initial' 				var: guiltAversionInitMin <- 0.0 min: 0.0 max: 1000.0 category:'Init Environment';
	parameter 'Discretization of the guilt aversion' 	var: guiltAversionStep <- 0.1 min: 0.01 max: 1.0 category:'Init Environment';
	parameter 'Number of agents per gA' 				var: nbAgentsPerGA <- 1 min: 1 max: 100 category: 'Init Environment';
		
	parameter 'Agents\' strategy' 	var: peopleStrategy <- 'Pure' among: ['Pure','Fictious play'] category: 'Simulation mode';
	parameter 'Evolution mode' 				var: evolutionMode <- 'Replicator dynamic' among: ['None','Replicator dynamic'] category: 'Simulation mode';
	parameter 'Ideal computation' 			var: idealComputation <- "Random" among: ["Rawls","Harsanyi","Random"] category: 'Simulation mode';

	parameter 'Reward (R)' 		var: R <- 5 min: 0 max:20 category: 'Prisoner dilemna';
	parameter 'Temptation (T)' 	var: T <- 6 min: 0 max:20 category: 'Prisoner dilemna';	
	parameter 'Sucker (S)' 		var: S <- 0 min: 0 max:20 category: 'Prisoner dilemna';
	parameter 'Punishment (P)' 	var: P <- 1 min: 0 max:20 category: 'Prisoner dilemna';
	
	parameter 'Frequence of evolution' 	var: stepEvol <- 10 min: 1 max: 100 category: 'Replicator dynamic';
	parameter 'Nb Agents will evolve' 	var: nbAgentsEvol <- 5 min: 1 max: 100 category: 'Replicator dynamic';
	parameter 'Emotional payoffs' 		var: payoffEmo <- true category: 'Replicator dynamic';
	parameter 'Replication Probability' var: probaEvolution <- 30.0 category: 'Replicator dynamic';
	//parameter 'Mutation Probability' 	var: probaMutation <- 30.0 category: 'Replicator dynamic';
	
	parameter 'Make some noise' var:bNoise <- false category:'Noise';
	parameter 'Ideality switch' var:idealityNoise <- 30 min: 0 max : 100 category:'Noise';
	parameter 'Guilt noise' var:guiltNoise <- 30 min: 0 max : 100 category:'Noise';
	parameter 'Strategy noise' var:stratNoise <- 30 min: 0 max : 100 category:'Noise';
	parameter 'Rational noise' var:rationalNoise <- 30 min: 0 max : 100 category:'Noise';
	
	parameter 'Display debug Game construction' 	var: debugGame <- false category: 'debug';
	parameter 'Display debug of play' 				var: playWithDebug <- false category: 'debug';	
	parameter 'Display debug of game resolution' 	var: resolveGameDebug <- false category: 'debug';

	parameter 'Agent To display' 				var: numAgentToDisplay <- -1 category: 'debug';
	parameter 'Agent with whom it interacts' 	var: otherAgentToDisplay <- -1 category: 'debug';
	
	parameter 'Step to save' 				var: cycleToSave <- 3000 min: 0 max: 2000000 category:'Analysis';
	parameter 'Step from which to observe' 	var: cycleObs <- 2000 category: 'Analysis';
	
	output{
		display guiltAversion {
			chart name: 'guiltAversion repartition' type: histogram background: rgb('lightGray') size:{0.5, 0.5} position:{0, 0}  {
				loop i from: int(guiltAversionInitMin/guiltAversionStep) to: int(guiltAversionInitMax/guiltAversionStep with_precision precision) step: 1 {
					float gA <- (i * guiltAversionStep) with_precision 1;
					data string((i * guiltAversionStep) with_precision 1) value: peoplePureStrategy count (each.guiltAversion = gA);
				}
			}
			
			chart 'gA for D' type: histogram background : rgb('lightGray') size:{0.5, 0.5} position:{0.5, 0.5} {
				loop i from: int(guiltAversionInitMin/guiltAversionStep) to: int(guiltAversionInitMax/guiltAversionStep with_precision precision) step: 1 {
					float gA <- (i * guiltAversionStep) with_precision 1;
					data string(gA) value: peoplePureStrategy count ((each.guiltAversion = gA) and (each.strategy = "D")) color:rgb("red");
				}
			}
			
			chart 'gA for C' type: histogram background : rgb('lightGray') size:{0.5, 0.5} position:{0.5, 0} {
				loop i from: int(guiltAversionInitMin/guiltAversionStep) to: int(guiltAversionInitMax/guiltAversionStep with_precision precision) step: 1 {
					float gA <- (i * guiltAversionStep) with_precision 1;
					data string(gA) value: peoplePureStrategy count ((each.guiltAversion = gA) and (each.strategy = "C")) color:rgb("green");
				}
			}
			
			chart name: 'mean gA' type: series background: rgb('lightGray') size:{0.5, 0.5} position:{0, 0.5}{
				data name: "avg gA" value: mean(peoplePureStrategy collect (each.guiltAversion));
				data name: "avg gA C" value: mean((peoplePureStrategy where (each.strategy = "C")) collect (each.guiltAversion)) color: rgb('green');
				data name: "avg gA D" value: mean((peoplePureStrategy where (each.strategy = "D")) collect (each.guiltAversion)) color: rgb('red');				
			}
		}
		
		display strategy {
			chart name: 'strategy repartition' type: pie background: rgb('lightGray') size:{0.5, 0.5} position:{0,0} {
				data name: "C" value: peoplePureStrategy count (each.strategy = "C") color:rgb('green');
				data name: "D" value: peoplePureStrategy count (each.strategy = "D") color:rgb('red');
			}
			
			chart name: 'strategy repartition history' type: series background: rgb('lightGray') size:{0.5, 0.5} position:{0.5,0} {
				data name: "C" value: peoplePureStrategy count (each.strategy = "C") color:rgb("green");
				data name: "D" value: peoplePureStrategy count (each.strategy = "D") color:rgb("red");
			} 
		}

		display payoffs {
			chart "payoffs" type: series background: rgb('lightGray') size:{0.5, 0.5} position:{0,0}{
				data name: "mean payoff" value: mean(peoplePureStrategy collect(each.sumPayoffs));
				data name: "min payoffs" value: agents of_generic_species(people) min_of (each.sumPayoffs) color:rgb(228,107,33);
				data name: "max payoffs" value: agents of_generic_species(people) max_of (each.sumPayoffs) color:rgb(203,54,206);
			}
			chart "sum_payoffs" type: series background: rgb('lightGray') size:{0.5, 0.5} position:{0.5,0} {
				data name: "sum payoff" value: sumPO;
			}
			chart "payoffs repartition" type: histogram background: rgb('lightGray') size:{0.5, 0.5} position:{0,0.5} {
				loop i from: int(guiltAversionInitMin/guiltAversionStep) to: int(guiltAversionInitMax/guiltAversionStep with_precision precision)*2 step: 1 {
					// float gA <- (i * guiltAversionStep) with_precision 1; inutile
					data string(i) value: peoplePureStrategy(i).sumPayoffs;
				}
			}
		}
		
		display payoff_by_step {
			chart "payoff of step" type: series background: rgb('lightGray') size:{0.5, 0.5} position:{0,0}{
				data name: "mean payoff" value: mean(peoplePureStrategy collect(each.stepPayoff));
				data name: "min payoff" value: agents of_generic_species(people) min_of (each.stepPayoff) color:rgb(228,107,33);
				data name: "max payoff" value: agents of_generic_species(people) max_of (each.stepPayoff) color:rgb(203,54,206);
			}
			chart "sum payoff of step" type: series background: rgb('lightGray') size:{0.5, 0.5} position:{0.5,0} {
				data name: "sum payoff" value: sum(peoplePureStrategy collect(each.stepPayoff));
			}
			chart "payoff gained per agent in this step" type: histogram background: rgb('lightGray') size:{0.5, 0.5} position:{0,0.5} {
				loop i from: int(guiltAversionInitMin/guiltAversionStep) to: int(guiltAversionInitMax/guiltAversionStep with_precision precision)*2 step: 1 {
					// float gA <- (i * guiltAversionStep) with_precision 1;
					data string(i) value: peoplePureStrategy(i).stepPayoff;
				}
			}
		}
		
		display ideal_repart {
			chart "ideal repartition" type: pie background: rgb('lightGray') size:{0.5, 0.5} position:{0,0} {
				data name: "Rawls" value: peoplePureStrategy count (each.idealMode = "Rawls");
				data name: "Harsanyi" value: peoplePureStrategy count (each.idealMode = "Harsanyi");
			}
			
			chart "ideal repartition history" type: series background: rgb('lightGray') size:{0.5, 0.5} position:{0.5,0} {
				data name: "Rawls" value: peoplePureStrategy count (each.idealMode = "Rawls");
				data name: "Harsanyi" value: peoplePureStrategy count (each.idealMode = "Harsanyi");
			}
		}
		
		display Space type: opengl{
			graphics 'G' {
				int j <- 0;
				int facteur <- 20;
				loop i from: 0 to: length(peoplePureStrategy)-1 {
						draw square(facteur) at:{(i mod 9)*facteur,j*facteur}
							color: (peoplePureStrategy(i).strategy = "D") ? rgb('red') : rgb('green');
						if(i mod 9 = 0 and i > 0){ j <- j + 1; }
						draw "# "+string(i) at:{(i mod 9)*facteur,j*facteur} color:rgb('black') style:bold;
						draw string(peoplePureStrategy(i).guiltAversion) at:{((i mod 9)*facteur),j*facteur - 2} color:rgb('black') style:bold;	
						draw string(int(peoplePureStrategy(i).sumPayoffs)) at:{((i mod 9)*facteur),j*facteur - 4} color:rgb('black') style:bold;				
				}
			}
		}
	}
}

