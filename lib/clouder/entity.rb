require 'ostruct'
require 'time'

module Clouder
  class Entity < OpenStruct
  
    class << self
      def uri(address = nil)
        address ? @uri = address : @uri
      end
      
      def all
        result = Rest.get(@uri)
        total, uris, offset = result.values_at("total", "uris", "offset")
        uris.map { |uri| self.new(uri) rescue nil }
      end
      
      def create(hsh)
        obj = self.new(hsh)
        obj.save   
      end
    end

    attr_accessor :id, :etag, :last_modified
    
    def uri
      @uri ||= File.join(collection_uri, id) if id
    end
    
    def initialize(id_or_attributes = nil)
      @id, @etag, @last_modified = nil
      
      if id_or_attributes.is_a?(Hash)
        @table = id_or_attributes
      elsif id_or_attributes.is_a?(String)
        @id = id_or_attributes
        @table = Rest.get(uri)
        @etag = Rest.last_response['etag'].gsub('"', '')
        @last_modified = Time.parse(Rest.last_response['last-modified'])
        @table.each { |k,v| @table.delete(k); @table[k.to_sym] = v }
      else
        @table = Hash.new
      end
    end

    def save
      result = Rest.post(collection_uri, @table)
      if result["ok"]
        @id, @etag, @last_modified = result.values_at("uri", "etag", "last_modified")
        @id = @id.split("/").last
        @last_modified = Time.parse(@last_modified)
        true
      else
        raise result["error"]
        false
      end
    end    

    def new?
      @uri == nil and @etag == nil and @last_modified == nil
    end
              
    def collection_uri
      self.class.uri
    end
        
    def inspect
      "#<#{self.class.name} uri=#{@uri}, etag=#{@etag}, last_modified=#{@last_modified}, #{@table.inspect}>"
    end
    
  end
end
