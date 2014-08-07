#! /usr/bin/python
# -*- coding: utf-8 -*-
# Developped with python 2.7.3
import tools
import sys
import os
import matplotlib
import pygal
import numbers
from math import sqrt

def lst_str_to_float(l):
	i = 0
	for el in l:
		l[i] = float(el)
		i +=1
	return l

def do_your_job(full_path_csv_file):
	file_name = (full_path_csv_file.split("/")).pop()
	data = tools.read_specific_file(full_path_csv_file, "csv") # I guess that encoding the file in json would be a better choice....

	# each line of the csv file (the expected one) is formated as it follow: key::value;key::value; etc...
	# where value could be : character or key:value table ( e.g. ["a","b","c"]:[1,2,3] )
	tab = []
	temp_map = {}
	for line in data:
		temp_map = {}
		for pair in line:			
			pair = pair.split("::")
			if len(pair[1].split(":")) == 1:
				if isinstance(pair[1], numbers.Real) or pair[1].isdigit():
					temp_map[pair[0]] = float(pair[1])
				else:
					temp_map[pair[0]] = pair[1]
			else:
				temp_map[pair[0]] = {}
				map_of_object_int = (pair[1].split(":")) # list of object (map_of_object_int[0]) could be : floats or strings
				list_of_keys = tools.str_table_to_list(map_of_object_int[0])
				list_of_values = tools.str_table_to_list(map_of_object_int[1])
				i = 0
				for key in list_of_keys:
					temp_map[pair[0]][key] = list_of_values[i]
					i += 1
		tab.append(temp_map)
	# static values mapped with possible dynamic (string) values
	key_value_of_data = {
	 0:"Value",
	 1:"C", 2:"D", 
	 3:"IdealRepartition", 
	 4:"GuiltRep", 5:"SumPayOffs", 
	 6:"MinPayOffs", 7:"MaxPayOffs",
	 8:"Iteration",9:"IdealRepartition",91:"Rawls",92:"Harsanyi",10:"GainFreq"}
	
	list_of_conf = {"C":{},"D":{}}
	computed_stat = {0:"gain",1:"guilt_lvl",2:"iteration"}
	stat_elements = {0:"min",1:"max",2:"mean",3:"sum", 4:"standard_deviation", 5:"configuration_count"}

	statistics = {} # 1:{0:{},1:{}},2:{0:{},1:{}}
	# init statistics variable
	for key in [1,2]: # 1 is C and 2 is D
		statistics[key] = {}
		statistics[key][key_value_of_data[0]] = [] # list of configurations in statistics[key]
		for type_stat in computed_stat.keys():
			statistics[key][type_stat] = {}
			for stat_element in stat_elements.keys():
				val = 0
				if stat_element == 0: # min
					val = 9999
				if stat_element == 1: # max
					val = -9999
				statistics[key][type_stat][stat_element] = val

	# statistics computation
	for record in tab:
		## number of agent of the record
		number_of_agent = 0
		if key_value_of_data[91] in record[key_value_of_data[9]].keys():
			number_of_agent += float(record[key_value_of_data[9]][key_value_of_data[91]]) 
		if key_value_of_data[92] in record[key_value_of_data[9]].keys():
			number_of_agent += float(record[key_value_of_data[9]][key_value_of_data[92]]) 

		## absolute strategy of record
		if record[key_value_of_data[1]]>record[key_value_of_data[2]]:
			strategy = 1
		else:
			strategy = 2
		statistics[strategy][key_value_of_data[0]].append(record[key_value_of_data[0]]) # we add configuration (TRPS) string in C or D side of the map

		#### guilt ####	
		omega = sum(record[key_value_of_data[4]].values())
		## count		
		for guilt_lvl, guilt_weight in record[key_value_of_data[4]].iteritems():
			### guilt scale ###
			## min
			if float(guilt_lvl) < statistics[strategy][1][0]:
				statistics[strategy][1][0] = float(guilt_lvl)
			## max
			if float(guilt_lvl) > statistics[strategy][1][1]:
				statistics[strategy][1][1] = float(guilt_lvl)
			## sum
			statistics[strategy][1][3] += float(guilt_lvl)*(float(guilt_weight)/omega)
			## count
			statistics[strategy][1][5] += (float(guilt_weight)/omega)

		#### gain ####
		## min
		if float(record[key_value_of_data[6]]) < statistics[strategy][0][0]:
			statistics[strategy][0][0] = float(record[key_value_of_data[6]])
		## max
		if float(record[key_value_of_data[7]]) > statistics[strategy][0][1]:
			statistics[strategy][0][1] = float(record[key_value_of_data[7]])
		## sum
		statistics[strategy][0][3] +=  float(record[key_value_of_data[5]])
		## count
		statistics[strategy][0][5] += number_of_agent

		#### iteration ####
		## min
		if float(record[key_value_of_data[8]]) < statistics[strategy][2][0]:
			statistics[strategy][2][0] = float(record[key_value_of_data[8]])
		## max
		if float(record[key_value_of_data[8]]) > statistics[strategy][2][1]:
			statistics[strategy][2][1] = float(record[key_value_of_data[8]])
		## sum
		statistics[strategy][2][3] += float(record[key_value_of_data[8]])
		## count
		statistics[strategy][2][5] += 1
	for key in [1,2]:
		for stat_type in computed_stat.keys():
			if(statistics[key][stat_type][5] != 0):
				## mean
				statistics[key][stat_type][2] = round(float(statistics[key][stat_type][3]) / statistics[key][stat_type][5], 2)
				## std-dev
				statistics[key][stat_type][4] = round( sqrt( abs(float(statistics[key][stat_type][3]) - (statistics[key][stat_type][5] * statistics[key][stat_type][2])) ) ,4)
			else:
				statistics[key][stat_type][2] = 0
				statistics[key][stat_type][4] = 0

	path = "" # no need to specify any path yet.
	from pygal.style import LightStyle

	# Gains chart
	gain_chart = pygal.Bar(fill=True, interpolate='cubic', style=LightStyle)
	gain_chart.title = 'Gains knowing strategy types'
	gain_chart.x_labels = map(str, ["Cooperative ("+str(int(statistics[1][0][5]))+" agt)","Non-cooperative ("+str(int(statistics[2][0][5]))+" agt)"])
	gain_chart.add('Min',  [statistics[1][0][0], statistics[2][0][0]])
	gain_chart.add('Mean', [statistics[1][0][2], statistics[2][0][2]])
	gain_chart.add('Max',  [statistics[1][0][1], statistics[2][0][1]])
	#gain_chart.add('Std-dev',  [statistics[1][0][4], statistics[2][0][4]])
	gain_chart.render_to_file(path+"/gains_with_"+file_name+".svg")

	gain_chart = pygal.Bar(fill=True, interpolate='cubic', style=LightStyle)
	gain_chart.title = 'Sum of gains knowing strategy types'
	gain_chart.x_labels = map(str, ['Cooperative ('+str(int(statistics[1][0][5]))+' agt)','Non-cooperative ('+str(int(statistics[2][0][5]))+' agt)','Both ('+str(int(statistics[1][0][5])+int(statistics[1][0][5]))+' agt)'])
	gain_chart.add("", [statistics[1][0][3], statistics[2][0][3], statistics[1][0][3]+statistics[2][0][3]])
	gain_chart.render_to_file(path+"/sum_gains_with_"+file_name+".svg")

	# Strat dominance chart
	strat_chart = pygal.Pie(fill=True, interpolate='cubic', style=LightStyle)
	strat_chart.title = 'Strategy who prevail'
	strat_chart.x_labels = map(str, ["Strategy prevailance among all configurations"])
	strat_chart.add('Absolute cooperation',  statistics[1][0][5])
	strat_chart.add('Absolute defection',  statistics[2][0][5])
	strat_chart.render_to_file(path+"/strat_prev_with_"+file_name+".svg")

	# Guilt repartition : min max mean... knowing C and D	
	guilt_rep_chart = pygal.Bar(fill=True, interpolate='cubic', style=LightStyle)
	guilt_rep_chart.title = 'Global repartition of guilt knowing strategies'
	guilt_rep_chart.x_labels = map(str, ["Cooperative ("+str(int(statistics[1][0][5]))+" agt)","Non-cooperative ("+str(int(statistics[2][0][5]))+" agt)","Both"])
	guilt_rep_chart.add('Min',  [statistics[1][1][0],statistics[2][1][0],min(statistics[1][1][0],statistics[2][1][0])])
	guilt_rep_chart.add('Mean', [statistics[1][1][2],statistics[2][1][2], (statistics[1][1][2] + statistics[2][1][2]) / 2])
	guilt_rep_chart.add('Max',  [statistics[1][1][1],statistics[2][1][1],max(statistics[1][1][1],statistics[2][1][1])])
	guilt_rep_chart.add('Std-dev',  [statistics[1][1][4], statistics[2][1][4], (statistics[1][1][4] + statistics[2][1][4]) / 2])
	guilt_rep_chart.render_to_file(path+"/guilt_rep_with_"+file_name+".svg")

	# Iteration chart
	iter_chart = pygal.Bar(fill=True, interpolate='cubic', style=LightStyle)
	iter_chart.title = 'Global iterations'
	iter_chart.x_labels = map(str, ["Iterations"])
	iter_chart.add('Min',  [ min([statistics[1][2][0], statistics[2][2][0]]) ] )
	iter_chart.add('Mean', [ (statistics[1][2][2] + statistics[2][2][2]) / 2 ] )
	iter_chart.add('Max',  [ max(statistics[1][2][1], statistics[2][2][1]) ] )
	iter_chart.render_to_file(path+"/iteration_chart_"+file_name+".svg")

# For now in sequential exp results in Pure strategy we have the following elements :
## 	Value::T R P S 		C::NumberOfCooperators		D::NbOfDefectors		IdealRepartition::[key1,key2,...]:[val1,val2]
## 	GuiltRep::[key1,...]:[val1,...]		SumPayOffs::Float		MinPayOffs::Float		MaxPayOffs::Float		Iteration::NbOfIteration
# We want to do some chart that could be interesting for observations. What could be interesting :

# -> Dominant strategy (C or D) % of dominance among experiences
# -> Global PayOffs of C strategy vs the other (max, min, mean and e-type) when they prevail
# (-> Min, max, mean and e-type global (C+D) PayOffs)
# -> GuiltRepartition :
## -> mean, max, min, e-type knowing C
## -> mean, max, min, e-type knowing D
if __name__ == '__main__':
	if len(sys.argv) == 2:
		full_path_csv_file = sys.argv[1]

		do_your_job(full_path_csv_file)
	else:
		print("Wrong number of argument (1 arg is expected). It should be : something.csv file")