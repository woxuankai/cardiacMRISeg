#!/bin/bash

./run.sh -d0 -v0 -s8 -j4 -n5 -m1
./run.sh -d0 -v9 -s7 -j4 -n5 -m1
./run.sh -d1 -v0 -s5 -j4 -n5 -m1
./run.sh -d1 -v9 -s4 -j4 -n5 -m1
./run.sh -d2 -v0 -s6 -j4 -n5 -m1
./run.sh -d2 -v9 -s7 -j4 -n5 -m1

#exit 0

for i in 0
do
	for j in 0 2 4 6 8 10 12 14 16 18
	do
		for k in 8 7
		do
			./run.sh -d${i} -v${j} -s${k} -j4 -n5 -m1
#      test -e "./output/d${i}_v${j}_s${k}-n.csv" || \
#          { ./gen_csv_atlas_selection_num_and_fusion.sh "d${i}_v${j}_s${k}" > "./output/d${i}_v${j}_s${k}-n.csv" ; }
#      test -e "./output/d${i}_v${j}_s${k}-m.csv" || \
#          { ./gen_csv_atlas_selection_method.sh "d${i}_v${j}_s${k}" > "./output/d${i}_v${j}_s${k}-m.csv" ; }
		done
	done
done

for i in 1
do
	for j in 0 2 4 6 8 10 12 14 16 18
	do
		for k in 4 5
		do
			./run.sh -d${i} -v${j} -s${k} -j4 -n5 -m1
		done
	done
done

for i in 2
do
	for j in 0 2 4 6 8 10 12 14 16 18 20 22
	do
		for k in 6 7
		do
			./run.sh -d${i} -v${j} -s${k} -j4 -n5 -m1
		done
	done
done
