require 'ostruct'
require 'time'

module Clouder
  class Entity < OpenStruct
  
    class << self
      def uri(address = nil)
        address ? @uri = address : @uri
      end
      
      def all(options = {})
        uri = options[:resolved] ? File.join(@uri, "_resolved") : @uri
        result = Rest.get(Rest.paramify_url(uri, options))
        if options[:resolved]
          result["documents"].map { |d| new(d) }
        else
          result["uris"]
        end
      end
      
      def create(hsh)
        obj = self.new(hsh)
        obj.save   
        obj
      end
      
      def options(uri = self.uri)
        Rest.custom(:options, uri)
        Rest.last_response["Allow"].to_s.split(",").map { |s| s.strip }
      end

      def id_from_uri(uri)
        uri.split("/").last
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
        if @table["uri"]
          @id = Entity.id_from_uri(@table['uri'])
          @etag = @table['etag'].gsub('"', '')
          @last_modified = Time.parse(@table['last_modified'])
          @table = @table['document']
        end
      elsif id_or_attributes.is_a?(String)
        @id = Entity.id_from_uri(id_or_attributes)
        @table = Rest.get(uri)
        @etag = Rest.last_response['etag'].gsub('"', '')
        @last_modified = Time.parse(Rest.last_response['last-modified'])
        @table.each { |k,v| @table.delete(k); @table[k.to_sym] = v }
      else
        @table = Hash.new
      end
    end

    def save
      if new?
        result = Rest.post(collection_uri, @table)
      else
        result = Rest.put(uri, @table, "If-Match" => etag)
      end
      
      if result["ok"]
        @id, @etag, @last_modified = result.values_at("uri", "etag", "last_modified")
        @id = Entity.id_from_uri(@id)
        @last_modified = Time.parse(@last_modified)
        true
      else
        raise result["error"]
        false
      end
    end    

    def destroy
      result = Rest.delete uri, "If-Match" => etag
      result["ok"] == true
    end
    
    def versions
      if uri
        resp = Rest.get(File.join(uri, "versions"))
        resp['uris']
      end
    end
    
    def options
      Entity.options(uri)
    end
    
    def new?
      @uri == nil and @etag == nil and @last_modified == nil
    end
              
    def inspect
      "#<#{self.class.name} uri=#{@uri}, etag=#{@etag}, last_modified=#{@last_modified}, #{@table.inspect}>"
    end

    private

    def collection_uri
      self.class.uri
    end
  end
end
