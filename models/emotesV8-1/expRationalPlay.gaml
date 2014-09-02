/**
 *  expRationalPlay
 *  Author: cberthaume
 *  Description: peopleRation are playing a rational game without history learning
 */

model expRationalPlay

import "main.gaml"
import "iteratedGame.gaml"
import "globals.gaml"
import "people.gaml"
import "peopleRationalPlay.gaml"

/*display my_display {
    event [event_type] action: myAction
}*/

global {
	action view_agent_info {
		map values <- user_input(["Agent to expose ?"::1]);
		int index <- int(values at "Agent to expose ?");
		people ppl <- peoples[index];
		ask ppl{
			do displayUtilitySTAR;
		}
	}
	
	/* Used to map which game are playing each actor.
	 * action do_mapping{
		list<int> agent_index <- [];
		// We map with a frame of agent, the frame of agent is bounded with 4 corner agent :
		loop i from:0 to: 41{ add(i) to:agent_index; }
		// loop i from:0 to: 1{ add(int(user_input([string(i) :: 1]) at string(i))) to:agent_index; }
		iterated_game_instance game <- one_of (agents of_generic_species(iterated_game_instance));
		do compute_environemet_information(agent_index, game.peoples_in_instance, game.instance_configuration);
		write "================================== Done.";
	}
	
	action compute_environemet_information(list<int> agent_index, list<people> few_peoples, map<string, int> conf){
		people tmp_ppl <- nil;
		string game_played <- "";
		list<map<string, int>> values_of_ppl <- [];
		list<string> order_of_game_ppl <- [];
		map<string, container> people_data <- [];
		/*
		 * container contains at first a string
		 * 					  at second a map<string, int>		 
		 * (1): map<string, int>: char(T,R,P or S)::value of  the local game,
		 * (2): string: order of the game played localy,
		*\/
		// Loop over each input_agent		
		loop i over:agent_index {			
			tmp_ppl <- few_peoples[i];

			if(tmp_ppl != nil){
				// we are interested in having the "local" game values that this agent plays with	
				float local_T <- float(tmp_ppl.guiltDependentUtility at ["D","C"]);
				float local_R <- float(tmp_ppl.guiltDependentUtility at["C","C"]);
				float local_P <- float(tmp_ppl.guiltDependentUtility at ["D","D"]);
				float local_S <- float(tmp_ppl.guiltDependentUtility at ["C","D"]);

				map<int, string> mapTRPS <- [0::"T", 1::"R", 2::"P", 3::"S"];
				list<float> new_order <- []; // <string : game letter (T, R, P or S), int : value of the n element of the new order>
				list<string> new_order_char <- [];
				
				// now we look if the agent plays a game other than PD
				if(!(local_T > local_R and local_R > local_P and local_P > local_S) or !(2*local_R > local_T + local_S)){
					list<float> localValues <- [];
					add(local_T) to:localValues;add(local_R) to:localValues;add(local_P) to:localValues;add(local_S) to:localValues;
					float max_value <- -99999;
					
					// determine the new order of the game
					loop j from:0 to:length(localValues)-1 {
						max_value <- -99999;
						loop localValue over:localValues {
							if(max_value <= localValue and (new_order count(each = localValue) < localValues count(each = localValue))){
								max_value <- localValue;
							}
							else {
								// write new_order contains(localValue); write string(max_value)+ "<=" +string(localValue);
							}
						}
						add(max_value) to:new_order;
						add(mapTRPS[localValues index_of(max_value)]) to:new_order_char;
					}
					string order_char_memo <- "";
					map<string, float> values_memo <- [];
					loop index from: 0 to:length(localValues) - 1{
						// ex : R(8)>T(2)>S(1)>P(0)
						order_char_memo <- order_char_memo + string(new_order_char[index]) + " ";
						add(new_order_char[index]::new_order[index]) to:values_memo;
					}
					add(order_char_memo) to: order_of_game_ppl;

					add(tmp_ppl, [order_char_memo, values_memo]) to:people_data;
					write "[" + string(tmp_ppl) + ": (" + order_char_memo+", "+ values_memo+")]";
					// write string(tmp_ppl) + ": " + "[" + order_char_memo +", "+ values_memo+"]";
				}else{ write string(tmp_ppl) + " is playing PD : " + tmp_ppl.guiltDependentUtility; }
			}
		}
	}*/
}

experiment expRationalPlay type: gui {
	//user_command frame_us action: do_mapping;
	user_command get_agent_info action: view_agent_info;
	
	parameter 'Max Guilt Aversion Initial' var: guiltAversionInitMax <- 4.1 min: -1000.0 max: 1000.0 category:'Init Environment';
	parameter 'Min Guilt Aversion Initial' var: guiltAversionInitMin <- 0.0 min: -1000.0 max: 1000.0 category:'Init Environment';
	parameter 'Discretization of the guilt aversion' var: guiltAversionStep <- 0.1 min: 0.01 max: 1.0 category:'Init Environment';
	parameter 'Number of agents per gA' var: nbAgentsPerGA <- 1 min: 1 max: 100 category: 'Init Environment';
	
	parameter 'Agents use pure strategy' var: peopleStrategy <- 'Rational' among: ['Rational','Pure','Fictious play'] category: 'Simulation mode';
	parameter 'Evolution mode' var: evolutionMode <- 'None' among: ['None','Replicator dynamic'] category: 'Simulation mode';
	parameter 'Ideal computation' var: idealComputation <- "Harsanyi" among: ["Rawls","Harsanyi","mixRawlsHarsanyi"] category: 'Simulation mode';
	
	parameter 'Reward (R)' var: R <- 4 min: 0 max:20 category: 'Prisoner dilemna';
	parameter 'Temptation (T)' var: T <- 6 min: 0 max:20 category: 'Prisoner dilemna';
	parameter 'Sucker (S)' var: S <- 0 min: 0 max:20 category: 'Prisoner dilemna';
	parameter 'Punishment (P)' var: P <- 1 min: 0 max:20 category: 'Prisoner dilemna';
	
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
				loop i from: 0 to: length(peopleRationalPlay)-1 {
					draw string(peopleRationalPlay(i).guiltAversion) at:{i*5, -5} color:rgb('black');
					draw string(peopleRationalPlay(i).guiltAversion) at:{-5, 5*i} color:rgb('black');
					loop j from: 0 to: length(peopleRationalPlay)-1 {
						int lastMoveIwJ <- -1;
						int lastMoveJwI <- -1;
						ask peopleRationalPlay(j) {
							lastMoveIwJ <- (self.lastMove_with_people at peopleRationalPlay(i));
						}
						ask peopleRationalPlay(i) {
							lastMoveJwI <- (self.lastMove_with_people at peopleRationalPlay(j));
						}
						draw square(5) at:{i*5,j*5}
							color: (lastMoveIwJ = 0 and lastMoveJwI = 0) ? rgb('red') :
											((lastMoveIwJ = 1 and lastMoveJwI = 1)? rgb('green'):
											((lastMoveIwJ = 1 and lastMoveJwI = 0)? rgb('yellow'):
											((lastMoveIwJ = 0 and lastMoveJwI = 1)? rgb('blue'):rgb('black'))));
							// flip(0.5)?rgb('red'):rgb('green');
					}
				}
			}
		}
		
		display Detailed type: opengl{
			graphics 'G' {
				loop i from: 0 to: length(peopleRationalPlay)-1 {
					draw string(peopleRationalPlay(i).guiltAversion) at:{i*5, -5} color:rgb('black');
					draw string(peopleRationalPlay(i).guiltAversion) at:{-5, 5*i} color:rgb('black');
					loop j from: 0 to: length(peopleRationalPlay)-1 {
						int lastMoveIwJ <- -1;
						int lastMoveJwI <- -1;
						ask peopleRationalPlay(j) {
							lastMoveIwJ <- (self.lastMove_with_people at peopleRationalPlay(i));
						}
						ask peopleRationalPlay(i) {
							lastMoveJwI <- (self.lastMove_with_people at peopleRationalPlay(j));
						}
						
						// Each pattern should have boundaries that define : above or below those boundaries, all agents situated there defect (or cooperate).
						list<float> boundaries <- one_of (agents of_generic_species(iterated_game_instance)).get_pattern_boundaries();			
						if(boundaries contains peopleRationalPlay(j).guiltAversion or boundaries contains peopleRationalPlay(i).guiltAversion){
							draw square(5) at:{i*5,j*5}
								color: rgb('white');
						}
						else{
							draw square(5) at:{ i*5, j*5 }
								color: (lastMoveIwJ = 0 and lastMoveJwI = 0) ? rgb('red') :
												((lastMoveIwJ = 1 and lastMoveJwI = 1)? rgb('green'):
												((lastMoveIwJ = 1 and lastMoveJwI = 0)? rgb('yellow'):
												((lastMoveIwJ = 0 and lastMoveJwI = 1)? rgb('blue'):rgb('black'))));
								// flip(0.5)?rgb('red'):rgb('green');
						}
					}					
				}
			}
		}		
	}
}

