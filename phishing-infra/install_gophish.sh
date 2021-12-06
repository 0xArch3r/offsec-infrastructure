#!/bin/bash
until [[ -f /var/lib/cloud/instance/boot-finished ]]
do 
    sleep 1
done

# Update Ubuntu System
echo "[+] Started Apt Update"
sudo apt update &> /dev/null
echo "[+] Started Apt Upgrade"
sudo apt upgrade -y &> /dev/null

# Install GoLang
echo "[+] Starting Go Lang Install"
sudo apt install golang net-tools -y &> /dev/null

# Install Go Phish Software
echo "[+] Installing GoPhish"
go get github.com/gophish/gophish &> /dev/null
cd go/src/github.com/gophish/gophish

go build &> /dev/null


