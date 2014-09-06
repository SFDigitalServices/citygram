require 'bundler'
Bundler.require

# setup environment variables
require 'dotenv'
Dotenv.load

# setup load paths
$: << File.expand_path('../', __FILE__)
$: << File.expand_path('../lib', __FILE__)

require 'sinatra/base'
require 'sinatra/assets_extension'

module Citygram
  class App < Sinatra::Base
    register Sinatra::AssetsExtension

    configure do
      set :root, File.expand_path('../', __FILE__)
      set :logger, Logger.new(test? ? nil : STDOUT)
      set :map_id, ENV.fetch('MAP_ID') { 'codeforamerica.inb9loae' }
      set :views, 'app/views'
      set :erb, escape_html: true,
                layout_options: { views: 'app/views/layouts' }
    end

    configure :production do
      require 'newrelic_rpm'
      require 'sinatra-error-logging'
      require 'rack/ssl'
      use Rack::SSL
    end
  end
end

require 'app/models'
require 'app/routes'
require 'app/workers'

# Log instrumented requests for publisher and subscription connections
ActiveSupport::Notifications.subscribe(
  /^request\.(publisher|subscription)\./,
  Citygram::Services::ConnectionBuilder::RequestLog.new(Citygram::App.logger)
)
