require 'cgi'

class Rest
  class << self

    def last_response
      RestClient.last_response
    end
      
    # set proxy for RestClient to use
    def proxy url
      RestClient.proxy = url
    end
 
    def put uri, doc = nil
      payload = doc.to_json if doc
      JSON.parse(RestClient.put(uri, payload))
    end
 
    def get uri
      JSON.parse(RestClient.get(uri), :max_nesting => false)
    end
  
    def post uri, doc = nil
      payload = doc.to_json if doc
      JSON.parse(RestClient.post(uri, payload))
    end
  
    def delete uri
      JSON.parse(RestClient.delete(uri))
    end
    
    def copy uri, destination
      JSON.parse(RestClient.copy(uri, {'Destination' => destination}))
    end
    
    def move uri, destination
      JSON.parse(RestClient.move(uri, {'Destination' => destination}))
    end
  
    def paramify_url url, params = {}
      if params && !params.empty?
        query = params.collect do |k,v|
          v = v.to_json if %w{key startkey endkey}.include?(k.to_s)
          "#{k}=#{CGI.escape(v.to_s)}"
        end.join("&")
        url = "#{url}?#{query}"
      end
      url
    end
  end # class << self
end
