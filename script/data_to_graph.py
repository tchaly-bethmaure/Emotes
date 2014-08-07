#! /usr/bin/python
# -*- coding: utf-8 -*-
# Developped with python 2.7.3
import networkx as nx
import tools
import conf_check_condition
import sys
import os
import matplotlib


### Aim : verify if given configurations of prisonner dilemma satisfies given conditions.
## Input : 
# -> a list of prisonner dilemma configurations (ex : 4 3 2 1) separated by \n ascii char
# -> a list of conditions (ex : 2*P > T+S) also separated by \n char
## Ouput :
# -> a report file contains for instance : 4 3 2 1 not satisfy 2*P > T+S
# -> a graph representif condition satisfy link between conditions (format .ps)
## Note :
# I choosed to formalise a prisonner dilemma configuration as it : (Traitor)4 (Reward)3 (Punishment)2 (Sucks)1, each value is separated by a space.
def get_sequence(char_map, tab_conditions):
	sequence = ""
	for condition in tab_conditions:
		sequence += char_map.get_key_of_value(condition)
	return sequence

def give_subset_info(seq1, seq2):
	X, Y = "", "" # set X is designed to be a subset of set Y
	bool_contains = False; bool_both_side = False

	index = 0
	count = 0
	lists_size = 0
	if len(seq1) > len(seq2): # seq1 is potentialy a subset of seq2
		X = seq1; Y = seq2		
	if len(seq1) < len(seq2): # seq2 is potentialy a subset of seq1
		X = seq2;  Y = seq1
	if len(seq1) == len(seq2): # we do not know if seq1 is a subset of seq2 or seq1 of seq2
		Y = seq1; X = seq2; bool_both_side = True	
	bool_contains = compute_subset(X, Y)

	# bool_contains : indicates weather or not X is a subset of Y
	# Y is subset of X
	# bool_both_side : indicates weather or not X include Y and Y include X
	return [bool_contains, X, Y, bool_both_side]

def compute_subset(X, Y):
	in_common = []
	bool_subset = False

	for indexX in range(len(X)):
		for indexY in range(len(Y)):
			if X[indexX] == Y[indexY]:
				in_common.append(X[indexX]) # we take X[indexX] arbitrary

	# If we have as many letter added than the length of the shortest sequence Y,
	# Y is a subset.
	if(len(Y) == len(in_common)):		
		return True
	else:
		return False

if __name__ == '__main__':
	full_path_conf = sys.argv[1]
	full_path_cond = sys.argv[2]
	file_configurations_name = (full_path_conf.split("/")).pop()
	file_conditions_name = (full_path_cond.split("/")).pop()
	full_path_conf = full_path_conf.replace(file_configurations_name, "")
	full_path_cond = full_path_cond.replace(file_conditions_name, "")

	data = conf_check_condition.do_your_job(full_path_conf+file_configurations_name, full_path_cond+file_conditions_name)
	flags = ["A","B","C","D","E","F","G","H","I","J","K","L","M","O","P","Q"]
	conditions_map = tools.pyMap()

	# Flaging conditions (which are too complicated) a map
	i = 0
	for line in open(sys.argv[2]):
		if line[0] != "#":
			conditions_map.add_v(flags[i], line.replace("\n",""))
			i+=1

	# Now that condition are flagged, we are creating the graph :
	G = nx.DiGraph()

	# - Grouping patterns by sequence of flags : ABs with ABs, ABCDs with ABCDs ... 
	seq_conf_map = tools.pyMap()
	for configuration in data.indices:
		seq_conf_map.add_v(get_sequence(conditions_map, data.get_values(configuration)), configuration)

	# - Creating nodes
	custom_node_color = {} # nodes' style
	for flag in seq_conf_map.indices:
		G.add_node(flag, style="filled", color="green")
		custom_node_color[flag] = 'green'
		for configuration in seq_conf_map.get_values(flag):		
			G.add_node(configuration, style="filled", color="yellow")
			custom_node_color[configuration] = 'yellow'
			G.add_edge(configuration, flag)

	# - Linking subsets with sets : AB, CD - linked to > ABCD ...
	for flag1 in seq_conf_map.indices:
		for flag2 in seq_conf_map.indices:
			if flag1 != flag2:
				# We look if flag1 is a subset of flag2 or flag2 subset of flag1
				results = give_subset_info(flag1, flag2)
				if results[0]:
					G.add_edge(results[2],results[1])
					if results[3]:
						G.add_edge(results[1],results[2])


	# Drawing the graph and saving import
	#nx.draw_graphviz(G)
	#nx.write_dot(G,"fullpath.png")

	output = [] # file's outputs 
	output.append("\nFlag mapping :")
	print output[0]
	i=0
	for field in conditions_map.indices:
		output.append("\n-> " + field + " : " + conditions_map.values[i][0])
		print "-> " + tools.bcolors.WARNING + field + tools.bcolors.ENDC + " : " + tools.bcolors.OKBLUE + conditions_map.values[i][0] + tools.bcolors.ENDC
		i+=1

	# Writing outputs in a file
	o = open("results/" +file_configurations_name+"_with_"+file_conditions_name,'a')
	for line in output:
		o.write(line)

	if len(sys.argv) >= 4 and int(sys.argv[3]) == 1:
		file_output_generic_name = "results/"+file_configurations_name + "_with_" +file_conditions_name
		nx.draw(G, node_list = custom_node_color.keys(), node_color=custom_node_color.values())
		matplotlib.pyplot.savefig(file_output_generic_name+".png")
		matplotlib.pyplot.show()
		matplotlib.pyplot.close()
		# .dot then .ps file
		nx.write_dot(G,file_output_generic_name+".dot")
		os.system("dot -Tps "+file_output_generic_name+".dot -o "+file_output_generic_name+".ps") # vectorial img file
	