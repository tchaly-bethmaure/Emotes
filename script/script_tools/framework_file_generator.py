#! /usr/bin/python
# -*- coding: utf-8 -*-
# Developped with python 2.7.3

import os
import sys
import tools
import json

print("The frame :")
name = raw_input("-> name of the framework ?")
kmin = float(raw_input("-> Minimum boundary ?"))
kmax = float(raw_input("-> Maximum boundary ?"))
precision = float(raw_input("-> Precision (graduation axe) ?"))
nb_agent_per_graduation =  int(raw_input("-> Number of agent per graduation ?"))
print("\nThis script generates the population distribution automatically : nb_agent_per_graduation is mapped.") 
print("\n(!) Note : it needs to be improved by following a law (gaussian law for instance), currently it only distributes uniformly.")

i=kmin
distribution = {}
while i < kmax+precision:
	distribution[i] = nb_agent_per_graduation
	i+= precision
	i = round(i, tools.get_round_precision(precision)) # fix : python >> 0.2 * 0.4
#print json.dumps(distribution); exit()

o = open(name+".frmwrk",'w')
o.write("# A framework is described as above : \n# in following order, we define  min_boundary max_boundary precision frequences)\n")
o.write(json.dumps([kmin, kmax, precision, distribution]))
o.close()