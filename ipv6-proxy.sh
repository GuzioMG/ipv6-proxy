#!/bin/bash

set -euo pipefail

start_processes() {
    echo "Starting proxy..."
    TARGET=$(dig +short AAAA "$(cat target.txt)" | head -n1)

	if [ -z "$TARGET" ]; then
    	echo "Target was empty! Full DIG result:"
		dig AAAA "$(cat target.txt)"
		exit 1;
	fi

    # Run commands in the background
    run_proxy_tcp "$TARGET" 80 &
    pid1=$!
    run_proxy_tcp "$TARGET" 443 &
    pid2=$!
    run_proxy_tcp "$TARGET" 25565 &
    pid3=$!
    run_proxy_udp "$TARGET" 24454 &
    pid4=$!

    echo "Processes started with PIDs: $pid1, $pid2, $pid3 and $pid4, and targeting $TARGET. Use kill -9 $pid1 $pid2 $pid3 $pid4 to stop and cat logs.txt to inspect."
}

run_proxy_tcp() {
	while true
	do
		echo "TCP proxy to [$1]:$2 started.";
		socat TCP4-LISTEN:$2,fork,su=nobody,reuseaddr "TCP6:[$1]:$2"
		echo "$(date): TCP proxy to [$1]:$2 died! Restarting in 5s...";
		sleep 5;
	done
}

run_proxy_udp() {
	while true
	do
		echo "UDP proxy to [$1]:$2 started.";
		socat UDP4-LISTEN:$2,fork,su=nobody,reuseaddr "UDP6:[$1]:$2"
		echo "$(date): UDP proxy to [$1]:$2 died! Restarting in 5s...";
		sleep 5;
	done
}

if [ ! -f "target.txt" ]; then
    echo "No target.txt found! Create one with the target domain."
	exit 1;
fi

start_processes > logs.txt & disown
sleep 3;
cat logs.txt
exit 0;