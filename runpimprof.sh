for bm in bc bfs cc cc_sv pr
do
    export OMP_NUM_THREADS=1 && ../pin-3.11/pin -t ../PIMProf/build/PinInstrument/PinInstrument.so -c ../PIMProf/Configs/defaultconfig.ini -o ${bm}_$1.decision.out -- ./${bm} -f ./benchmark/kron_$1.sg -n1 &
done
export OMP_NUM_THREADS=1 && ../pin-3.11/pin -t ../PIMProf/build/PinInstrument/PinInstrument.so -c ../PIMProf/Configs/defaultconfig.ini -o sssp_$1.decision.out -- ./sssp -f ./benchmark/kron_$1.wsg -n1 &
