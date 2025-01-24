import usocket as socket
import ustruct
import ujson

class WebSocket:
    def __init__(host, port):
        self.socket = usocket.socket(usocket.AF_INET, usocket.SOCK_STREAM)
        print(host, port)
        self.socket.connect((host, port))
    
    def send_handshake():
        request = "GET / HTTP/1.1\r\n"
        request += "Host: {0}:{1}\r\n".format(server_ip, server_port)
        request += "Connection: Upgrade\r\n"
        request += "Upgrade: websocket\r\n"
        request += "\r\n"
        self.socket.send(request.encode())
    
    def emit(event, data):
        message = {
            'event' : event,
            'data' : data
        }
        
        self.socket.send(ustruct.pack("B", len(message)) + ujson.dumps(message).encode())
    
    def on(event, handler):
        pass
    
    
        
