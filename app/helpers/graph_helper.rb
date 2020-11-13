require 'httparty'
module GraphHelper
  GRAPH_HOST = 'https://graph.microsoft.com'.freeze

  def make_api_call(method, endpoint, token, params = nil)
    headers = {
      "Authorization": "Bearer #{token}",
      "Content-Type": "application/json"
    }

    if method == 'get'
      query = params || {}
      HTTParty.get "#{GRAPH_HOST}#{endpoint}",
                   headers: headers,
                   query: query
    elsif method == 'post'
      params = params || {}
      puts endpoint
      HTTParty.post "#{GRAPH_HOST}#{endpoint}",
                 headers: headers,
                 body: params.to_json
    elsif method == 'delete'
      HTTParty.delete "#{GRAPH_HOST}#{endpoint}",
                   headers: headers
    end
  end
end
