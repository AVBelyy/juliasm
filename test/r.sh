#!/bin/bash
make clean
make 
./dumptopng 1000 1000 aaa.png
feh aaa.png

