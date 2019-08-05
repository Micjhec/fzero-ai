import socket
import traceback

HOST = '127.0.0.1'
PORT = 2222

class server(object):
    def __init__(self):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.bind((HOST, PORT))
        print('Hostname: %s Port: %d' % (HOST, PORT))
        s.listen()
        while True:
            try:
                print('Listening for connection...')
                self.conn, addr = s.accept()
                print('Connection established: ', addr)
                break
            except:
                # TODO: gracefully handle client closing connection
                print('Exception occurred while trying to connect:')
                print(traceback.print_exc())
                if self.conn != None:
                    self.conn.send(b'close')
                    self.conn.close()
        
    def send_line(self, line):
        try:
            self.conn.sendall((str(line) + '\n').encode())
        except:
            print('Exception occurred while sending data.')
            print(traceback.print_exc())
            self.conn.send(b'close')
            self.conn.close()

    def receive_line(self):
        line = ''
        while not line.endswith('\n'):
            data = self.conn.recv(1).decode('ascii')
            if len(data) == 0:
                raise Exception()
            line += data

        return line.strip()

    def send_buttons(self, buttons):
        self.send_line(''.join(['1' if button else '0' for button in buttons]))
                
