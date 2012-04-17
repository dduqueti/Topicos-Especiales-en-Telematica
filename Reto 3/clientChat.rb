=begin
    Archivo: clientChat.rb
    Topicos Especiales en Telematica, Abril 2012
        Implementación de un servicio de presencia

            Esteban Arango Medina
            Sebastian Duque Jaramillo
            Daniel Julian Duque Tirado
=end

def Kernel.is_windows?
  processor, platform, *rest = RUBY_PLATFORM.split("-")
  platform == 'mingw32'
end


require "socket"
require 'nokogiri'
require 'readline'
require 'drb'
if Kernel.is_windows? == true
  require 'win32console'
end
load "Modules/designModules.rb"
load "user.rb"

class ClientChat < User

	include DRbUndumped
	include Color
	include Help

	attr_accessor :host, :puerto, :chat, :time, :socket

	

	def initialize(host,puerto)
		@host = host
		@puerto = puerto
		@time = Time.new
	end

	def local_ip
	  orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

	  UDPSocket.open do |s|
	    s.connect '64.233.187.99', 1
	    s.addr.last
	  end
	ensure
	  Socket.do_not_reverse_lookup = orig
	end

	def run
	    @socket = TCPSocket.new(host, puerto)
	    begin
	    	
	    	STDOUT.sync = true	    	
	    	print gris("Enter an username: ")
	    	@userName = STDIN.gets.chomp
	    	@socket.puts @userName
	    	#Creo la uri Drb (ej. druby://localhost:8787) y me expongo
	    	DRb.start_service nil, self  
	    	myUri = DRb.uri.gsub(/\/\/(.*):/,"//"+local_ip+":")
	    	#puts myUri
	    	@socket.puts myUri	
	    	reply = @socket.gets.chomp
	    	while (reply!='Welcome')
	    		puts(reply)
	    		print gris("Enter an username: ")
		    	@userName = STDIN.gets.chomp
		    	@socket.puts @userName
		    	reply = @socket.gets.chomp
	    	end




	    	system "clear"

	      	puts rojo("Conected...")
	      	puts amarillo("Type '-help' to see the avalible commands")

	    	hiloLeer = Thread.new { leer }
		    hiloEscribir = Thread.new { escribir}
		    hiloLeer.join
		    hiloEscribir.join
	    ensure
	      @socket.close
	    end
	end
	
	# Métodos expuestos al Peer para la interacción del chat
	def mandar(from,messages)
      	@chat.recibir(from,messages)
  	end
	def recibir(from,messages)
		if messages == "__DISCONNECT"
			@chat = nil
			@socket.puts("QUIT CONVERSATION (#{@userName})")
			@state = "Online"
		else
			print @time.strftime("%Y-%m-%d %H:%M:%S")+" "+rojo("#{from}: ")
	   	 	print("#{messages}\n")
	   	 	print @time.strftime("%Y-%m-%d %H:%M:%S")+" "+rojo("#{@userName}: ")
		end
	end

	def end
	    if @chat != nil
	    	mandar(@username,"__DISCONNECT")
	    end
	    @socket.puts("QUIT APP (#{@userName})")
	    Thread.list.each { |t| t.kill }
	end

	private

	def leer
		
		begin
	      while not @socket.eof?
		        line = @socket.gets.chomp
		        if line=~ /(NEW CONECTION) (.+)/i
		        	@chat = DRbObject.new nil, $2
		        	system "clear"


				else
					puts line	
		        end	
		   end
		rescue SystemExit, Interrupt
		    puts("Good Bye! :).")
			Thread.list.each { |t| t.kill }
	    rescue Exception => e     				#Catch de RUBY
	      puts "Ha ocurrido un error: #{e}"
	    end

	end

	def escribir
		begin
	      while not STDIN.eof?
	        line = STDIN.gets.chomp
	      	if line == "-HELP" || line == "-help"
	      		helpUser
	      	elsif line == "QUIT" || line == "quit"
	        	exit
	        elsif @chat != nil
	        	mandar(@userName,line)
	        else
	        	@socket.puts line
	        end	
	      end
	    rescue SystemExit, Interrupt
		    puts("Good Bye! :).")
			Thread.list.each { |t| t.kill }
	    rescue Exception => e
	      puts "Ha ocurrido un error: #{e}"      
	    end
	end
end

$client = nil

trap("SIGINT") do
		$client.end
 end

if ARGV.size < 2
  puts "Usage: ruby #{__FILE__} [host] [port]"
else
  $client = ClientChat.new(ARGV[0], ARGV[1].to_i)
  $client.run
end