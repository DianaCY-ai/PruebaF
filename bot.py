# bot.py

from chatterbot import ChatBot

chatbot = ChatBot("Chatpot")

exit_conditions = (":q", "quit", "exit")
while True:
    query = input("> ")
    if query in exit_conditions:
        break
    else:
        print(f"🪴 {chatbot.get_response(query)}")

#PRUEBA 
#PRUEBA
#123456
#cambio a la rama brDihani
#Pruebas 123
#probNDO Cmbios de Diana