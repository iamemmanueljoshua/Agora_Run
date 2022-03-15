# run script in Agora's top-level directory
# test_hw.sh [client output file] [base station output file] [threshold BER value]
#!/bin/bash
​
ue_out_file=$1
bs_out_file=$2
threshold=$3
​
if [ -z "$3" ]; then
{
    threshold="0.005"
}
fi
​
echo "==========================================="
echo "Build cmake... with -DUSE_ARGOS=on -DUSE_UHD=off"
echo "==========================================="
cmake -S ./ -B ./build -DUSE_ARGOS=on -DUSE_UHD=off
echo -e "-------------------------------------------------------\n\n\n"
​
echo "==========================================="
echo "execute make"
echo "==========================================="
make -j -C ./build
echo -e "-------------------------------------------------------\n\n\n"
​
echo "==========================================="
echo "Generating data for test"
echo "==========================================="
./build/data_generator --conf_file data/ue-ul-hw.json
echo -e "-------------------------------------------------------\n\n\n"
​
echo "==========================================="
echo "Starting clients"
echo "==========================================="
echo -e "-------------------------------------------------------\n\n\n"
​
for i in 1 2 3; do
{  # try to start radio at most three times
​
    ./build/user data/ue-ul-hw.json > $ue_out_file &
    pid=$!
    sleep 1
    timeout 8 tail -f -n0 $ue_out_file | grep -qe "radio start done!"
    if [ $? != 0 ]; then
        if [ $i == 3 ]; then
            echo "==========================================="
            echo "cannot start radio, exiting..."
            echo "==========================================="
            kill $pid >/dev/null
            exit
        fi
        echo "==========================================="
        echo "radio did not start, trying again..."
        echo "===========================================" 
        kill $pid >/dev/null
        else
            sleep 2
            break
    fi
} done
​
echo ""
echo "==========================================="
echo "Starting base stations"
echo "==========================================="
./build/agora data/bs-ul-hw.json > $bs_out_file &
line=""
tail -f -n0 $bs_out_file | grep -qe "Agora: terminating"
​
# compare BER to threshold
BER=$(grep "(BER)" $bs_out_file | grep -oE "[0-9]\.[0-9]*")
echo ""
echo "==========================================="
echo "BER value: ${BER}"
echo "threshold: ${threshold}"
if (( $(echo "$BER > $threshold" | bc -l) )); then
    echo "test failed"
    else
        echo "test successful"
fi
echo "==========================================="
​
exit
