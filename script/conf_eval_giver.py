#! /usr/bin/python
# -*- coding: utf-8 -*-

import sys
import tools
import __future__

### Aim : compute term indicated in given list of term file for each configuration given in a list of prisonner dilemma configuration file.
## Input : 
# -> a list of prisonner dilemma configurations (ex : 4 3 2 1) separated by \n ascii char
# -> a list of term (ex : 2*P / S) also separated by \n char
## Ouput :
# -> a report file contains for instance : 4 3 2 1 with  2*P / S gives 4
## Note :
# I choosed to formalise a prisonner dilemma configuration as it : (Traitor)4 (Reward)3 (Punishment)2 (Sucks)1, each value is separated by a space.
def do_your_job(file_configurations_name, file_conditions_name):
	# Vars
	full_path_conf = file_configurations_name
	full_path_cond = file_conditions_name
	file_configurations_name = (full_path_conf.split("/")).pop()
	file_conditions_name = (full_path_cond.split("/")).pop()
	full_path_conf = full_path_conf.replace(file_configurations_name, "")
	full_path_cond = full_path_cond.replace(file_conditions_name, "")

	configurations = tools.read_specific_file(full_path_conf+file_configurations_name, "conf") # configuration vectors, ex : [[3, 2, 0, 1], [5, 4, 3, 1], ...]
	conditions = tools.read_specific_file(full_path_cond+file_conditions_name, "cond") # conditions ex : ["R > 1","T > R", "1 == 1" :D, ...]
	data = tools.pyMap() # a map that allow key:array structure ex: {"configuration":["val1", "val2", "val3"]}
	output = [] # console and file log final output

	# exploiting data : for each configuration
	for config in configurations:
		T=int(config[0]);R=int(config[1]);P=int(config[2]);S=int(config[3])
		conf_sequence = str(T) + " "+ str(R) +" "+ str(P) +" "+ str(S)
		data.add_i(conf_sequence)
		output.append("Proceeding configuration " + tools.bcolors.WARNING + conf_sequence + tools.bcolors.ENDC+ ":")
		# we test if the condition is satisfied by the configuration
		for condition in conditions:
			try:
				data.add_v(conf_sequence, str(condition)) # adding satisfied condition as a value of key configuration
				value_of_evaluation = eval(compile(condition, '<string>', 'eval', __future__.division.compiler_flag))
				output.append("-> " + conf_sequence + " (with " + condition + ") the limit C/D is " + str(value_of_evaluation)+".")
			except:
				print str(sys.exc_info()[0])
	
	# writing output in the console and in a file
	o = open("results/" +file_configurations_name+"_with_"+file_conditions_name,'w')
	for line in output:
		print line
		o.write(tools.m_replace([tools.bcolors.WARNING,tools.bcolors.OKGREEN,tools.bcolors.OKBLUE,tools.bcolors.FAIL,tools.bcolors.ENDC], "", line)+"\n")			
	o.close()

	return data

if __name__ == '__main__':
	if len(sys.argv) == 3:
		do_your_job(sys.argv[1], sys.argv[2])
	else:
		print "Wrong number of arguments (2 expected)."