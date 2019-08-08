import server

serve = server.server()

while True:
    serve.send_buttons([False,True,False])
    print(serve.receive_list(str))

print ('done')
