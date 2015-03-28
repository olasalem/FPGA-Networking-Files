// UDP receiver
// adapted from http://www.district86.k12.il.us/central/activities/computerclub/Tutorials/Winsock/Lesson5.htm

#include <winsock.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#pragma comment (lib, "wsock32.lib")

int main(int argc, int **argv)
{
   WSADATA wsda;
   SOCKET s;
   SOCKADDR_IN addr, remote_addr;
   u_short iPort = 1024;
   int i, ret, iRemoteAddrLen;
   char hex[16] = "0123456789ABCDEF";
   char szMessage[512], szMessageString[512*3];

   WSAStartup(MAKEWORD(1,1), &wsda);
   s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

   if(s == SOCKET_ERROR)
   {
      printf("Error\nCall to socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP); failed with:\n%d\n", WSAGetLastError());
      exit(1);
   }

   addr.sin_family = AF_INET;
   addr.sin_port = htons(iPort);
   addr.sin_addr.s_addr = INADDR_ANY;

   if(bind(s, (struct sockaddr *) &addr, sizeof(addr)) == SOCKET_ERROR)
   {
      printf("Error\nCall to bind(s, (struct sockaddr *) &addr, sizeof(addr)); failed with:\n%d\n", WSAGetLastError());
      exit(1);
   }

   printf("Waiting for packets (Press Ctrl-C to exit)...\n");
   while(1)
   {
	   iRemoteAddrLen = sizeof(remote_addr);
	   ret = recvfrom(s, szMessage, sizeof(szMessage), 0, (struct sockaddr *) &remote_addr, &iRemoteAddrLen);

	   if(ret == SOCKET_ERROR)
	   {
		  printf("Error\nCall to recvfrom(s, szMessage, sizeof(szMessage), 0, (struct sockaddr *) &remote_addr, &iRemoteAddrLen); failed with:\n%d\n", WSAGetLastError());
		  exit(1);
	   }

	   for(i=0; i<ret; i++)
	   {
		   szMessageString[i*3+0] = hex[szMessage[i]>>4];
		   szMessageString[i*3+1] = hex[szMessage[i]&0xF];
		   szMessageString[i*3+2] = ' ';
	   }
	   szMessageString[i*3-1] = 0;

	   printf("Received %d bytes from %s\n", ret, inet_ntoa(remote_addr.sin_addr));
	   printf("%s \n", szMessageString);
   }

   closesocket(s);
   WSACleanup();

   return 0;
}
