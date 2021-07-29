#!/bin/bash
#-------------------------------#
# This script is a part of GASS
# reweighting codes.
#-------------------------------#
# Function to write input
function print_input() {
cat >input<<EOF
300.d0 300.d0 4.d0
1 ${1}00001
-3.14d0 3.14d0 0.10d0
-3.14d0 3.14d0 0.10d0
-3.14d0 3.14d0 0.10d0
-3.14d0 3.14d0 0.10d0
10 500
EOF
}
#-------------------------------#
# Function to write whaminput
function Write_WhamInput() {
cat >whaminput<<EOF
0.0000001
EOF
for i in `seq -3.2 0.2 3.2`;do
cat >>whaminput<<EOF
PROB/PROB_$i
$i  500  ${1}00000
EOF
done
}
#------------------------------#
# Function to run WHAM
function Run_WHAM() {
cd WHAM_2D
mv ../PROB_$1 ./PROB
cp PROB/whaminput .
./wham.x
mv free_energy PROB/free_energy_$1
mv PROB ../PROB_$1
cd ..
}
#--------------------------------#
#      Main Code                 #
#--------------------------------#
#for j in `seq 9 -1 1`;do
j=10
mkdir PROB_$j
cd ..
#--------------------------------#
for i in `seq -3.2 0.2 3.2 `; do
#------------------------#
   if [ $j -eq 10 ] 
   then
     cd GASS_$i
     mkdir ANALYSIS
     cd ANALYSIS
     print_input $j
     cp ../COLVAR.0 ./COLVAR
     cp ../HILLS.0 ./HILLS
     sed -i "/^#/d" COLVAR HILLS
     cp ../../ANALYSIS/*.x .
     ./ct.x
     ./vbias.x
     ./prob_2D.x
   else 
     cd GASS_$i
     cd ANALYSIS
     print_input $j
     ./prob_2D.x
   fi
#------------------------#
mv PROB_2D ../../ANALYSIS/PROB_$j/PROB_$i
cd ../..
echo "$i Done...";echo 
done
#--------------------------------#
cd ANALYSIS
echo "$j Done...";echo 
Write_WhamInput $j
mv whaminput PROB_$j
Run_WHAM $j
echo "WHAM done for $j."
#done
#--------------------------------#
#    Anji Babu Kapakayala        #
#--------------------------------#


