
import png
import os



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

def give_grey_code(str_as_hex):
    # str_as_hex ex: FF or 00
    if str_as_hex == "FF0000":
        return "0"
    if str_as_hex == "00FF00":
        return "1"

def convert_grey_with_only_RG():
    # Conversion Hex to Dec in grey depth 2
    zoom = 8;
    dir = "/home/tchaly/EspaceDeTravail/Gama/works/EMOTES/models/emotesV8/config_related_save"
    for file in os.listdir(dir):
        if file.endswith(".csv"):
            with open(dir+"/"+file,'r') as fichier:
                print("Parsing : "+file+" ...")
                line = ""
                pixel_col = []
                # Read each line of the file
                for ligne in fichier.readlines():
                    pixel_line = ""
                    # line of pixels separated by a ';' ex : FF00FF;FFFFFF;FF0000; ... etc
                    line = ligne.strip("\t\r\n")
                    pixelHEX_tab = line.split(";")
                    # A pixel is symbolized with a FFFFF hex chars
                    for pixelHex in pixelHEX_tab:
                        if pixelHex != "":
                            for i in range(zoom):
                                pixel_line += str(give_grey_code(pixelHex))
                    for i in range(zoom):
                        pixel_col.append(pixel_line)
                print("OK.")
                s = map(lambda x: map(int, x), pixel_col)

                # Creating Png file
                filename = file.replace(".csv",".png")
                fichier.close()
                print("Writing : "+filename+" ...")
                f = open("png/"+filename, 'wb')
                w = png.Writer(len(s[0]), len(s), greyscale=True, bitdepth=2)
                w.write(f, s)
                f.close()
                print("OK.")
    print("Done.")

def convert_to_RGB():
    # Conversion Hex to Dec in grey depth 2
    zoom = 8;
    dir = "/home/tchaly/EspaceDeTravail/Gama/works/EMOTES/models/emotesV8/config_related_save"
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
                    # A pixel is symbolized with a FFFFF hex chars
                    for pixelHex in pixelHEX_tab:
                        if pixelHex != "":
                            for i in range(zoom):
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

convert_to_RGB()