# SuperSonic - A livecoding-tool for irb by m.wisniowsi (nodepond.com) and t.schrader (slogmen).
# Currently this tool need an open socket to a pure-data patch

require 'socket'
require 'irb'
require 'irb/completion'

require 'sketches'

# SuperSonic-code
require './supermidi'
require './superui'
require './superhelp'

@nopuredata = false

# not decided about the sketches approach yet...
Sketches.config :editor => 'nano',
                :background => true,
                :terminal => lambda { |cmd|
                  "xterm -fg gray -bg black -e #{cmd.dump}"
                }

#Sketches.config :editor => 'nano',
#                :background => true,
#                :terminal => lambda { |cmd|
#                  "'/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl' #{cmd.dump}"
#                }

#Sketches.config :editor => '/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl',
#                :background => true

#Sketches.config :editor => 'nano',
#                :background => true
                

### UDP Socket connection has to be some troubles. Let's make this later...

#s = UDPSocket.new
#s.bind(nil, 3001)
#s.send('hello World;', 0, 'localhost', 3001)
#puts s

#testing ARGV-stuff
ARGV.each do |a|
  puts a
  if a == "--no-pd" then
    @nopuredata = true
  end
  ARGV.delete(a)
end


module Pd

	@sock = nil
	
	def connect(host, port)
		@sock = TCPSocket.new("localhost",port)
		@sock.write ( 'SuperSonic inited on port '+ port.to_s+";")
	end

	def disconnect
		@sock.close
	end

	def send(message)
		@sock.write(message+";")
	end

end

class PdSeq16
	include Pd

	@sequence

	def init(host='localhost',port=3000)
		self.connect(host,port)
		@sequence = Hash.new
		@sequence = { 
			:type => "notes",
			:data => "60 0 0 0 60 0 0 0 63 0 0 0 65 0 0 0",
			:transpose => 0,
			:length => 16,
			:host => host,
			:port => port
	}
	end

	def data(mdata)
		@sequence[:data] = mdata
	end
	alias_method :data=, :data
	def data!(mdata)
		@sequence[:data] = mdata
		s
	end

	def info
		return @sequence
	end
	alias_method :i, :info

	# send current sequence data to puredata ss = send_sequence
	def s
		# calculate transpose
		mdata = @sequence[:data].split
		mdata.map! { |note|
			note = note.to_i + @sequence[:transpose]
			note.to_s
		}
		data_to_send = mdata.join(" ")
		
		# send data
		#self.send(@sequence[:data])
		self.send(data_to_send)
	end

	# transpose sequence values
	def transpose(t)
		@sequence[:transpose] = t
	end
	alias_method :transp, :transpose
	alias_method :t, :transpose

	def transpose!(t)
		@sequence[:transpose] = t
		s
	end
	alias_method :transp!, :transpose!
	alias_method :t!, :transpose!

	# send stop signal
	def stop
		self.send("stop")
	end
	alias_method :sto, :stop
	alias_method :off, :stop

	# send start signal
	def start
		self.send("start")
	end
	alias_method :sta, :start
	alias_method :on, :start

	# send reset signal
	def reset
		self.send("reset")
	end
	alias_method :r, :reset
	
	# this method puts the current sequencer data into the copy-buffer to directly paste into irb and evaluate (currently mac only)
	#http://utilitybelt.rubyforge.org/usage.html
	#http://utilitybelt.rubyforge.org/svn/lib/utility_belt/clipboard.rb
	def copybuffer
		s = ""
		s = "seq16.data '#{@sequence[:data]}'"
		IO.popen('pbcopy', 'w+') {|clipboard| clipboard.write(s)}
		print s
	end
	alias_method :cp, :copybuffer
end

@pdseq16 = PdSeq16.new

if !@nopuredata
  @pdseq16.init
end

def seq16
	return @pdseq16
end


IRB.start

if !@nopuredata
  seq16.disconnect
end