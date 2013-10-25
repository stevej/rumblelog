require 'fauna'
require 'yaml'

module Fauna
  def self.with_context(&block)
    if block.nil?
      raise "with_context called without block"
    elsif Fauna.connection.nil?
      raise "cannot use with_context without connection"
    else
      Fauna::Client.context(Fauna.connection) do
        block.call
      end
    end
  end

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

      #root_connection = Connection.new(
      #                                 :email    => credentials["email"],
      #                                 :password => credentials["password"],
      #                                 :logger   => logger)

      #publisher_key = root_connection.post("keys/publisher")["resource"]["key"]

# [11:42:39] <@evn> you can use the DDL endpoints in cloud now
# [11:42:49] <@evn> pass your email and password to basic auth as the rootkey
# [11:48:17] <@evn> in the client, this is achieved by setting the secret to an array

      server_key = credentials["server_key"]
      Connection.new(secret: server_key,
                     logger: logger)
    end
  end
end

