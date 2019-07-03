
server_addr = 'localhost';
server_port = 12001;

client = tcpip(server_addr, server_port);
fopen(client);
fwrite(client, 'Hello world!\n');
fclose(client);
