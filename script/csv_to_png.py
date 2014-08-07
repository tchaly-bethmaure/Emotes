#! /usr/bin/python
# -*- coding: utf-8 -*-
# Developped with python 2.7.3
import png
import os

# Script a bit trash, but useful

### Aim : verify if given configurations of prisonner dilemma satisfies given conditions.
## Input : 
# -> a list of prisonner dilemma configurations (ex : 4 3 2 1) separated by \n ascii char
# -> a list of conditions (ex : 2*P > T+S) also separated by \n char
## Ouput :
# -> a report file contains for instance : 4 3 2 1 not satisfy 2*P > T+S

## Note :
# I choosed to formalise a prisonner dilemma configuration as it : (Traitor)4 (Reward)3 (Punishment)2 (Sucks)1, each value is separated by a space.
def string_rgbhex_to_lst_rgbdec(strRGBHEX):
    # strRGB ex : FFFFFF
    if len(strRGBHEX) == 6:
        return [give_dec_code(strRGBHEX[0] + strRGBHEX[1]),
                give_dec_code(strRGBHEX[2] + strRGBHEX[3]),
                give_dec_code(strRGBHEX[4] + strRGBHEX[5])]
    else:
        return [0, 0, 0]


def give_dec_code(str_as_hex):
    #str_as_hex ex: FF or 00
    if str_as_hex == "FF":
        return 255
    if str_as_hex == "00":
        return 0

def convert_to_RGB(path):
    zoom = 8;
    dir = path
    # Read a configuration_file_generated_by_expSequential.gaml_experiment_file.csv ... :D
    for file in os.listdir(dir):
        if file.endswith(".csv"):
            with open(dir+"/"+file,'r') as fichier:
                print("Parsing : "+file+" ...")
                line = ""
                pixel_col = []
                # Read each line of the file
                for ligne in fichier.readlines():
                    pixel_line = []
                    # line of pixels separated by a ';' ex : FF00FF;FFFFFF;FF0000; ... etc
                    line = ligne.strip("\t\r\n")
                    pixelHEX_tab = line.split(";")
                    # A pixel is symbolized with 6 hex chars ...
                    for pixelHex in pixelHEX_tab:
                        if pixelHex != "":
                            for i in range(zoom):
                                # Convert Hex-RGB-code to non-hex-RGB code 
                                pixel_line.extend(string_rgbhex_to_lst_rgbdec(pixelHex))
                    for i in range(zoom):
                        pixel_col.append(pixel_line)
                print("OK.")

                # Creating Png file
                filename = file.replace(".csv",".png")
                fichier.close()
                print("Writing : "+filename+" ...")
                f = open(dir+"/png/"+filename, 'wb')
                w = png.Writer(len(pixel_col), len(pixel_col))
                w.write(f, pixel_col)
                f.close()
                print("OK.")
    print("Done.")

path = raw_input("Path ?")
convert_to_RGB(path)
