#!/usr/bin/env bash

# Define array of IP addresses and their corresponding identifiers
declare -A pub_ip_addresses=(
  ["vm0"]="20.191.241.238"
  ["vm1"]="20.191.240.174"
  ["vm2"]="20.191.192.116"
)

declare -A pri_ip_addresses=(
  ["vm0"]="10.0.0.4"
  ["vm1"]="10.1.0.4"
  ["vm2"]="10.2.0.4"
)

# Function to SSH into each IP and ping all other IPs
function ssh_and_ping() {
  local current_vm="$1"
  local current_ip="${pub_ip_addresses[$current_vm]}"
  for vm in "${!pub_ip_addresses[@]}"; do
    if [ "$vm" != "$current_vm" ]; then
      echo "Pinging $vm from $current_vm:"
      ssh -o "StrictHostKeyChecking no" adminuser@"$current_ip" "ping -W 1 -c 3 ${pri_ip_addresses[$vm]}"
      echo "======================================"
    fi
  done
} 

# Loop through each VM and SSH into it
for vm_name in "${!pub_ip_addresses[@]}"; do
  echo "SSHing into $vm_name ..."
  ssh_and_ping "$vm_name"
done
