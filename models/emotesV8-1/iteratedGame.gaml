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
import "peopleRationalPlay.gaml"
import "main.gaml"

species iterated_game_instance {
	map<string, int> instance_configuration;
	list<people> peoples_in_instance;
	
	int R_instance;
	int P_instance;
	int T_instance;
	int S_instance;
	
	map<int, string> game_pattern_type <- [0::"Rawls",1::"Square",2::"Gap",3::"Bite",-1::"Unknown"]; // see get_game_pattern_code for further explication
		
	float sumPayOff_instance <- 0.0;
			
	action init_manually(map configuration){		
		instance_configuration <- configuration;
		R_instance <- instance_configuration["R"];
		P_instance <- instance_configuration["P"];
		T_instance <- instance_configuration["T"]; 
		S_instance <- instance_configuration["S"];
		
		// Init. of the game
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

		// Creation of agents by type (peopleStrategy gives the type of strat)
		do createPeople(peopleStrategy, getDistribution(guiltLaw, guiltLaw="Unifrome"?nbAgentsPerGA:nbOfAgtOfSample));
		
		// self can't read agent people created via agent of_generic_species people, so we pass via a global var : peoples.
		peoples_in_instance <- peoples;

		do displayGame;
		do displayParameters;
		if(idealComputation = "Harsanyi" and peopleStrategy != "Pure"){ do display_game_pattern; }
	}
	
	reflex play {		
		loop i from: 0 over:shuffle(peoples_in_instance){
			loop j from: 0 over:shuffle(peoples_in_instance){
				if(i != j){
					people p1 <- i;
					people p2 <- j;
					
					string s1 <- p1 play_with [p::p2];
					string s2 <- p2 play_with [p::p1];
					
					ask p1 {
						do resolve_game p: p2 s: [s1,s2];
					}
					ask p2 {
						do resolve_game p: p1 s: [s2,s1];
					}
				}
			}
		}
		sumPayOff_instance <- sum((agents of_generic_species people) collect (each.sumPayoffs)); 
	}
	
	reflex evolve when: ((evolutionMode = 'Replicator dynamic') and (cycle mod stepEvol = 0)) {
		peoplePureStrategy p <- nil;
		create peoplePureStrategy{ p <- self; } 
		p.strategy <- getStratToReplicate();
		p.guiltAversion <- (bMimicGuilt=true)?getGuiltToReplicate():0;
		p.idealMode <- (bMimicIdeal=true)?getIdealityToReplicate():"";
		
		ask peoplePureStrategy{ do replicate(p); }
		
		
	}
	
	reflex noise when: (evolutionMode = 'Replicator dynamic' and bNoise = true) {		
		list<peoplePureStrategy> lP <- one_of(peoplePureStrategy); // Could ask x amount of people instead of one
		ask peoplePureStrategy {
			if(rnd(100) <= guiltNoise){
				guiltAversion <- rnd((guiltAversionInitMax - guiltAversionInitMin)/guiltAversionStep)*guiltAversionStep + guiltAversionInitMin;
				guiltAversion <- guiltAversion with_precision precision;
			}
			
			if(rnd(100) <= stratNoise){
				if(rnd(1) = 1){ strategy <- "C"; }
				else{ strategy <- "D"; }
			}
			/*if(rnd(100) <= idealityNoise){
				if(rnd(1) = 1){ idealMode <- "Rawls";}
				else{ idealMode <- "Harsanyi";}
				do computeIdeality();
			}*/
		}
	}
	
	// Faction of strategy i at time t, where t is (for now the current tick)
	float getStrategyProportion(string str){
		return length(peoplePureStrategy where (each.strategy = str))/ length(peoplePureStrategy);
	}
	float getGuiltProportion(float i) {
		return length(peoplePureStrategy where (each.guiltAversion = i))/ length(peoplePureStrategy);
	}
	float getIdealProportion(string str) {
		return length(peoplePureStrategy where (each.idealMode = str))/ length(peoplePureStrategy);
	}
	
	// Get the fitness of the strategy i of the system (should be function of time)
	float getFitnessOfStrategyPerAgt(string str){
		// Is described as : the fitness of strategy i at time t
		// We assume that fitness of i at time ti is mean gain by strategy at time t
		return mean(peoplePureStrategy where (each.strategy = str) collect (each.stepPayoff));
	}
	float getFitnessOfGuiltPerAgt(float i){
		return mean(peoplePureStrategy where (each.guiltAversion = i) collect (each.stepPayoff));
	}
	float getFitnessOfIdealPerAgt(string str){
		return mean(peoplePureStrategy where (each.idealMode = str) collect (each.stepPayoff));
	}
	
	// Get the average fitness of the system (should be function of time)
	float fitnessOfSystemPerAgt {
		return mean(peoplePureStrategy collect (each.stepPayoff));
	}	
	
	//// (David Catteeuw says or Cecile Wolffs define) Evolution :
	// For each strategy i: si(t+1) = xi(t) fi(t) / f(t), 
	// where xi(t) is the fraction of strategy i in the population at time t, fi(t) is the fitness of strategy i at time t, 
	// and f(t) is the average fitness in the population.
	string getStratToReplicate { 
		string strategyToChoose <- "C";
		float fitnessOfSystemPerAgt <- fitnessOfSystemPerAgt(); // Sum(Payoffs) of all agent
		
		// Fraction of C's and D's fitness in the population :
		float fitnessC <- (getStrategyProportion("C") * getFitnessOfStrategyPerAgt("C")) / fitnessOfSystemPerAgt;
		float fitnessD <- (getStrategyProportion("D") * getFitnessOfStrategyPerAgt("D")) / fitnessOfSystemPerAgt;
		
		// fitnessC <- getStrategyProportion("C") * (getFitnessOfStrategy("C") - fitnessOfSystem); ?
		// fitnessD <- getStrategyProportion("D") * (getFitnessOfStrategy("D") - fitnessOfSystem); ?
		
		// The agent choose the fraction which have the highest value.
		if(fitnessC > fitnessD){ return "C"; }
		else{if(fitnessC < fitnessD){ return "D"; }else{ return rnd(1)=1?"C":"D"; }}
	}
	
	string getIdealityToReplicate {
		string idealityToChoose <- "";
		float fitnessOfSystemPerAgt <- fitnessOfSystemPerAgt();
		list<string> ideals <- ["Rawls", "Harsanyi"];
		
		// Fitness of population who adopt Rawls or Harsanyi
		float fitnessRawls <- (getIdealProportion(ideals[0]) * getFitnessOfIdealPerAgt(ideals[0])) / fitnessOfSystemPerAgt;
		float fitnessHarsanyi <- (getIdealProportion(ideals[0])* getFitnessOfIdealPerAgt(ideals[0])) / fitnessOfSystemPerAgt;
		
		if(fitnessRawls > fitnessRawls){ return ideals[0]; }
		else{if(fitnessRawls < fitnessRawls){ return ideals[1]; }else{ return rnd(1)=1?ideals[0]:ideals[1]; }}
		
		return;
	}
	
	float getGuiltToReplicate {
			list<peoplePureStrategy> lstPpl <- peoplePureStrategy collect (each.guiltAversion);
			// Introducing random fitness choice when fitness are equal
			lstPpl <- shuffle(lstPpl);
			float fitnessOfSystemPerAgt <- fitnessOfSystemPerAgt();
			
			// Init values : we randomly take one agent as reference
			peoplePureStrategy p <- one_of(peoplePureStrategy);
			float fitnessScoreOfGuilt <- (getGuiltProportion(p.guiltAversion) * getFitnessOfGuiltPerAgt(p.guiltAversion)) / fitnessOfSystemPerAgt;
			float optimGuilt <- p.guiltAversion;			
			loop p over: lstPpl{
				float tempFitnessScoreOfGuilt <- (getGuiltProportion(p.guiltAversion) * getFitnessOfGuiltPerAgt(p.guiltAversion)) / fitnessOfSystemPerAgt;
				if(fitnessScoreOfGuilt < tempFitnessScoreOfGuilt){
					fitnessScoreOfGuilt <- tempFitnessScoreOfGuilt;
					optimGuilt <- p.guiltAversion;
				}
			}
			
			return optimGuilt;
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
		 
	
	// PeopleCreation taking in account the peopleStrategy type of the game/simulation
	action createPeople(string p_strat, list<float> guiltDistribution){
		if(p_strat='Fictious play'){ do _createFictitiousPlayPeople(guiltDistribution); }
		if(p_strat='Pure'){ do _createPureStratPeople(guiltDistribution); }
		if(p_strat='Rational'){ do _createRationalPlayPeople(guiltDistribution); }
	}
	
	// Creating people depending on peopleStrategy types :
	action _createFictitiousPlayPeople(list<float> guiltDistribution) {
		loop i from: 0 to: (length(guiltDistribution) - 1) {
			create peopleFictitiousPlay number: nbAgentsPerGA {
				sumPayoffs <- 0.0;
				guiltAversion <- guiltDistribution[i];
				idealMode <- idealComputation;
				do init();
			}				
		}
		// needed to display the black color in the interaction matrix display
		ask peopleFictitiousPlay{
			loop i from: 0 to: length(peopleFictitiousPlay)-1 {
				// eltOfHisto is a list : [nbCoop, totalInter, utilityGained, lastCoop, nbStepWithoutChange]
				add(peopleFictitiousPlay(i)::[0, 0, 0, -1, 0]) to:self.history;
			}
		}
	}	
	action _createRationalPlayPeople(list<float> guiltDistribution){
		loop i from: 0 to: (length(guiltDistribution) - 1) {
			create peopleRationalPlay{
				sumPayoffs <- 0.0;
				guiltAversion <- guiltDistribution[i];
				idealMode <- idealComputation;
				do init();
			}				
		}
		ask peopleRationalPlay{
			loop i from: 0 to: length(peopleRationalPlay)-1 {
				// lastMove_with_people is a map : people::[lastMove], -1 => none
				add(peopleRationalPlay(i)::-1) to:self.lastMove_with_people;
			}
		}
	}
	action _createPureStratPeople(list<float> guiltDistribution){
		loop i from: 0 to: (length(guiltDistribution) - 1) {
			create peoplePureStrategy {
				sumPayoffs <- 0.0;
				strategy <- "C";
				guiltAversion <- guiltDistribution[i];
				idealMode <- idealComputation;
				do init();
			}
			create peoplePureStrategy {
				sumPayoffs <- 0.0;
				strategy <- "D";
				guiltAversion <- guiltDistribution[i];
				idealMode <- idealComputation;
				do init();
			}
		}
	}
	
	// Take the distribution type (e.g. uniform, normal), a list of val useful for the law used and the sample size wanted
	// Give a distribution of number according to the size wanted
	list<float> getDistribution(string distribType, int sampleSize){	
		list<float> distribGuilt <- [];
		list<float> lval <- [];
		
		if(distribType = "Normal"){ 
			add(guiltAversionMean) to:lval; add(guiltDispersion) to:lval; add(guiltAversionStep) to:lval; add(float(sampleSize)) to:lval;
			distribGuilt <- _giveNormalDistribution(lval);
		}
		else{ // Default distrib is Uniform
			add(guiltAversionInitMax) to:lval; add(guiltAversionInitMin) to:lval; add(guiltAversionStep) to:lval; add(precision) to:lval; add(float(sampleSize)) to:lval;
			distribGuilt <- _giveUniformDistribution(lval);
		}
		return distribGuilt;
	}
	
	action _giveUniformDistribution(list<float> lval){
		list<float> distribGuilt <- [];
		
		// lval <- [guiltAversionInitMax, guiltAversionInitMin, guiltAversionStep, numberOfAgentPerStep]
		float guiltAversionInitMax <- lval[0];
		float guiltAversionInitMin <- lval[1];
		float guiltAversionStep <- lval[2];
		float numberOfAgentPerStep <- lval[3];
		
		loop i from: int(guiltAversionInitMin/guiltAversionStep) to: int((guiltAversionInitMax/guiltAversionStep) with_precision getPrecisionOfFloat(guiltAversionStep)) step: 1 {
			loop j from: 1 to: numberOfAgentPerStep{
				add((i*guiltAversionStep) with_precision getPrecisionOfFloat(guiltAversionStep)) to:distribGuilt;
			}
		}
		return distribGuilt;		
	}
	
	action _giveNormalDistribution(list<float> lval){
		list<float> distribGuilt <- [];
		
		// lval <- [guiltAversionMean, guiltDispersion, discretization, numberOfAgentWanted]
		float guiltAversionMean <- lval[0];
		float guiltDispersion <- lval[1];
		float guiltDiscretization <- lval[2];
		int numberOfAgentWanted <- int(lval[3]);
		
		loop i from:1 to:numberOfAgentWanted {
			add((gauss(guiltAversionMean, guiltDispersion)) with_precision getPrecisionOfFloat(guiltDiscretization)) to:distribGuilt;
		}
		
		return distribGuilt;
	}
	
	int getPrecisionOfFloat(float number){
		return int(length(string(int(1/number))) - 1);
	}
	
	// Codify the different pattern in Harsanyi ideal mode
	int get_game_pattern_code {
		int code <- -1; // we enum pattern type by a code
		
		if(idealComputation = "Harsanyi"){
			// Each configuration of a game has a specific pattern that -intuitively- can be classified in 4 classes :
			if(2*P_instance >= T_instance+S_instance){
				// we are in a "Rawls" type pattern, try for instance : (T)9 (R)8 (P)7 (S)0
				code <- 0;
			} else{
				// -> Square : we observ four square of different colors, and there is no gap seperate one group at an other 
				// (ex : (T)3 (R)2 (P)1 (S)0)
				if(P_instance+R_instance - (T_instance+S_instance) = 0){
					code <- 1;
				}
				// -> Called Gap : there is at least one square (of reds or greens) max two (reds and greens), yellows and blues are pentagones
				// 	blues and yellows create a gap between greens and reds 
				// (ex of Gap : (T)6 (R)4 (P)2 (S)1)
				if(P_instance+R_instance - (T_instance+S_instance) < 0){
					code <- 2;
				}
				// -> Called Bite :there is not only squares : greens steps on reds and reds steps on blues and yellows
				// (ex of Bite : (T)7 (R)6 (P)3 (S)1)
				if(P_instance+R_instance - (T_instance+S_instance) > 0){
					code <- 3;
				}
			}
		}
		// Other than Harsanyi aren't explored yet.
		
		return code;
	}
	
	action display_game_pattern {		
			write "(!) Note : the configurations of the attractor basin that agent will be is called "+game_pattern_type[get_game_pattern_code()]+".";
			write "Limits are : "+get_pattern_boundaries();
	}
	
	// Get limits of a specific pattern (only available in Harsanyi ideal mode).
	list<float> get_pattern_boundaries {
		list<float> boundaries <- [];
		
		if(idealComputation = "Harsanyi"){
			// TODO : Wrong round ... 0.5 instead of 0.25 for ...
			// FIXME : change with_precision 1, it vary depending on guiltAversionStep
			int code <- self get_game_pattern_code();
			switch code {
				match 0 { add( ( (P_instance - S_instance) / (S_instance+T_instance-2*R_instance) ) with_precision 1) to:boundaries; add(((R_instance-T_instance) / (S_instance+T_instance-2*R_instance)) with_precision 1) to:boundaries; }
				match 1 { add(((R_instance-T_instance) / (S_instance+T_instance-2*R_instance)) with_precision 1) to:boundaries; }
				match 2 { add((((S_instance-P_instance) / (2*(P_instance+R_instance-1*(S_instance+T_instance))))) with_precision 1) to:boundaries; add(((R_instance-T_instance) / (S_instance+T_instance-2*R_instance)) with_precision 1) to:boundaries; }
				match 3 { add(((S_instance-P_instance) / (2*(P_instance+R_instance-1*(S_instance+T_instance)))) with_precision 1) to:boundaries; add(((R_instance-T_instance) / (S_instance+T_instance-2*R_instance)) with_precision 1) to:boundaries; }
				default {  }
			}
		}
		return boundaries;
	}
}