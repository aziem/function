#!/bin/bash

# Default is to repeat each benchmark 5 times. 
NUMRUNS=${1:-5}
MULTITIME=/usr/local/bin/multitime
APRONORIGLOC=$HOME/apron-20160125
APRONAPLASLOC=$HOME/apron-aplas
APRONKENTLOC=$HOME/apron-kent

files=${ls ./tests/*.c)
currentdir=`pwd`

compile_hash () {
    echo "Compiling CoDBM Hash"
    cd ${APRONKENTLOC}/octagons; ./patchseqnostrong.sh; cd ..
    make clean && make -j 30 &&./reinstall-apron.sh
    cd $currentdir
}

compile_join_opt () {
    echo "Compiling CoDBM Hash + Join opt"
    cd ${APRONKENTLOC}/octagons; ./patchseqnostrong-joinopt.sh; cd ..
    make clean && make -j 30 &&./reinstall-apron.sh
    cd $currentdir
}

compile_hash_opt () {
    echo "Compiling CoDBM Hash + Join + Close Opt"
    cd ${APRONKENTLOC}/octagons; ./patchseqnostrong-floydopt.sh; cd ..
    make clean && make -j 30 &&./reinstall-apron.sh
    cd $currentdir
}

compile_aplas () {
    echo "Compiling APLAS CoDBM"
    cd $APLASAPRONLOC; make clean;
    ./configure --no-ppl --no-java && make -j 30 && ./reinstall-apron.sh
    cd $currentdir
}

compile_apron_orig () {
    echo "Compiling Apron Original"
    cd $APRONORIGLOC; make clean;
    ./configure --no-ppl --no-java && make -j 30 && ./reinstall-apron.sh
    cd $currenddir
}

rebuild_function () {
    make clean; make
}

build_function_double () {
    make clean; ./patchdouble.sh; make
}

build_function_mpq () {
    make clean; ./patchmpq.sh; make
}

run_benchmark () {
    # Argument 1 is the apron implementation: apron, aplas, hash, join, hashopt
    # Argument 2 is either mpq or dbl (the number system to use)
    echo "Running benchmarks $1"
    for f in $files; do
	echo "Running on file $f"
	$MULTITIME -n $NUMRUNS -q ./function $f -termination -domain octagons -joinbwd 2 -retrybwd 5 &> $f.multitime.$2.$1
	# get the mean time
	cat $f.multitime.$2.$1 | grep -A1 user | awk '{print $2}' | awk '{sum+=$1} END {print sum}' > ${f}.$1-mpq-mean.txt
	# get the median time
	cat $f.multitime.$2.$1 | grep -A1 user | awk '{print $5}' | awk '{sum+=$1} END {print sum}' > ${f}.$1-mpq-median.txt
    done
}

process_results () {
    echo "Processing results for $1"
    for f in $files; do
	paste <(cat $f) ${f}.apron-mpq-mean.txt  ${f}.aplas-mpq-mean.txt ${f}.hash-mpq-mean.txt ${f}.join-mpq-mean.txt ${f}.hashopt-mpq-mean.txt >> overall-results-mpq-mean.txt
	paste <(cat $f) ${f}.apron-dbl-mean.txt  ${f}.aplas-dbl-mean.txt ${f}.hash-dbl-mean.txt ${f}.join-dbl-mean.txt ${f}.hashopt-dbl-mean.txt >> overall-results-dbl-mean.txt
    done
}

# Run the MPQ benchmarks first followed by the double benchmarks

compile_apron_orig
build_function_mpq
run_benchmark apron mpq
build_function_double
run_benchmark apron dbl

compile_aplas
build_function_mpq
run_benchmark aplas mpq
build_function_double
run_benchmark aplas dbl

compile_hash
build_function_mpq
run_benchmark hash mpq
build_function_double
run_benchmark hash dbl

compile_join_opt
build_function_mpq
run_benchmark join mpq
build_function_double
run_benchmark join dbl

compile_hash_opt
build_function_mpq
run_benchmark hashopt mpq
build_function_double
run_benchmark hashopt dbl

# Now process the results
process_results

