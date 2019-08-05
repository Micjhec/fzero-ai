import server

serve = server.server()
# i = 0
# while i < 60:
#     serve.send_buttons([False,True,False])
#     i = i + 1

# i = 0
# while i < 100:
#     serve.send_buttons([True,True,False])
#     i = i + 1

while True:
    serve.send_buttons([False,True,False])

print ('done')
