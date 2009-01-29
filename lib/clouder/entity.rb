require 'ostruct'
require 'time'

module Clouder
  # This is the base class to be used when accessing resources
  # in a CloudKit server. It contains all the basic persistence
  # methods and attributes. See the entity_spec.rb file for sample usages.
  #
  # A Note class should be declared as follows:
  #   class Note < Clouder::Entity
  #     uri "http://localhost:9292/notes"
  #   end
  class Entity < OpenStruct
  
    class << self

      # If +address+ is passed, sets the URI for the target class.
      # If nothing is passed, returns the current URI for the target class.
      #
      #   Note.uri "http://localhost:8989/notes" # changes the old URI
      #   Note.uri # => "http://localhost:8989/notes"
      def uri(address = nil)
        address ? @uri = address : @uri
      end

      # If +options+ is nil, returns an array containing all URIs 
      # of existing objects for this class. Sort order is from the 
      # most recent to the oldest.
      #
      # For other results, +options+ can be:
      # [:resolved] If +true+, returns full objects instead of URIs.
      # [:offset] A positive integer, starting at 0, offsetting the result.
      # [:limit] A positive integer, limiting the results.
      #
      # All options can be combined.
      #
      #   Note.all 
      #   Note.all(:resolved => true)
      #   Note.all(:offset => 20, :limit => 10)
      #   Note.all(:resolved => true, :limit => 20, :offset => 10)
      def all(options = {})
        uri = options[:resolved] ? File.join(@uri, "_resolved") : @uri
        result = Rest.get(Rest.paramify_url(uri, options))
        options[:resolved] ? result["documents"].map { |d| new(d) } : result["uris"]
      end
      
      # Creates and saves an object with the attributes and values
      # passed as a hash. Returns the newly created object.
      #
      #   note = Note.create(:text => "My note", :author => "John Doe")
      def create(hsh = {})
        obj = self.new(hsh || {})
        obj.save   
        obj
      end

      # Returns an array of allowed HTTP methods to be requested at
      # +uri+. If +uri+ is nil, the class URI is queried.
      #
      #  Note.options # => [ "GET", "HEAD", "POST", "OPTIONS" ]
      def options(uri = self.uri)
        Rest.custom(:options, uri)
        Rest.last_response["Allow"].to_s.split(",").map { |s| s.strip }
      end

      # Extracts object ids from absolute or partial URIs.
      #
      #   Note.id_from_uri("http://localhost:9292/notes/ce655c90-cf09-012b-cd41-0016cb91f13d") 
      #   => "ce655c90-cf09-012b-cd41-0016cb91f13d" 
      def id_from_uri(uri)
        id = URI.parse(uri)
        # /notes/abc
        if id.path[0,1] == "/"
          id.path.split("/")[2]
        else
          id.to_s
        end
      end

      # Composes a full URI from an object id or partial URI.
      #
      #   Note.uri_from_id("/notes/ce655c90-cf09-012b-cd41-0016cb91f13d") 
      #   => "http://localhost:9292/notes/ce655c90-cf09-012b-cd41-0016cb91f13d" 
      #
      #   Note.uri_from_id("ce655c90-cf09-012b-cd41-0016cb91f13d") 
      #   => "http://localhost:9292/notes/ce655c90-cf09-012b-cd41-0016cb91f13d" 
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

    # Unique object id - not an URI, just a UUID
    attr_reader :id

    # ETag, a UUID
    attr_reader :etag

    # Last modified timestamp
    attr_reader :last_modified

    # Full URI for the object
    #   => "http://localhost:9292/notes/ce655c90-cf09-012b-cd41-0016cb91f13d" 
    def uri
      @uri ||= self.class.uri_from_id(id) if id
    end

    # Partial URI for the object (without the protocol, hostname)
    #   => "/notes/ce655c90-cf09-012b-cd41-0016cb91f13d" 
    def path
      URI.parse(uri).path
    end

    # Constructs a new, unsaved object OR retrieves an existing object. 
    # According to +id_or_attributes+, which can be:
    #
    # [nil] Initializes a new, unsaved, empty object
    # [Hash of attributes and values] Initializes a new, unsaved object with attributes and values set
    # [String with a URI, path or ID] Retrieves the corresponding object if exists
    #
    #  note = Note.new # => new, empty
    #  note = Note.new(:text => "Ready note", :author => "Myself") # => new, with attributes set
    #  note = Note.new("ce655c90-cf09-012b-cd41-0016cb91f13d") # => existing object
    def initialize(id_or_attributes = nil)
      @id, @etag, @last_modified, @deleted = nil

      case id_or_attributes
      when Hash: build(id_or_attributes)
      when String: get(id_or_attributes)
      else
        @table = Hash.new
      end
    end

    # Saves a new or existing object. If the object already exists,
    # then its etag should match the etag in the database, otherwise
    # the operation fails.
    #
    # Returns +true+ if save was successful, +false+ otherwise.
    #  note = Note.new(:text => "Ready note", :author => "Myself")
    #  note.save # => true
    def save
      result = new? ? Rest.post(collection_uri, @table) : Rest.put(uri, @table, "If-Match" => etag)
      @id, @etag, @last_modified = result.values_at("uri", "etag", "last_modified")
      @id = self.class.id_from_uri(@id)
      @last_modified = Time.parse(@last_modified)
      true
    rescue RestClient::RequestFailed
      false
    end    

    # Deletes an existing object. Its etag should match the etag in 
    # the database, otherwise the operation fails.
    #
    # Returns +true+ if save was successful, +false+ otherwise.
    #  note = Note.new("ce655c90-cf09-012b-cd41-0016cb91f13d")
    #  note.delete # => true
    def delete
      Rest.delete uri, "If-Match" => etag
      @deleted = true
      freeze
      true
    rescue RestClient::RequestFailed
      false
    end

    # +true+ if object was not saved yet, +false+ otherwise.
    def new?
      @uri == nil and @etag == nil and @last_modified == nil
    end

    # +true+ if object was deleted, +false+ otherwise.
    def deleted?; @deleted end
    
    # Retrieves older versions of the object. Sort order is from the
    # current version to the oldest one.
    # The +options+ parameter works as in +all+.
    #
    #  note = Note.new("ce655c90-cf09-012b-cd41-0016cb91f13d")
    #  older_versions = note.versions(:resolved, :limit => 3)
    def versions(options = {})
      if uri
        url = File.join(uri, "versions")
        if options[:etag]
          url = File.join(url, options[:etag])
          self.class.new(url)
        else
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

    # Returns an array of allowed HTTP methods to be requested for
    # this object.
    #
    #  note = Note.new("ce655c90-cf09-012b-cd41-0016cb91f13d") # => existing object
    #  note.options # => [ "DELETE", "GET", "HEAD", "PUT", "OPTIONS" ]
    def options
      self.class.options(uri)
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
      @etag = doc[:etag].to_s.gsub('"', '')
      @last_modified = Time.parse(doc[:last_modified])
      @table = doc[:document].is_a?(String) ? JSON.parse(doc[:document]) : doc[:document]
      @table.keys.each { |k| v = @table.delete(k); @table[k.to_sym] = v }
    end
    
  end
end
