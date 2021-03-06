=begin
	Archivo: mainModules.rb
	Topicos Especiales en Telematica, Abril 2012
		Implementación de un servicio de presencia

			Esteban Arango Medina
			Sebastian Duque Jaramillo
			Daniel Julian Duque Tirado
=end

#Expresiones regulares para los mensajes proveninetes del los usuarios
RegUserActions = %r{(?<cdg>(?i)LIST USERS|CHAT|QUIT CONVERSATION|QUIT APP|RESP CONVER) *(?<user>\(.{1,}\))?}
RegResps = %r{(Y|y|S|s|Yes|YES|yes|YeS|yEs|si|Si|sI)}


module Main
	# ---------- MAIN  ----------
	def mainADMIN(socket)
		while not socket.eof?
            line = socket.readline.chomp
            r = RegUserActions.match(line)
            userOwner = @users.invert[socket]
            if !(r.nil?)
                code = r[:cdg]
                code.upcase!
                case code
                    when "QUIT CONVERSATION"
                        userName = r[:user].to_s.sub!(/\(/,'').sub!(/\)/,'')
                        @users.keys.each do |user|
                            if(user.userName == userName)
                                user.state = 'Online'
                                @users[user].puts ("You have just left you last conversation.")
                                @users[user].puts amarillo("Type '-help' to see the avalible commands")
                                messagesOffline(userName)
                                #Server info
                                puts "User "+ verde(userName)+" has left his/her last conversation."
                                break
                            end
                        end
                    when "QUIT APP"
                        userName = r[:user].to_s.sub!(/\(/,'').sub!(/\)/,'')
                        @users.keys.each do |user|
                            if(user.userName == userName)
                                user.state = 'Offline'
                                puts "User "+ verde(userName)+" has gone :(."
                                break
                            end
                        end
                    when "LIST USERS"
                        socket.puts gris("Online users:")
                        @users.keys.each do |user|  
                            socket.puts verde("\t #{user.userName}") if user.state == "Online"
                        end
                        socket.puts gris("Busy users:")
                        @users.keys.each do |user|
                            socket.puts amarillo("\t #{user.userName}") if user.state == "Busy"
                        end
                        socket.puts gris("Offline users:")
                        @users.keys.each do |user|
                            socket.puts azul("\t #{user.userName}") if user.state == "Offline"
                        end
                        socket.puts "\n"
                    when "CHAT"
                        unless r[:user].nil?
                            userName = r[:user].to_s.sub!(/\(/,'').sub!(/\)/,'')
                            #Flags decisiones importantes
                            existe=false
                            messages=false

                            userConectTo= @users.invert[socket] #My information
                            uriUserConectTo = userConectTo.uri
                            #Verificar que no sea el mismo
                            if userConectTo.userName == userName
                                socket.puts ("You can not chat with yourself!.")   
                            else
                                @users.keys.each do |user|
                                    if(user.userName == userName) 
                                        existe=true
                                        if(user.state == 'Online')
                                        	socket.puts ("Waiting for #{userName} responses...")
                                        	#Pregunto primero si el otro peer si desea 'chatiar' conmigo
                                        	@users[user].puts ("User "+verde("#{userConectTo.userName}")+" wants to chat with you.")
                                            @users[user].puts ("Would you like too?(Y/N)")

                                            #Indico que estoy esperando por una respuesta de este socket
                                            user.response=true
                                            resp = ""
                                            
                                            #Manejo de concurrencia #Espero activa buuuuuu
                                            while (user.response==true)
                                                next
                                            end

                                            resp=user.response_text

        									if resp=~RegResps
        										@users[user].puts("NEW CONECTION #{uriUserConectTo}")     #El se conecta conmigo
        										@users[user].puts @time.strftime("%Y-%m-%d %H:%M:%S")     #Muestro el tiempo de la conversación
                                                @users[user].puts("Your now connected with "+verde("#{userConectTo.userName}")+".")
        	                                    socket.puts ("NEW CONECTION #{user.uri}")                 #Me conecto con el 
        	                                    socket.puts @time.strftime("%Y-%m-%d %H:%M:%S")
                                                socket.puts ("Your now connected with "+verde("#{userName}")+".")
        	                                    user.state = userConectTo.state ='Busy'
                                                #Server information
                                                puts "Users "+verde(userConectTo.userName)+" and "+verde(userName)+" are in a conversation."
        									else
        										socket.puts ("User "+verde("#{userName}")+" does not want to chat with you.")
        									end
                                        elsif (user.state == 'Busy')
                                           socket.puts ("User "+verde("#{userName}")+" is busy at this moment, you may interrupt.")
                                           messages=true
                                        else
                                           socket.puts ("User "+verde("#{userName}")+" is offline at this moment.")
                                           messages=true
                                        end  
                                        break   #Lo encontré me salgo el for                                       
                                    end
                                end
                                if(messages)
                                    leaveMessages(socket,userConectTo.userName,userName)
                                end
                                if(!existe)
                                    socket.puts "User "+rojo("#{userName}")+" does not exist!."
                                end 
                            end
                        else
                            socket.puts "ERR 2"     #No mandó nada en el user
                        end                                    
                end#case
            elsif (userOwner.response==true)
                userOwner.response_text=line.chomp
                userOwner.response=false
            else
                socket.puts "ERR 1"
            end
        end#while
	end
end