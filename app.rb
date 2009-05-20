load 'bench.rb'

Thread.abort_on_exception = true
thread = Thread.new do
  Bench.run!
end

sleep(2) # wait for startup

def bench(path = "", tries = 500)
  data = `ab -n #{tries} http://127.0.0.1:4599/#{path} 2>/dev/null`
  rps = data.match(/^Requests per second:\s*(\d*\.\d*)/)[1]
  requests = data.match(/^Complete requests:\s*(\d*)/)[1]
  raise "Tried to make #{tries} requests but only made #{requests}" unless tries.to_i == requests.to_i
  rps.to_i
end

engines = [:erb, :erec_s, :erec_a]
puts "tree\t#{engines.join("\tfaster\t")}\tfaster"
[1,2,3].each do |trunks|
  [1,2,3].each do |branches|
    rps = {}
    engines.each do |engine|
      rps[engine] = bench("#{engine}/#{trunks}/#{branches}")
    end
    print "#{trunks}x#{branches}"
    engines.each do |engine|
      faster = ((rps[engine] - rps[:erb])/rps[:erb].to_f) * 100
      print "\t#{rps[engine]}"
      print "\t#{'%.1f%%' % faster}"
    end
    puts
  end
end

# Thread.kill(thread)
