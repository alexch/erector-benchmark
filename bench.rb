require 'rubygems'
require 'sinatra/base'

$: << 'erector/lib'
require 'erector'





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
end
