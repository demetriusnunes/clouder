$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require "rubygems"
require 'json'
require 'restclient'
require 'clouder/entity'  
require 'clouder/rest'  

# The Clouder module holds global server-wide functions.
module Clouder
  VERSION = '0.0.1'

  # Returns an array of URIs of the resources exposed by
  # the CloudKit server at the +uri+.
  #
  #  Clouder.collection("http://localhost:9292")
  #  => [ "notes", "comments" ]
  def Clouder.collections(uri)
    uris = Rest.get(File.join(uri, "cloudkit-meta"))["uris"]
    uris.map { |uri| uri.split("/").last }
  end

  # Makes a HEAD request to the +uri+ and returns a hash
  # of headers contained in the response.
  def Clouder.head(uri)
    Rest.head(uri)
  end
  
end

