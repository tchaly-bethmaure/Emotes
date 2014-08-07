import sys

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'

def get_round_precision(number):
	return len(str(int(1/number))) - 1

def m_replace(tab, replaceBy, strToReplace):
	for val in tab:
		strToReplace = strToReplace.replace(val,replaceBy)
	return strToReplace	

# read file of type csv but with ignore hatched # (commented) line
def read_specific_file(file_name, file_type):	
	f = open(file_name, 'r')
	tab = []
	# loading data
	for line in f:
		if line[0] != "#" and line:
			# make a switch if more than two file types are.
			if file_type != "conf":
				tab.append((line.replace("\n","")))
			else:
				tab.append((line.replace("\n","")).split(' '))

	f.close()
	return tab

class pyMap:	

	def __init__(self):
		self.indices = []
		self.values = []

	def add_i(self, index):
		if index not in self.indices:
			# add our index value
			self.indices.append(index)

	def add_v(self, index, value):
		self.add_i(index)
		
		i = self.indices.index(index)
		# create a list at the slot i if this is not done yet
		if i >= len(self.values):
			self.values.append([])
		# add the value ...
		self.values[i].append(value)

	def delete_i(self, index):
		# looking for the index in indicies
		if index in self.indices:
			# if found, delete it then delete its values associated array
			i = self.indices.index(index)
			self.indices.remove(index)
			self.values.pop(i) # we drop the array
			return True
		return False

	def delete_v(self, index, value):
		# does index is contained in indices
		if index in self.indices:
			i = self.indices.index(index)
			# does value is in the array associated with index ?
			if value in self.values[i]:
				self.values[i].remove(value) # we remove the value
				return True
		return False

	def get_values(self, index):
		if index in self.indices:
			i = self.indices.index(index)
			return self.values[i]
		return []	

	def get_index_of_value(self, value):
		find = False
		i = 0
		j = -1
		while not find and len(self.values) > i:
			if value in self.values[i]:
				j = i
				find = True
			i+=1
		return j

	def get_key_of_value(self, value):
		return self.indices[self.get_index_of_value(value)]

	def get_index_of_value_in_list(self, value):
		find = False
		i = 0
		j = -1
		while not find and len(self.values) > i:
			if value in self.values[i]:
				j = self.values[i].index(value)
				find = True
			i+=1
		return j

	def display(self):
		print "Keys: " + str(self.indices) + "\n Values: " + str(self.values)

def test_pyMap():
	m = pyMap()
	m.add_i("hello")
	m.add_v("hello","hi")
	m.add_v("hello","bonjour")
	m.add_v("hello","allo")
	m.add_v("hello","bonjour")
	print m.get_key_of_value("allo")
	m.display()

	m.delete_v("hello","hi")
	m.display()

	m.delete_i("hello")
	m.display()

if __name__ == '__main__':
	test_pyMap()