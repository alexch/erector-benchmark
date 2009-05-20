load 'bench.rb'

ENGINES = [:erb, :erec_s, :erec_a]
TRIES = 500

Thread.abort_on_exception = true
thread = Thread.new do
  Bench.run!
end

sleep(2) # wait for startup

def bench(path = "", tries = TRIES)
  data = `ab -n #{tries} http://127.0.0.1:4599/#{path} 2>/dev/null`
  rps = data.match(/^Requests per second:\s*(\d*\.\d*)/)[1]
  requests = data.match(/^Complete requests:\s*(\d*)/)[1]
  raise "Tried to make #{tries} requests but only made #{requests}" unless tries.to_i == requests.to_i
  rps.to_i
end

def run(trunks, branches)
  rps = {}
  ENGINES.each do |engine|
    rps[engine] = bench("#{engine}/#{trunks}/#{branches}")
  end
  print "#{trunks}x#{branches}"
  ENGINES.each do |engine|
    faster = ((rps[engine] - rps[:erb])/rps[:erb].to_f) * 100
    print "\t#{rps[engine]}"
    print "\t#{'%.1f%%' % faster}" unless engine == :erb
  end
  puts  
end

cols = ["tree"]
ENGINES.each do |engine|
  cols << engine
  cols << "faster" unless engine == :erb
end
puts cols.join("\t")
[1,2,3].each do |trunks|
  [1,2,3].each do |branches|
    run trunks, branches
  end
end
run 100, 0
run 500, 0


Thread.kill(thread)
