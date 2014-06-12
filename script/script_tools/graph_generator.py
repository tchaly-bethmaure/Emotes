import networkx as nx
import sys
import matplotlib
import re
import os

# A Graph generator, using networkx library and matplotlib
# not realy powerful but could be useful to draw a graph based
# on a file (see examples/graph.example file) and output an image file. 

file_name = sys.argv[1]

def test():
	regexp_node = "n\(([\w\s]*)\)"
	regexp_edge = "e\(([\w\s]*),\s?([\w\s]*)\)"
	node_list = []
	edge_list = []

	for line in open(file_name):
			if line[0] != "#" and not re.match("^\s$", line):
				# nodes
				node_list += re.findall(regexp_node, line)
				# edges
				edge_list += re.findall(regexp_edge, line)
	print node_list
	print edge_list

def draw_by_file(file_name, save_file=0):
	regexp_node = "n\(([\w\s]*)\)"
	regexp_edge = "e\(([\w\s]*),\s?([\w\s]*)\)"
	node_list = []
	edge_list = []

	for line in open(file_name):
			if line[0] != "#" and not re.match("^\s$", line):
				# nodes
				node_list += re.findall(regexp_node, line)
				# edges
				edge_list += re.findall(regexp_edge, line)
	draw(node_list, edge_list, file_name)

def draw_by_string(string):
	# TODO
	pass

def draw(node_list, edge_list, file_name="None"):
	full_path = file_name
	file_name = (file_name.split("/")).pop()
	full_path = full_path.replace(file_name, "")

	# Our graph
	G = nx.DiGraph()

	for node in node_list:
		G.add_node(node)
	for edge_tuple in edge_list:
		G.add_edge(edge_tuple[0], edge_tuple[-1])

	# We draw it 
	nx.draw(G)

	# Save the graph as ps
	# # matplotlib.pyplot.savefig("results/"+file_name+".png")
	# Graphviz as prettier rendering than pyplot so we generates also a .dot
	nx.draw_graphviz(G)
	matplotlib.pyplot.close()
	dot_file = full_path+"results/"+file_name+'.dot'
	nx.write_dot(G, dot_file)
	os.system("dot -Tps "+dot_file+" -o "+full_path+"results/"+file_name+".ps") # vectorial img file

	

if __name__ == "__main__":
	if len(sys.argv) >= 2:		
		if len(sys.argv) >= 4:
			draw_by_file(sys.argv[1], sys.argv[2])
		else:
			draw_by_file(sys.argv[1])
	else:
		draw(["hello there","hi_there"],[("hello there", "hi_there")])