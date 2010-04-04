require 'cgi'

class Rest
  class << self

    # set proxy for RestClient to use
    def proxy url
      RestClient.proxy = url
    end
 
    def put uri, doc = nil, headers = {}
      payload = doc.to_json if doc
      parse(RestClient.put(uri, payload, headers))
    end
 
    def get uri
      parse(RestClient.get(uri), :max_nesting => false)
    end
  
    def post uri, doc = nil, headers = {}
      payload = doc.to_json if doc
      parse(RestClient.post(uri, payload, headers))
    end
  
    def delete uri, headers = {}
      parse(RestClient.delete(uri, headers))
    end
    
    def copy uri, destination
      parse(RestClient.copy(uri, {'Destination' => destination}))
    end
    
    def move uri, destination
      parse(RestClient.move(uri, {'Destination' => destination}))
    end

    def head uri, headers = {}
      custom(:head, uri, headers)
    end
    
    def custom method, uri, headers = {}
      response = nil
      url = URI.parse(uri)
      Net::HTTP.start(url.host, url.port) { |http|
        response = http.send(method, url.path, headers)
      }
      response.to_hash
    end
  
    def parse(response, opts = {})
      if response
        json = JSON.parse(response.body, opts)
        json.extend(ResponseHeaders)
        json.headers = response.headers
        json
      end
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

module ResponseHeaders
  def headers
    @headers
  end
  
  def headers=(h)
    @headers = h
  end
end