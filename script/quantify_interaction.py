#! /usr/bin/python
# -*- coding: utf-8 -*-
# Developped with python 2.7.3
# /!\ Note : formula needs to be reviewed, it does not match with the simulation.
 
import sys
import tools
from math import sqrt
from math import floor
from math import ceil

### Aim : compute proportions of defectors and cooperators of an Emotes given list of configurations gain of the game.
## Input : 
# -> a list of prisonner dilemma configurations in this order : T R P S (ex : 4 3 2 1) separated by \n ascii char
# -> a file describing the framework
## Ouput :
# -> a report file contains the proportion of C's and D's associated to each game configuration.
## Note :
# I choosed to formalize a prisonner dilemma configuration as it : (Traitor)4 (Reward)3 (Punishment)2 (Sucks)1, each value is separated by a space.
def Ui(strat, map_gain):
	value = -999999
	if strat[0] == "C" and strat[1] == "C":
		value = map_gain["R"]
	if strat[0] == "C" and strat[1] == "D":
		value = map_gain["S"]
	if strat[0] == "D" and strat[1] == "C":
		value = map_gain["T"]
	if strat[0] == "D" and strat[1] == "D":
		vFalue = map_gain["P"]
	return value

# I(s)
def I(strat, map_gain):
	return Ui([strat[0], strat[1]], map_gain) + Ui([strat[1], strat[0]], map_gain)

# Guilti(s)
def Guilti(strat, map_gain):
	return max(I(["C",strat[1]], map_gain), I(["D",strat[1]], map_gain)) - I(strat, map_gain)

def Ui_star(strat, ki, map_gain):
	return Ui(strat, map_gain) - (ki * Guilti(strat, map_gain))

def EUi(strat, ki, map_gain):
	return 0.5 * (Ui_star(strat, ki, map_gain) + Ui_star(strat, ki, map_gain))

def ponderate_sum(bound_min, bound_max, step, frequences):
	i = float(bound_min)
	s = 0
	while i < float(bound_max) + step:
		index = str(round(i, tools.get_round_precision(step)))
		if index in frequences:
			s += frequences[index]
			i += float(step)
		else:
			break
		# i = float(round(i, get_round_precision(precision))) # fix : python >> (0.2 * 0.4) = 0.08000000000000002 bug)
	return s

# Input :
# -> full_path_file : absolute file path of the file
# -> kmin, kmax : boundaires of our model
# -> precision : graduation
# -> distribution : frequences of agent per graduation
def do_your_job(full_path, full_frmwrk_path):
	# we load configurations
	configurations = tools.read_specific_file(full_path, "conf") # configuration are vectors, ex : [[3, 2, 0, 1], [5, 4, 3, 1], ...]

	# we load the framework, it is formatted as a configuration file
	frmwrks = tools.read_specific_file(full_frmwrk_path, "json") # tab = [boundary_min, boundary_max, precision, distribution]
	frmwrk = frmwrks[0] # could do a for(frmwrk in frmwarks): here
	# -> associating framework vars
	distribution = (frmwrk.pop()); precision = float(frmwrk.pop()); kmax = float(frmwrk.pop()); kmin = float(frmwrk.pop())
	output = []

	for configuration in configurations:		
		T=float(configuration[0]);R=float(configuration[1]);P=float(configuration[2]);S=float(configuration[3])
		map_gain = {"T":T,"R":R,"P":P,"S":S}
		map_index_pattern = { 0:"defections", 1:"cooperations",2:"treacheries & leechs"}
		results = []

		# we define limit 1 which is (R-T) / ( S+T - 2R) is supposed to be > 0
		limit2 = round(((R-T) / (S+T-2*R)), tools.get_round_precision(precision))
		limit1 = None
		# (1) 2P >= T+S or (2) 2P < T+S:
		if 2*P >= T+S: # (1)
			 limit1 = float((P-S) / (S+T - 2*R)) # < 0
		if 2*P < T+S: # (2)
			# we define limit 2 which has 3 case :
				# (2-1) : P + R > T + S give the limit (S-P) / 2(P+R-(T+S)) > 0
				# (2-2) : P + R < T + S give the limit (S-P) / 2(P+R-(T+S)) < 0	
			if P + R > T + S or P + R < T + S:
				limit1 = float((S-P) / (2*(P+R-1*(S+T))))						
			# (2-3) : P + R = T + S give the limit P-S > 0, but P-S doesn't depends on Ci so we do not concider it.
		limit1 = round(limit1, tools.get_round_precision(precision))

		# Avoid limits out of framework
		if limit1 < kmin:
			limit1 = kmin
		if limit1 > kmax:
			limit1 = kmax
		if limit2 < kmin:
			limit2 = kmin
		if limit2 > kmax:
			limit2 = kmax

		output.append("Configuration : "+str(T)+" "+str(R)+" "+str(P)+" "+str(S))
		# Now we compute proportion by concidering the distribution of agent (hard)
		# Note : for now, we only manage 2*P < T+S particulary square and gap case.
		# 		Rawls and Bite case are not handled because the learning process is not handled by the limit obtained.
		if 2*P >= T+S:
			output.append("* Rawls *")
			output.append("-> Unable to evaluate exact or approximate quantities, but we can say that we have : ")

			# defectors
			defect_part1 = pow(ponderate_sum(kmin, limit2, precision, distribution),2) - ponderate_sum(kmin, limit2, precision, distribution)
			defect_part2and3 = (ponderate_sum(kmin, limit2, precision, distribution)*ponderate_sum(limit2 + precision, kmax, precision, distribution))*2

			# number of agents
			n = ponderate_sum(kmin, kmax, precision, distribution)
			n = (pow(n,2) - n)

			output.append("--> At least "+ str(defect_part1 + defect_part2and3) +tools.bcolors.FAIL+" "+map_index_pattern[0]+" "+tools.bcolors.ENDC+" among " +str(n)+" interactions.")
			output.append("\n")
		else:
			if P+R - (T+S) > 0:
				output.append("* Bite *")
				output.append("-> Unable to evaluate exact or approximate quantities, this is the hardest pattern. To be analyzed ...")
			
			if P+R - (T+S) < 0:	
				output.append("* Gap *")

				# defectors
				n = ponderate_sum(kmin, limit1 - precision, precision, distribution)
				m = ponderate_sum(kmin, limit1 - precision, precision, distribution)
				results = (pow(n,2) - m)
				# in terms of surface : results = (pow(ponderate_sum(kmin, limit1 - precision, precision, distribution), 2) - sqrt(ponderate_sum(kmin, limit1 - precision, precision, distribution)*2)) # limit - precision <> ceil(limit) but we are in float
				output.append("-> Approximative quantity of "+tools.bcolors.FAIL+" "+map_index_pattern[0]+" "+tools.bcolors.ENDC+" : "+str(results))
				
				# cooperators
				n = ponderate_sum(limit2, kmax, precision, distribution)
				m = ponderate_sum(limit2, kmax, precision, distribution)
				results = (pow(n, 2) - m)
				# results = (pow(ponderate_sum(limit2+precision, kmax, precision, distribution), 2) - sqrt(ponderate_sum(limit2+precision, kmax, precision, distribution)*2)) # limit + precision <> floor(limit)
				output.append("-> Approximative quantity of "+tools.bcolors.OKGREEN+" "+map_index_pattern[1]+" "+tools.bcolors.ENDC+" : "+str(results))

				# traitors & suckers
				# /!\ Bug : floor and ceil functions output are reversed on my computer... so it might need to be swapped on others (PCs).
				results = ponderate_sum(limit1, kmax, precision, distribution) * ponderate_sum(kmin, limit1 - precision, precision, distribution)
				results += ponderate_sum(limit2 - precision, kmax, precision, distribution) * ponderate_sum(limit1, limit2 - precision, precision, distribution)
				results += (pow(ponderate_sum(limit1, limit2, precision, distribution),2) - ponderate_sum(limit1, limit2, precision, distribution)) / 2

				output.append("-> Approximative quantity of "+tools.bcolors.OKBLUE+"treacheries"+tools.bcolors.ENDC+" & "+tools.bcolors.WARNING+"leechs"+tools.bcolors.ENDC+" : "+str(results))
				output.append("\n")

			if P+R - (T+S) == 0:
				output.append("* Square *")
				# Compute proportion of Full cooperative agent which is fixed
				quantity = {
					0:[kmin, limit2, kmin, limit2, tools.bcolors.FAIL], # defectors
					1:[limit2, kmax, limit2, kmax, tools.bcolors.OKGREEN], # cooperators
					2:[limit2, kmax, kmin, limit2, tools.bcolors.ENDC] # traitors & suckers : 3:[kmin, limit2, limit2, kmax] is the same quantity because we have a symetric interactions' matrix
				}
				
				i = 0
				for row in quantity:
					results.append(ponderate_sum(quantity[row][0], quantity[row][1], precision, distribution)*ponderate_sum(quantity[row][2], quantity[row][3], precision, distribution))
					output.append("-> Exact quantity of "+quantity[4]+str(map_index_pattern[i])+tools.bcolors.ENDC+ " : "+str(results[i]))
					i += 1
				output.append("\n")
	output.append("Done.")

	# writing output in the console and in a file
	#print(str(output))

	file_name = (full_path.split("/")).pop()+"_with_"+ ((full_frmwrk_path.split("/").pop()))
	o = open("results/"+file_name,'w')
	for line in output:
		print line
		o.write(tools.m_replace([tools.bcolors.WARNING,tools.bcolors.OKGREEN,tools.bcolors.OKBLUE,tools.bcolors.FAIL,tools.bcolors.ENDC], "", line)+"\n")
	o.close()
	# Done

if __name__ == '__main__':
	if len(sys.argv) == 3:
		full_path = sys.argv[1]
		full_frmwrk_path = sys.argv[2]

		do_your_job(full_path, full_frmwrk_path)
	else:
		print("Wrong number of argument. It should be arg#1 : something.confile & arg#2 : something_else.frmwrk.")
		print("(!) Note : framework files (.frmwrk) can be created by the framework_file_generator.py script.")