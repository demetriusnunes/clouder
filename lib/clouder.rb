require "rubygems"
require 'json'
require 'rest_client'

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Clouder
  VERSION = '0.0.1'
  
end

require 'clouder/entity'  
require 'clouder/rest'  
