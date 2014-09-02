/**
 *  emotesV8
 *  Author: cberthaume
 *  Description: experience which take a file (.csv) containing PD configuration formalized as
 *  it follows : "T R P S; T R P S; T R P S;" (with (T)raitor (R)eward, (P)unishment and (S)ucker). For exemple : "4 3 2 1; 5 3 2 0;"
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
import "peoplePureStrategy.gaml"
import "configFileHandler.gaml"
import "iteratedGame.gaml"

global {
	// Sequential testing
	bool sequential_game_testing;
	list<string> valid_configuration;
	list<string> rejected_configuration;
	bool batch_display_only;
	int game_concidered_stable_at_cycle <- 600;
	bool screen_capture;
	
	// Game configuration vars
	int game_configuration_index;
	int nb_of_configuration;
	int cycle_to_sub <- 0;
	
	// Statistics vars1
	map<float, int> agent_gain <- []; // map<int:agent#, int:cash>
	float total_gain <- 0.0;
	float min_gain <- 0.0;
	float max_gain <- 0.0;
	int defect_count <- 1;
	int coop_count <- 0;
    int chaos_count <- 0;
    int traitor_count <- 0;
	int sucker_count <- 0;	
    int nb_of_stable_state <- 1; // only stable ones
	int nb_of_unstable_state <- 1; // unstable
	map<string,int> state_history <- ["stable"::0, "unstable"::0, "cycle_count"::0];
	map<string, int> ideal_choosed <- ["Rawls"::0, "Harsanyi"::0, "Other"::0];
	map<float, int> guilt_repartition <- [];
    int stable_change_max_cycle_elapsed <- 100;
    
    // Generated configuration file vars 
   	string file_path;
   	string file_name;
   	string file_extension;
    
    string save_results_path;
    
	init{
		if(sequential_game_testing){
			valid_configuration <- read_file_containing_config(file_name,file_path) ;  // Initial configuration
			rejected_configuration <- [];
			// if(sequential_game_testing = true){do find_matching_DP_config();}
			if(game_configuration_index != 0){ do reset_game(); }		
		}
	}
	
	reflex 	begin_an_other_game {
		do statistics_computation();
		bool is_game_stable <- self compute_game_stability();		
		// If the experiment sequential game testing is on, we chain instances of iterated DP game
		if (sequential_game_testing = true) {
			if(is_game_stable){
				nb_of_configuration <- length(valid_configuration);
				if(screen_capture){ do snap_shot(); }
				if(game_configuration_index < nb_of_configuration + 1){					
					//do save_statistic(); // We save the results : coop vs defect
					do reset_game();
					write "Advancement : "+string(game_configuration_index/nb_of_configuration)+" % done.";
				}
				else { write "xxxxxxxxxxx Simulation is over xxxxxxxxxxx"; do halt; }
			}
		}
	}
	
	action save_statistic{				
		string file_name <- save_results_path+"/PrisonnerDilemma_Stats";
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
	        agent_gain <- [];
	        state_history["stable"] <- nb_of_stable_state;
			state_history["unstable"] <- nb_of_unstable_state;
	        nb_of_stable_state <- 0; // stable
	        nb_of_unstable_state <- 0; // stabe + unstable	        
			guilt_repartition <- [];
			ideal_choosed <- [];
			total_gain <- sum(agents of_generic_species(people) collect(each.sumPayoffs)); // Global payoffs
			max_gain <- agents of_generic_species(people) max_of (each.sumPayoffs);
	        min_gain <- agents of_generic_species(people) min_of (each.sumPayoffs);
	        loop p1 over:peoples{
				// Map gain
	        	// add((float(p1.guiltAversion))::(int(p1.sumPayoffs))) to:agent_gain;
	        	// total_gain <- total_gain + int(p1.sumPayoffs);	
				
	        	if(peopleStrategy = "Pure"){
	        		int move_p1 <- peoplePureStrategy(p1).strategy="C"?1:0;	
	        		// Count coop and count defect
	        		if(move_p1 = 1){coop_count <- coop_count +1;}else{defect_count <- defect_count +1;} 
	        		
	        		// Ideal repartition
	        		if((ideal_choosed.keys contains p1.idealMode) = false){ add(p1.idealMode::1) to: ideal_choosed; } 
	        		else{ ideal_choosed[p1.idealMode] <- ideal_choosed[p1.idealMode] + 1;}	
	        		
	        		// Guilt repartition	        		
	        		if((guilt_repartition.keys contains p1.guiltAversion) = false){ add(p1.guiltAversion::1) to: guilt_repartition; } 
	        		else{ guilt_repartition[p1.guiltAversion] <- guilt_repartition[p1.guiltAversion] + 1;}	

	        	}else{
					loop p2 over:peoples{
						switch (peopleStrategy){
							match "FictitiousPlay"{
							int move_p1 <- (peopleFictitiousPlay(p1).history at p2) at 3;							
							int move_p2 <- (peopleFictitiousPlay(p2).history at p1) at 3;
							
							// Stats for FictitiousPeople
							if (length(peoples of_species peopleFictitiousPlay) != 0 and p1.guiltAversion != p2.guiltAversion){						
								if(move_p1 = 1 and move_p2 = 1) { coop_count <- coop_count + 1; }
								if(move_p1 = 0 and move_p2 = 0){ defect_count <- defect_count + 1; }
								if(move_p1 = 1 and move_p2 = 0){ sucker_count <- sucker_count + 1; }
								if(move_p1 = 0 and move_p2 = 1){ traitor_count <- traitor_count + 1; }					
								
								if ((move_p1 = 1 and move_p2 = 1) or (move_p1 = 0 and move_p2 = 0)) {							
									nb_of_stable_state <- nb_of_stable_state + 1; // A bit shaky			
								}						
								else{			
									nb_of_unstable_state <- nb_of_unstable_state + 1;							
								}
							}
						}					
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
		
		if(peopleStrategy = "FictitiousPlay"){
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
		}
		else{
			if(peopleStrategy = "Pure" and
			(length(peoplePureStrategy) = length(peoplePureStrategy where (each.strategy = "C")) 
				or 
			 length(peoplePureStrategy) = length(peoplePureStrategy where (each.strategy = "D"))) ){
				write "==================== GAME HAS CONVERGED ====================";
				stable <- true;
			}
		}
		
		return stable;
	}
	
	action snap_shot {
		switch(peopleStrategy){
			match "FictitiousPlay"{
				string file_name <- save_results_path+"/configuration_"+valid_configuration at game_configuration_index+".csv";
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
			
			match "Pure"{
				// PayOffs repartition
				int cnt <- 0;
				map<float,float> gain_freq <- [];
				loop agt over:agents of_generic_species(people) {
					if gain_freq.keys contains agt.guiltAversion{
						gain_freq[agt.guiltAversion] <- int(gain_freq[agt.guiltAversion]) + 1;
					}
					else{
						add(agt.guiltAversion::1) to:gain_freq;
					}
					cnt <- cnt + 1;
				}
				loop key over:gain_freq.keys{ gain_freq[key] <- gain_freq[key] / cnt;}
				
				// SnapShot string buffer
				string file_name <- save_results_path+"/report_"+file_name+"_Evo-"+peopleStrategy+"_Ideal-"+idealComputation+"_Guilt"+guiltAversionMean+".save";
				string data <- "Value::"+valid_configuration at game_configuration_index+";"+"C::"+string(coop_count)+";D::"+defect_count+";IdealRepartition::"
				+ideal_choosed.keys+":"+ideal_choosed.values+";GainFreq::"+gain_freq.keys+":"+gain_freq.values+";GuiltRep::"+guilt_repartition.keys+":"+guilt_repartition.values+";SumPayOffs::"+string(round(total_gain))+";MinPayOffs::"
				+string(round(min_gain))+";MaxPayOffs::"+string(round(max_gain))+";Iteration::"+string((cycle-cycle_to_sub))+"\n";				
				
				// Saving into file_name
				save data type: "csv" to: file_name;
			}
		}
	}
	action view_guilt_rep{
		write "Guilt repartition of current system : "+string(guilt_repartition.keys);
	}
}

experiment expSequentialGame type: gui {
	user_command guilt_rep action: view_guilt_rep;
	parameter 'Agents distribution law'				var: guiltLaw <- 'Normal' among: ['Unifrom','Normal'] category: 'Distribution';
	parameter 'Guilt Aversion Mean'					var: guiltAversionMean <- 2.88 min: -999.0 max: 1000.0 category:'Distribution';
	parameter 'Guilt Aversion Dispersion'			var: guiltDispersion <- 0.495 min: 0.0 max: 1000.0 category:'Distribution';
	parameter 'Number of agents'					var: nbOfAgtOfSample <- 82 min: 1 max: 1000 category:'Distribution';	
	
	parameter 'Max Guilt Aversion Initial' 				var: guiltAversionInitMax <- 4.1 min: 0.0 max: 1000.0 category:'Init Environment';
	parameter 'Min Guilt Aversion Initial' 				var: guiltAversionInitMin <- 0.0 min: 0.0 max: 1000.0 category:'Init Environment';
	parameter 'Discretization of the guilt aversion' 	var: guiltAversionStep <- 0.1 min: 0.01 max: 1.0 category:'Init Environment';
	parameter 'Number of agents per gA' 				var: nbAgentsPerGA <- 1 min: 1 max: 100 category: 'Init Environment';
	
	parameter 'Agents\' strategy' 	var: peopleStrategy <- 'Pure' among: ['Pure','Fictious play'] category: 'Simulation mode';
	parameter 'Evolution mode' 				var: evolutionMode <- 'Replicator dynamic' among: ['None','Replicator dynamic'] category: 'Simulation mode';
	parameter 'Ideal computation' 			var: idealComputation <- "Harsanyi" among: ["Rawls","Harsanyi","Random"] category: 'Simulation mode';

	parameter 'Reward (R)' 		var: R <- 2 min: 0 max:20 category: 'Prisoner dilemna';
	parameter 'Temptation (T)' 	var: T <- 3 min: 0 max:20 category: 'Prisoner dilemna';	
	parameter 'Sucker (S)' 		var: S <- 0 min: 0 max:20 category: 'Prisoner dilemna';
	parameter 'Punishment (P)' 	var: P <- 1 min: 0 max:20 category: 'Prisoner dilemna';
	
	parameter 'Emotional payoffs' 		var: payoffEmo <- true category: 'Replicator dynamic';
	parameter 'Frequence of evolution' 	var: stepEvol <- 10 min: 1 max: 100 category: 'Replicator dynamic';
	parameter 'Nb Agents will evolve' 	var: nbAgentsEvol <- 5 min: 1 max: 100 category: 'Replicator dynamic';
	parameter 'Replication Probability' var: probaEvolution <- 30.0 category: 'Replicator dynamic';
	parameter 'Mimic also ideal' var: bMimicIdeal <- false category: 'Replicator dynamic';
	parameter 'Mimic also guilt' var: bMimicGuilt <- false category: 'Replicator dynamic';
	
	parameter 'Make some noise' var:bNoise <- false category:'Noise';
	parameter 'Ideality switch' var:idealityNoise <- 30 min: 0 max : 100 category:'Noise';
	parameter 'Guilt noise' 	var:guiltNoise <- 30 min: 0 max : 100 category:'Noise';
	parameter 'Strategy noise' 	var:stratNoise <- 30 min: 0 max : 100 category:'Noise';
	parameter 'Rational noise' 	var:rationalNoise <- 30 min: 0 max : 100 category:'Noise';
	
	parameter 'Display debug Game construction' 	var: debugGame <- false category: 'debug';
	parameter 'Display debug of play' 				var: playWithDebug <- false category: 'debug';	
	parameter 'Display debug of game resolution' 	var: resolveGameDebug <- false category: 'debug';

	parameter 'Agent To display' 				var: numAgentToDisplay <- -1 category: 'debug';
	parameter 'Agent with whom it interacts' 	var: otherAgentToDisplay <- -1 category: 'debug';
	
	parameter 'Step to save' 				var: cycleToSave <- 3000 min: 0 max: 2000000 category:'Analysis';
	parameter 'Step from which to observe' 	var: cycleObs <- 2000 category: 'Analysis';	
	
	//parameter "Only batch display" var: batch_display_only<-true category: "Sequential game";
	parameter "Generate snapshot or report" 		var: screen_capture <- true category: "Sequential game";
	parameter "Configuration index start" 			var: game_configuration_index<-0 category: "Sequential game";
	parameter "Sequential game testing" 			var: sequential_game_testing<-true category: "Sequential game";
	parameter "Generated configuration file path" 	var: file_path<-"config_generation" category: "Sequential game";
	parameter "Generated configuration file name" 	var: file_name<-"all_conf-1_to_10.csv" category: "Sequential game";
	parameter "Results saving path" 				var: save_results_path<-"simulation_saves" category: "Sequential game";		
	
		/*output{			        
			display Stat refresh_every: 10 {
				chart name:'Players\'s behaviour' type: pie background: rgb("lightGray") style: exploded size: {0.5, 0.5} position: {0, 0} {			
		            data "Defector" value: defect_count color: rgb('red') ;
		            data "Cooperator" value: coop_count  color: rgb("green");
		            data "Traitor" value: traitor_count  color: rgb("blue");
		            data "Sucker" value: sucker_count  color: rgb("yellow");
		            data "Chaos" value: chaos_count color: rgb("black") ;
		    	}
		    	chart "Global payoffs" type: series background: rgb('lightGray') size:{0.5, 0.5} position:{0.5,0} {
					data name: "sum payoffs" value: total_gain;
					data name: "min payoffs" value: min_gain color:rgb(228,107,33);
					data name: "max payoffs" value: max_gain color:rgb(203,54,206);
				}
				chart "Ideal repartition" type: pie background: rgb('lightGray') size:{0.5, 0.5} position:{0,0.5} {
					data name: "Rawls" value: peoplePureStrategy count (each.idealMode = "Rawls");
					data name: "Harsanyi" value: peoplePureStrategy count (each.idealMode = "Harsanyi");
				}
				chart name:'Players\'s behaviour history' type: series background: rgb("lightGray") style: exploded size: {0.5, 0.5} position: {0.5, 0.5} {			
		            data "Defector" value: defect_count color: rgb('red') ;
		            data "Cooperator" value: coop_count  color: rgb("green");
		    	}	    	
			}
			display PayOffs refresh_every: 1 {
				chart "Global payoffs" type: series background: rgb('lightGray') size:{1, 1} position:{0,0} {
					data name: "sum payoffs" value: total_gain;
					data name: "min payoffs" value: min_gain color:rgb(228,107,33);
					data name: "max payoffs" value: max_gain color:rgb(203,54,206);
				}
			}
			display CoopHisto refresh_every: 1 {
				chart name:'Players\'s behaviour history' type: series background: rgb("lightGray") style: exploded size: {1, 1} position: {0, 0} {			
		            data "Defector" value: defect_count color: rgb('red') ;
		            data "Cooperator" value: coop_count  color: rgb("green");
		    	}	   
			}
			   display gain refresh_every: 10 {		   	
			       	 chart name:'Repartition of gain' type: histogram background: rgb('lightGray') {
			       	 	if(total_gain != 0 and guiltAversionStep != 0 and length(agent_gain) > 1){
			       	 		int i <- 0;		       	 							
							loop value over:agent_gain{
								// Amount (in %) of total gain agent i acquired
								float percent_of_cake <- (value / total_gain) with_precision 0.01;
								data name:string(i) value: percent_of_cake;
								i <- i + 1;
							}						
						}
					}
			    }
				
				/*display Behav type: opengl{				
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
	} */
}
