import tools

freq = [0.25,0.10,0.40,0.25]
val = [1,2,3,4]
moy=tools.esperence(freq,val)
esp=tools.std_dev(freq,val,moy)
print(moy,esp)