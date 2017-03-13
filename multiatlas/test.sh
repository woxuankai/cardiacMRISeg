#!/bin/bash

for i in 0 1 2
do
	for j in 0 5 10
	do
		for k in 2 4 6
		do
			./run.sh -d${i} -v${j} -s${k} -j4 -n5 -m1
		done
	done
done
