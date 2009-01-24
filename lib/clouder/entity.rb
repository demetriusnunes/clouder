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
        options[:resolved] ? result["documents"].map { |d| new(d) } : result["uris"]
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
        id = URI.parse(uri)
        # /notes/abc
        if id.path[0,1] == "/"
          id.path.split("/")[2]
        else
          id.to_s
        end
      end
      
      def uri_from_id(id)
        url = URI.parse(id)
        if url.absolute?
          url.to_s
        else
          # /notes/1234
          if url.path[0,1] == "/"
            URI.parse(self.uri) + uri
          # 1234
          else
            File.join("#{self.uri}", id)
          end
        end
      end
      
    end

    attr_accessor :id, :etag, :last_modified
    
    def uri
      @uri ||= self.class.uri_from_id(id) if id
    end
    
    def path
      URI.parse(uri).path
    end
    
    def initialize(id_or_attributes = nil)
      @id, @etag, @last_modified, @deleted = nil

      case id_or_attributes
      when Hash: build(id_or_attributes)
      when String: get(id_or_attributes)
      else
        @table = Hash.new
      end
    end

    def save
      result = new? ? Rest.post(collection_uri, @table) : Rest.put(uri, @table, "If-Match" => etag)
      @id, @etag, @last_modified = result.values_at("uri", "etag", "last_modified")
      @id = self.class.id_from_uri(@id)
      @last_modified = Time.parse(@last_modified)
      true
    rescue RestClient::RequestFailed
      false
    end    

    def delete
      Rest.delete uri, "If-Match" => etag
      @deleted = true
      freeze
      true
    rescue RestClient::RequestFailed
      false
    end

    def deleted?; @deleted end
    
    def versions(options = {})
      if uri
        url = File.join(uri, "versions")
        if options[:etag]
          url = File.join(url, options[:etag])
          self.class.new(url)
        elsif
          url = options[:resolved] ? File.join(url, "_resolved") : url
          result = Rest.get(Rest.paramify_url(url, options))
          if options[:resolved]
            result["documents"].map { |d| self.class.new(d) }
          else
            result["uris"]
          end
        end
      else
        []
      end
    end
    
    def options
      self.class.options(uri)
    end
    
    def new?
      @uri == nil and @etag == nil and @last_modified == nil
    end
              
    def inspect
      "#<#{self.class.name} uri=#{uri}, id=#{id}, etag=#{@etag}, last_modified=#{@last_modified}, #{@table.inspect}>"
    end

    private

    def collection_uri
      self.class.uri
    end
    
    def build(doc)
      @table = doc
      if @table["uri"]
        initialize_from_json(
          :id => @table['uri'],
          :etag => @table['etag'],
          :last_modified => @table['last_modified'],
          :document => @table['document']
        )
      end
    end
    
    def get(id_or_uri)
      uri = self.class.uri_from_id(id_or_uri)
      document = Rest.get(uri)
      initialize_from_json(
        :id => uri,
        :etag => Rest.last_response['etag'],
        :last_modified => Rest.last_response['last-modified'],
        :document => document
      )
    end
    
    def initialize_from_json(doc)
      @id = self.class.id_from_uri(doc[:id])
      @etag = doc[:etag].gsub('"', '')
      @last_modified = Time.parse(doc[:last_modified])
      @table = doc[:document].is_a?(String) ? JSON.parse(doc[:document]) : doc[:document]
      @table.keys.each { |k| v = @table.delete(k); @table[k.to_sym] = v }
    end
    
  end
end
