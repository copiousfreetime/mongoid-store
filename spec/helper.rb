# encoding: utf-8
#
$:.unshift(File.expand_path('../../lib', __FILE__))

require 'rubygems'
require 'bundler'
require 'active_support/all'

Bundler.require(:default)

require 'mongoid-store'

Mongoid.load!(File.expand_path("../mongoid.yml", __FILE__), :test)

RSpec.configure do |config|
  config.before(:each) do
    Mongoid.client(:default).collections.each do |collection|
      collection.find.remove_all
    end
  end
end
