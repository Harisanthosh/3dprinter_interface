#!/bin/bash

# Script als Machbarkeitsstudie zum Automatischen Erstellen eines 3D Drucks aus von extern erhaltenen (nicht 3D) Daten.
# Autor: Sebastian Setz, Sebastian@Setz.name
# Änderungen durch: Manuel Grote
# letzte Änderung 26.11.18
# Erforderliche Software:
  # 1. octopi image 0.14, https://github.com/guysoft/OctoPi/releases/tag/0.14.0
  # 2. openscad, inkscape, pstoedit, pip (sudo apt-get -y install inkscape openscad pstoedit python-pip)
  # 3. octocmd, https://octocmd.readthedocs.io/en/latest/# (sudo pip install https://github.com/vishnubob/octocmd/archive/master.zip)
  #     "octocmd init" ausführen, IP und API Key eintragen
  #     octocmd anpassen, cura zu cura_engine ändern (sudo nano /usr/local/bin/octocmd)
  # 4. Skript mit
  #     sh create4.sh "NAME" "STRASSE HAUSNUMMER" "PLZ STADT" "LAND" LOGONUMMER SERIENNUMMER
  #     Beispiel: sh create4.sh "Max Muster" "Constantiaplatz 4" "26723 Emden" "Germany" 1 1234567
  # 5. Status mittels "octocmd status"
#
# Changelog
# 181204, Sebastian Setz, Optionen fuer Slicing eingefuegt


NAME=$1
STREET=$2
CITY=$3
COUNTRY=$4
LOGO=$5
SERIALNUMBER=$6
echo " "
echo "Erhaltene Daten:"
echo "--------------------------------------------------"
echo "Name:         "$NAME
echo "Street:       "$STREET
echo "City:         "$CITY
echo "Country:      "$COUNTRY
echo "Logo:         "$LOGO
echo "Serialnumber: "$SERIALNUMBER"\n"

# eingefuegt von ***
cd /home/pi/joseb

rm -r data/$SERIALNUMBER
mkdir data/$SERIALNUMBER

# create SVG, https://stackoverflow.com/questions/7680504/sed-substitution-with-bash-variables
echo "\nCreating .svg"
cp data/template.svg data/$SERIALNUMBER/rohling.svg

sed -i -e "s/NAME/$NAME/g" data/$SERIALNUMBER/rohling.svg
sed -i -e "s/STREET/$STREET/g" data/$SERIALNUMBER/rohling.svg
sed -i -e "s/CITY/$CITY/g" data/$SERIALNUMBER/rohling.svg
sed -i -e "s/COUNTRY/$COUNTRY/g" data/$SERIALNUMBER/rohling.svg
echo "... OK.\n"


# SVG to EPS (https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Other_2D_formats | https://inkscape.org/de/doc/inkscape-man.html)
echo "Export .eps from .svg"
inkscape -T -E data/$SERIALNUMBER/rohling.eps data/$SERIALNUMBER/rohling.svg
echo "... OK.\n"


# EPS to DXF (https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Other_2D_formats)
echo "Converting .eps to .dxf"
pstoedit -dt -f dxf:-polyaslines\ -mm data/$SERIALNUMBER/rohling.eps data/$SERIALNUMBER/rohling.dxf
echo "... OK.\n"


# DXF extrude in OpenScad (https://reprap.org/forum/read.php?313,627739)
echo "Creating .stl"
ln -f data/$SERIALNUMBER/rohling.dxf data/link.dxf
openscad -o data/$SERIALNUMBER/rohling.stl data/dxf2stl.scad
rm data/link.dxf
echo "... OK.\n"


# STL to GCODE
echo "Creating .gcode"
cura_engine -v -p -s startCode M115 U3.4.1 ; tell printer latest fw version
M83  ; extruder relative mode
M104 S[first_layer_temperature] ; set extruder temp
M140 S[first_layer_bed_temperature] ; set bed temp
M190 S[first_layer_bed_temperature] ; wait for bed temp
M109 S[first_layer_temperature] ; wait for extruder temp
G28 W ; home all without mesh bed level
G80 ; mesh bed leveling
G1 Y-3.0 F1000.0 ; go outside print area -o data/$SERIALNUMBER/$SERIALNUMBER.gcode data/$SERIALNUMBER/rohling.stl
echo "... OK.\n"


# https://github.com/vishnubob/octocmd
echo "upload, select and print .gcode"
octocmd upload data/$SERIALNUMBER/$SERIALNUMBER.gcode
octocmd select $SERIALNUMBER.gcode
octocmd print $SERIALNUMBER.gcode
echo "... OK.\n"
echo "--------------------------------------------------"
echo " "
#rm -r data/$SERIALNUMBER

cd /home/pi/Desktop/rhaudi-transfactrestclient-3dcf739c5711/transfactclient

# Beispiel aus Octoprint Log:
# cura_engine -v -p
# -s coolHeadLift=0
# -s downSkinCount=5
# -s enableCombing=0
# -s endCode=;End GCode
#     \nM104 S0                      ;extruder heater off
#     \nM140 S0                      ;heated bed heater off (if you have it)
#     \nG91                          ;relative positioning
#     \nG1 E-1 F300                  ;retract the filament a bit before lifting the nozzle, to release some of the pressure
#     \nG1 Z+0.5 E-5 X-20 Y-20 F9000 ;move Z up a bit and retract filament even more
#     \nG28 X0 Y0                    ;move X/Y to min endstops, so the head is out of the way
#     \nM84                          ;steppers off
#     \nG90                          ;absolute positioning
#     \n
# -s extrusionWidth=400.0
# -s fanFullOnLayerNr=14
# -s fanSpeedMax=100
# -s fanSpeedMin=60
# -s filamentDiameter=1750
# -s filamentFlow=90
# -s fixHorrible=0
# -s gcodeFlavor=0
# -s infillOverlap=15
# -s infillSpeed=80
# -s initialLayerSpeed=40
# -s initialLayerThickness=300
# -s initialSpeedupLayers=4
# -s inset0Speed=40
# -s insetCount=2
# -s insetXSpeed=80
# -s layer0extrusionWidth=400
# -s layerThickness=200
# -s minimalExtrusionBeforeRetraction=20
# -s minimalFeedrate=15
# -s minimalLayerTime=12
# -s moveSpeed=150
# -s multiVolumeOverlap=200
# -s objectSink=0
# -s perimeterBeforeInfill=0
# -s postSwitchExtruderCode= ;Switch between the current extruder and the next extruder, when printing with multiple extruders.
#     \n                     ;This code is added after the T(n)
#     \n
# -s posx=100000
# -s posy=100000
# -s preSwitchExtruderCode= ;Switch between the current extruder and the next extruder, when printing with multiple extruders.
#     \n                    ;This code is added before the T(n)
#     \n
# -s printSpeed=50
# -s retractionAmount=1400
# -s retractionAmountExtruderSwitch=16500
# -s retractionMinimalDistance=1500
# -s retractionSpeed=40
# -s retractionZHop=0
# -s skinSpeed=50
# -s skirtDistance=3000
# -s skirtLineCount=1
# -s skirtMinLength=150000
# -s sparseInfillLineDistance=1600
# -s startCode=M140 S60.0
    # \nM109 T0 S215.0
    # \nT0
    # \nM190 S60.0
    # \n;Sliced at: Tue 04-12-2018 09:52:13
    # \n;Basic settings: Layer height: 0.2 Walls: 0.8 Fill: 25
    # \n;Print time: ?print_time?
    # \n;Filament used: ?filament_amount?m ?filament_weight?g
    # \n;Filament cost: ?filament_cost?
    # \nG21            ;metric values
    # \nG90            ;absolute positioning
    # \nM107           ;start with the fan off
    # \nG28 X0 Y0      ;move X/Y to min endstops
    # \nG28 Z0         ;move Z to min endstops
    # \nG1 Z15.0 F9000 ;move the platform down 15mm
    # \nG92 E0         ;zero the extruded length
    # \nG1 F200 E10    ;extrude 3mm of feed stock
    # \nG92 E0         ;zero the extruded length again
    # \nG1 F9000
    # \nM117 Printing...
    # \n
# -s supportAngle=-1
# -s supportEverywhere=0
# -s supportExtruder=0
# -s supportLineDistance=2666
# -s supportXYDistance=700
# -s supportZDistance=150
# -s upSkinCount=5
# -o test.gcode
# test.stl
