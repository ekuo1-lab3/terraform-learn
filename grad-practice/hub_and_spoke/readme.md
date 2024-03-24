# Task

Create 3 virtual machines, each belonging to a separate virtual machine. Set up a hub and spoke model, so that traffic between the spokes is passed through the hub network. In this case, the following networks were used:

10.0.0.0/16 - hub network

10.1.0.0/16 - spoke1 network

10.2.0.0/16 - spoke2 network

# How to run

1. Replace the subscription id in variables.tf with your subscription id
2. az login (not needed if using a service principal)
3. terraform apply
4. ssh into the hub vm with "ssh adminuser@PUBLIC_IP_ADDRESS"
5. sudo edit the "/etc/sysctl.conf" file and uncomment the "net.ipv4.ip_forward=1" line to allow port forwarding
6. Set up is done!
7. To test connectivity, you can ssh into each spoke vm and try pinging the other spoke vm. 
8. Alternatively, run the test_ping.sh script to check connectivity between vms. Make sure to replace the public and private ips to the correct ones for your vms tho :) 

# Resources

https://learn.microsoft.com/en-us/azure/virtual-network/tutorial-create-route-table-portal