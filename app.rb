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

puts "rps\terb\terector\tfaster"
[1,2,5].each do |trunks|
  [1,2,5].each do |branches|
    rps = {}
    [:erb, :erector].each do |engine|
      rps[engine] = bench("#{engine}/#{trunks}/#{branches}")
    end
    faster = ((rps[:erector] - rps[:erb])/rps[:erb].to_f) * 100
    puts "#{trunks}x#{branches}\t#{rps[:erb]}\t#{rps[:erector]}\t#{'%.1f%%' % faster}"
  end
end

Thread.kill(thread)
