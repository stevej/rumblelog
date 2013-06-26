require 'fauna'

module Fauna
  module Rack
    def self.credentials(config_file, local_config_file, app_name)
      env = ENV['RACK_ENV'] || 'development' # FIXME: need this for tux.
      credentials = {}

      if File.exist? config_file
        credentials.merge!(YAML.load_file(config_file)[env] || {})

        if File.exist? local_config_file
          credentials.merge!((YAML.load_file(local_config_file)[app_name] || {})[env] || {})
        end
      else
        STDERR.puts ">> Fauna account not configured. You can add one in config/fauna.yml."
      end

      credentials
    end

    def self.connection(credentials, logger)

      root_connection = Connection.new(
                                       :email    => credentials["email"],
                                       :password => credentials["password"],
                                       :logger   => logger)

      publisher_key = root_connection.post("keys/publisher")["resource"]["key"]

      connection = Connection.new(
                                  publisher_key: publisher_key,
                                  logger: logger)

      {
        root_connection: root_connection,
        connection: connection
      }
    end
  end
end

