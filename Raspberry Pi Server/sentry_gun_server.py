from big_red import BigRedButton
import socket
import serial
import time
import threading
import sys

s = socket.socket()
host = '192.168.1.25'
port = 12340
s.bind((host, port))
ser = serial.Serial('/dev/ttyACM0', 9600)
time.sleep(1)
s.listen(5)

class Button(BigRedButton):

    should_send_data = False

    def start(self):
        thread = threading.Thread(target=self.run, args=())
        thread.daemon = True
        thread.start()

    def on_unknown(self):
        print 'The button is in an unknown state'

    def on_cover_open(self):
        print 'Cover open'
        ser.write('O')

    def on_cover_close(self):
        print 'The cover has been closed'
        ser.write('X90.LC')
        Button.should_send_data = False

    def on_button_release(self):
        if not Button.should_send_data:
            ser.write('TL')
            Button.should_send_data = True
        print 'The button has been released'

    def on_button_press(self):
        print 'The button has been pressed'

button = Button()
button.start()
while True:
  c, addr = s.accept()
  print('Got connection from', addr)
  while True:
      data = c.recv(2048)
      if not data: break
      print data
      if Button.should_send_data:
        ser.write(data)
  print('Connection lost')
