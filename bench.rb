require 'rubygems'
require 'sinatra/base'

$: << 'erector/lib'
require 'erector'

class Tree < Erector::Widget
  needs :branches, :trunks
  def content
    ul :class => "tree" do
      trunks.to_i.times do |i|
        li "Trunk #{i}"
        widget Branch, :branches => branches
      end
    end
  end
end

class Branch < Erector::Widget
  needs :branches
  def content
    li "Branch #{i}"
    ul :class => "branch" do
      branches.to_i.times do |i|
        widget Branch, :branches => (branches.to_i - 1)
      end
    end
  end
end

class Bench < Sinatra::Base
  set :port, 4599
  
  get "/" do
    "hello"
  end

  get "/erec_a/:trunks/:branches" do
    Tree.new(:trunks => params[:trunks], :branches => params[:branches]).to_a
  end

  get "/erec_s/:trunks/:branches" do
    Tree.new(:trunks => params[:trunks], :branches => params[:branches]).to_s(:output => "")
  end
  
  get "/erb/:trunks/:branches" do
    erb :trunk, :locals => {:trunks => params[:trunks], :branches => params[:branches]}
  end
end
