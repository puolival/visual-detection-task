
listen_addr = 'localhost';
listen_port = 12001;

sck = tcpip(listen_addr, listen_port, 'NetworkRole', 'server');
fopen(sck);

while 1
    if (sck.BytesAvailable > 0)
        fprintf('CLIENT: %s\n', fread(sck, sck.BytesAvailable));
        break;
    end
end

fclose(sck);


