python memtest.py &
PID=$!
watch -n 1 ./memmonitor.py $PID
kill -15 $PID
