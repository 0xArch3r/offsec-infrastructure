#!/bin/bash

echo '[+] Starting Evilnginx2 Install'
sudo apt install git make -y &> /dev/null
git clone https://github.com/kgretzky/evilginx2.git
cd evilginx2
make