/**
 *  emotesV8
 *  Author: cberthaume
 *  Description: experience which take a file (.csv) containing PD configuration formalized as
 *  it : "T R P S; T R P S; T R P S;" (with (T)raitor (R)eward, etc.). For exemple : "4 3 2 1; 5 3 2 0;"
 *  could be the content of such .csv file. 
 * 	Those configuration are loaded in a list and executed sequentialy by creating instance of iterated PD's game.
 */
 
model sequentialGame

/* TODO : 
 * - Graph proportion : gain / agent.
 */

import "main.gaml"
import "globals.gaml"
import "people.gaml"
import "peopleFictitiousPlay.gaml"
import "configFileHandler.gaml"
import "iteratedGame.gaml"

global {
	// Sequential testing
	bool sequential_game_testing;
	list<string> valid_configuration;
	list<string> rejected_configuration;
	bool batch_display_only;
	int game_concidered_stable_at_cycle <- 600;
	
	// Game configuration vars
	int game_configuration_index;
	int nb_of_configuration;
	int cycle_to_sub <- 0;
	
	// Statistics vars1
	int defect_count <- 1;
    int coop_count <- 0;
    int chaos_count <- 0;
    int traitor_count <- 0;
    int sucker_count <- 0;	
    int nb_of_stable_state <- 1; // only stable ones
    int nb_of_unstable_state <- 1; // unstable
    map<string,int> state_history <- ["stable"::0, "unstable"::0, "cycle_count"::0];
    int stable_change_max_cycle_elapsed <- 100;
    
    // Generated configuration file vars 
   	string file_path;
   	string file_name;
   	string file_extension;
    
	init{
		valid_configuration <- read_file_containing_config(file_name,file_path) ;  // Initial configuration
		rejected_configuration <- [];
		// if(sequential_game_testing = true){do find_matching_DP_config();}
		if(game_configuration_index != 0){ do reset_game(); }
	}
	
	reflex 	begin_an_other_game {
		do statistics_computation();
		bool is_game_stable <- self compute_game_stability();		
		// If the experiment sequential game testing is on, we chain instances of iterated DP game
		if (is_game_stable = true and sequential_game_testing = true) {
			nb_of_configuration <- length(valid_configuration);
			do snap_shot();
			if(game_configuration_index < nb_of_configuration + 1){
				// We save the results : coop vs defect
				do save_statistic();
				do reset_game();
			}
			else { write "Simulation is over."; do halt; }
		}
	}
	
	action save_statistic{				
		string file_name <- "config_related_save/PrisonnerDilemma_Stats";
		string data <- "D::" + string(defect_count) + ";C::" + string(coop_count)+";Config::"+valid_configuration at game_configuration_index+";";
		save data type: "csv" to: file_name;
	}
	
	// Compute statistics of the game (actually yet, it only count)
	action statistics_computation{
		if (length(peoples) > 1) {
			defect_count <- 0;
	        coop_count <- 0;
	        chaos_count <- 0;
	        traitor_count <- 0;
	        sucker_count <- 0;	        
	        state_history["stable"] <- nb_of_stable_state;
			state_history["unstable"] <- nb_of_unstable_state;
	        nb_of_stable_state <- 0; // stable
	        nb_of_unstable_state <- 0; // stabe + unstable	        
			
	        loop p1 over:peoples{
				loop p2 over:peoples{
					//peopleFictitiousPlay p1 <- peopleFictitiousPlay(i);
					//peopleFictitiousPlay p2 <- peopleFictitiousPlay(j);
					
					if (p1.guiltAversion != p2.guiltAversion){
						int move_p1 <- (peopleFictitiousPlay(p1).history at p2) at 3;							
						int move_p2 <- (peopleFictitiousPlay(p2).history at p1) at 3;
						if(move_p1 = 1 and move_p2 = 1) { coop_count <- coop_count + 1; }
						if(move_p1 = 0 and move_p2 = 0){ defect_count <- defect_count + 1; }
						if(move_p1 = 1 and move_p2 = 0){ sucker_count <- sucker_count + 1; }
						if(move_p1 = 0 and move_p2 = 1){ traitor_count <- traitor_count + 1; }					
						
						if ((move_p1 = 1 and move_p2 = 1) or (move_p1 = 0 and move_p2 = 0)) {							
							nb_of_stable_state <- nb_of_stable_state + 1;							
						}						
						else{							
							nb_of_unstable_state <- nb_of_unstable_state + 1;							
						}
					}
				}
			}			
		}
	}
	
	// We look if any agent changed his state, if not : the game is stable.
	action compute_game_stability{
		// There are many configuration, each configuraiton i take ti cycle, sum(ti) is cycle_count
		int instance_cycle <- cycle - cycle_to_sub ; // and instance_cycle is ti - cycle_to_sub 
		int grid_agent <- ((length(peoples)^2) - length(peoples));
		int borne_inf <- 1;
		bool stable <- false;
		
		if(idealComputation = "Rawls"){
			// Just a reset of history cycle if stable state and unstable ones number change
			if((state_history["stable"] != nb_of_stable_state) or (state_history["unstable"] != nb_of_unstable_state)){
				state_history["cycle_count"] <- 0;
			}
						
			if((((state_history["stable"] = nb_of_stable_state) and (state_history["unstable"] = nb_of_unstable_state))
			 or
			 nb_of_stable_state = grid_agent) and instance_cycle > borne_inf){
				// Needed for non-Rawls guilt type game
				if(state_history["cycle_count"] > stable_change_max_cycle_elapsed){
					state_history["cycle_count"] <- 0;
					write "==================== GAME STABLE ====================";
					stable <- true;
				}
				else{ 
					state_history["cycle_count"] <- state_history["cycle_count"] + 1;
				}
			}
		}
		else{
			if(idealComputation = "Harsanyi" and instance_cycle > game_concidered_stable_at_cycle){
				write "==================== GAME CONCIDERED AS STABLE ====================";
				stable <- true;
			}
		}
		return stable;
	}
	
	action snap_shot{
		string file_name <- "config_related_save/configuration_"+valid_configuration at game_configuration_index+".csv";
		string data <- "";
					
		int i <- 0;
		int j <- 0;
		loop p1 over:peoples {				
			loop p2 over:peoples {
				if(p2 != nil and p1 != nil){
					int lastMoveIwJ <- (peopleFictitiousPlay(p2).history at peopleFictitiousPlay(p1)) at 3;
					int lastMoveJwI <- (peopleFictitiousPlay(p1).history at peopleFictitiousPlay(p2)) at 3;
					// We save the results
					string hex_color <- (lastMoveIwJ = 0 and lastMoveJwI = 0) ? "FF0000" : 
										((lastMoveIwJ = 1 and lastMoveJwI = 1)? "00FF00" :
										((lastMoveIwJ = 1 and lastMoveJwI = 0)? "FFFF00" :
										((lastMoveIwJ = 0 and lastMoveJwI = 1)? "0000FF" : "000000")));
					data <- data + hex_color + ";";
					}
					j <- j + 1;		
				}					
			j <- 0;
			save data type: "csv" to: file_name;
			data <- "";
			i <- i + 1;
		}		
	}
}

experiment expSequentialGame type: gui {
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
	
	//parameter "Only batch display" var: batch_display_only<-true category: "Sequential game";
	parameter "Configuration index start" var: game_configuration_index<-0 category: "Sequential game";
	parameter "Sequential game testing" var: sequential_game_testing<-true category: "Sequential game";
	parameter "Generated configuration file path" var: file_path<-"config_generation" category: "Sequential game";
	parameter "Generated configuration file name" var: file_name<-"all_conf-1_to_10.csv" category: "Sequential game";
	//parameter "Extension of file" var: file_extension<-csv category: "Sequential game";
	
	
	output{	
			display Charts  refresh_every: 10 {
				chart "Players' behaviour" type: pie background: rgb("lightGray") style: exploded size: {0.9, 0.9} position: {0, 0} {			
		            data "Defector" value: defect_count color: rgb('red') ;
		            data "Cooperator" value: coop_count  color: rgb("green") ;
		            data "Traitor" value: traitor_count  color: rgb("blue") ;
		            data "Sucker" value: sucker_count  color: rgb("yellow") ;
		            data "Chaos" value: chaos_count color: rgb("black") ;
		       	 }
		    }
			 
			display Behav type: opengl{				
				graphics 'G' {
					int i <- 0;
					int j <- 0;
					loop p1 over:peoples {				
						loop p2 over:peoples {
							if(p2 != nil and p1 != nil){
								int lastMoveIwJ <- (peopleFictitiousPlay(p1).history at peopleFictitiousPlay(p2)) at 3;
								int lastMoveJwI <- (peopleFictitiousPlay(p2).history at peopleFictitiousPlay(p1)) at 3;
								draw square(5) at:{i*5,j*5}
									color: (lastMoveIwJ = 0 and lastMoveJwI = 0) ? rgb('red') : 
											((lastMoveIwJ = 1 and lastMoveJwI = 1)? rgb('green') :
											((lastMoveIwJ = 1 and lastMoveJwI = 0)? rgb('yellow'):
											((lastMoveIwJ = 0 and lastMoveJwI = 1)? rgb('blue'):rgb('black'))));
									// flip(0.5)?rgb('red'):rgb('green');
							}
							j <- j + 1;
						}
						j <- 0;
						i <- i + 1;
					}
					
					
				}	
	   		}
	   	}	
}
