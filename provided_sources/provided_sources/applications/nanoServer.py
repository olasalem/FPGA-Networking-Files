from socket import *
import sys
import select
address = ('', 20698)
server_socket = socket(AF_INET, SOCK_DGRAM)
server_socket.bind(address)

print "Listening on all interface for udp port 20698"

while(1):
    recv_data, addr = server_socket.recvfrom(2048)
    print str(recv_data)+str(' from ')+str(addr)
