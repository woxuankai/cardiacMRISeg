#!/bin/bash

for i in 0
do
	for j in 0 2 4 6 8 10 12 14 16 18
	do
		for k in 8 7
		do
			./run.sh -d${i} -v${j} -s${k} -j4 -n5 -m1
		done
	done
done
