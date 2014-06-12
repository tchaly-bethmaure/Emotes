import os
import sys
import re

## Aim : list every regexp_matching_files into a file.
## Input : a path containing desired regexp files to be listed in the file
## Ouput : a file containing the list of regexp_matching_files

# Note : I probably not resolve It in an optimal way.

# check if the specified file path is a directory
def is_a_folder(folder_full_path):
    if os.path.isdir(folder_full_path):
        return True
    else:
        self.print_output_msg("Not a folder.")

def filter_files(file_pattern, folder):
	# we list files in folder
	files = os.listdir(folder)
	# files = ["Coucou", ":)", "MesVacances.png","FichierFiltre.png","configuration_4 3 2 1.png"]

	# we keep only files matching file_pattern
	files_matching = []
	for str_file in files:
		if(re.match(file_pattern, str_file)):
			files_matching += re.findall(file_pattern, str_file)
	return files_matching

def main():
	regexp = "configuration_(.*)\.png"
	if(len(sys.argv) <= 1):
		print "Error : please indicate the path where to find configurations' png files."
		exit()
	path = str(sys.argv[1])
	if(path[len(path) - 1] != "/"):
		path += "/"

	if(is_a_folder(path)):
		# get files in folder that are matching regexp
		configurations = filter_files(regexp, path)

		if len(configurations) != 0:
			# creating configuration file
			# - we ask how we should name the file
			file_name = raw_input("-> file name ?")
			# - we now write the file
			f = open(path+file_name, "w")
			f.write("# File listing prisonners dilemma configurations.\n")
			f.write("# Auto-generated file based on " + path + ".\n")
			for config in configurations:
				f.write(config+"\n")
		else:
			print "/!\ No file matching."
		# We got it !

if __name__ == '__main__':
	main()