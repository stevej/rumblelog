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
end

