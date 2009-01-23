require "rubygems"
require 'json'
require 'rest-client/lib/rest_client'
require 'clouder/entity'  
require 'clouder/rest'  

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Clouder
  VERSION = '0.0.1'

  def Clouder.collections(uri)
    uris = Rest.get(File.join(uri, "cloudkit-meta"))["uris"]
    uris.map { |uri| uri.split("/").last }
  end
  
end

