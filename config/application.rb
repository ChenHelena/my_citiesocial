require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MyCitiesocial
  class Application < Rails::Application
    config.generators do |g|
      g.assets false
      g.helper false
      g.test_framework false
    end
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1
    
    # Load environment variables from .env file
    config.before_configuration do
      env_file = File.join(Rails.root, '.env')
      Dotenv.load(env_file) if File.exists?(env_file)
    end
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
