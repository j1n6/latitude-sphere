require 'thin'
require 'launchy'
require 'google/api_client'

module LatitudeSphere
  class LatitudeClient
    attr_reader :host, :port, :api_client

    def initialize(host = '0.0.0.0', port = 4567)
      @host = host
      @port = port
      @api_client = Google::APIClient.new
    end

    def latitude_api
      api_client.discovered_api('latitude')
    end
    
    def authorize!
      api_client.authorization.client_id     = LatitudeSphere.client_id
      api_client.authorization.client_secret = LatitudeSphere.client_secret
      api_client.authorization.scope         = LatitudeSphere.scope
      api_client.authorization.redirect_uri  = "#{@host}:#{@port}"

      server = Thin::Server.new(@host, @port) do
        run lambda { |env|
          # Exchange the auth code & quit 
          req = Rack::Request.new(env)
          api_client.authorization.code = req['code']
          api_client.authorization.fetch_access_token!
          server.stop() 
          [200, {'Content-Type' => 'text/plain'}, 'OK']
        }
      end

      Launchy.open url
      server.start
    end
  end
end