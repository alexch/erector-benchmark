# benchmark.rb
#
# This script fires up a Sinatra server and runs some simple benchmarks using
# ab (apachebench). Most settings are here at the top.

ENGINES = [:erb, :haml, :erec_s, :erec_a]
TRIES = 500

### The Sinatra app including Erector, ERB, and HAML templates

require 'rubygems'
require 'sinatra/base'

$: << 'erector/lib'
require 'erector'
require 'haml'

class Trunk < Erector::Widget
  needs :branches, :trunks
  def content
    ul :class => "trunk" do
      trunks.to_i.times do |i|
        li "Trunk #{i}"
        widget Branch, :branches => branches.to_i
      end
    end
  end
end

class Branch < Erector::Widget
  needs :branches
  def content
    ul :class => "branch" do
      branches.to_i.times do |i|
        li "Branch #{i}"
        widget Branch, :branches => (branches.to_i - 1)
      end
    end
  end
end

class Bench < Sinatra::Base
  set :port, 4599
  enable :show_exceptions
  
  get "/" do
    "hello"
  end
  
  get "/sanity" do
    a = Trunk.new(:trunks => 2, :branches => 2).to_a.join.size
    s = Trunk.new(:trunks => 2, :branches => 2).to_s(:output => "").size
    e = erb(:trunk, :locals => {:trunks => 2, :branches => 2}).size
    Erector::Widget.new do
      p a == s
      p a == e
      p s == e
      p "erec_a: #{a}"
      p "erec_s: #{s}"
      p "erb: #{e}"
    end.to_s
  end

  get "/erec_a/:trunks/:branches" do
    Trunk.new(:trunks => params[:trunks], :branches => params[:branches]).to_a
  end

  get "/erec_s/:trunks/:branches" do
    Trunk.new(:trunks => params[:trunks], :branches => params[:branches]).to_s(:output => "")
  end
  
  get "/erb/:trunks/:branches" do
    erb :trunk, :locals => {:trunks => params[:trunks], :branches => params[:branches]}
  end

  get "/haml/:trunks/:branches" do
    haml :haml_trunk, :locals => {:trunks => params[:trunks], :branches => params[:branches]}
  end

  template :branch do
    '<ul class="branch"><% branches.to_i.times do |i| %><li>Branch <%=i%></li><%= erb(:branch, :locals => {:branches => branches.to_i - 1}) %><% end %></ul>'
  end

  template :trunk do
    '<ul class="trunk"><% trunks.to_i.times do |i| %><li>Trunk <%=i%></li><%= erb :branch, :locals => {:branches => (branches.to_i)} %><% end %></ul>'
  end
  
  template :haml_trunk do
    <<-HAML
%ul.trunk
  - trunks.to_i.times do |i|
    %li
      Trunk
      =i
    = haml :haml_branch, :locals => {:branches => (branches.to_i)}
    HAML
  end

  template :haml_branch do
    <<-HAML
%ul.branch
  - branches.to_i.times do |i|
    %li
      Branch 
      =i
    = haml :haml_branch, :locals => {:branches => (branches.to_i - 1)}
    HAML
  end

end

### Benchmarking code

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
  rps.to_f
end

def run(trunks, branches)
  rps = {}
  ENGINES.each do |engine|
    rps[engine] = bench("#{engine}/#{trunks}/#{branches}")
  end
  print "%7s" % "#{trunks}x#{branches}"
  ENGINES.each do |engine|
    faster = ((rps[engine] - rps[:erb])/rps[:erb].to_f) * 100
    print "\t"
    print "%7.2f" % rps[engine]
    print "\t#{'%6.1f%%' % faster}" unless engine == :erb
  end
  puts  
end

cols = ["tree"]
ENGINES.each do |engine|
  cols << engine
  cols << "faster" unless engine == :erb
end
puts cols.map{|col| "%7s" % col.to_s}.join("\t")
[1,2,3].each do |trunks|
  [1,2,3].each do |branches|
    run trunks, branches
  end
end
run 100, 0
run 500, 0

Thread.kill(thread)
