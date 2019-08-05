import server

serve = server.server()

while True:
    serve.send_buttons([False,True,False])

print ('done')
