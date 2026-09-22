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

    command1="run_proxy_tcp \"$TARGET\" 80"
    command2="run_proxy_tcp \"$TARGET\" 443"
    command3="run_proxy_tcp \"$TARGET\" 25565"
    command4="run_proxy_udp \"$TARGET\" 8024454"
    
    # Run commands in the background
    $command1 &
    pid1=$!
    $command2 &
    pid2=$!
    $command3 &
    pid3=$!
    $command4 &
    pid4=$!

    echo "Processes started with PIDs: $pid1, $pid2, $pid3 and $pid4, and targeting $TARGET. Use kill -9 $pid1 $pid2 $pid3 $pid4 to stop."
}

run_proxy_tpc() {
	while true
	do
		sudo socat TCP4-LISTEN:$2,fork,su=nobody,reuseaddr "TCP6:[$1]:$2"
		echo "Proxy died! Restarting in 5s..."
		sleep 5;
	done
}

run_proxy_upd() {
	while true
	do
		sudo socat UDP4-LISTEN:$2,fork,su=nobody,reuseaddr "UDP6:[$1]:$2"
		echo "Proxy died! Restarting in 5s..."
		sleep 5;
	done
}

if [ ! -f "target.txt" ]; then
    echo "No target.txt found! Create one with the target domain."
	exit 1;
fi

start_processes