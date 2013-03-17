#!/bin/sh

stop_control_panel
wait

imgtool --fill=0,102,204 ; fbwrite --color=255,255,255 "restarting network..."
start_network
wait

imgtool --fill=0,102,204 ; fbwrite --color=255,255,255 "restarting app..."
start_control_panel