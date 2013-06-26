require 'sinatra/base'
require 'mustache/sinatra'
require 'fauna'

# TODO: make this nicer
load 'lib/fauna_helper.rb'

# TODO: this is not awesome but works for now.
module Fauna
  mattr_accessor :credentials
  mattr_accessor :connection

  self.credentials = Fauna::Rack::credentials("#{ENV["HOME"]}/.fauna.yml",
                                              "config/fauna.yml",
                                              "rumblelog")

  self.connection = Fauna::Rack::connection(self.credentials, Logger.new("rumblelog"))[:connection]
end

class Rumblelog < Sinatra::Base
  register Mustache::Sinatra
  require 'views/layout'

  set :mustache, {
    :views     => 'views/',
    :templates => 'templates/'
  }

  helpers do
    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)

      @auth.provided? &&
        @auth.basic? &&
        @auth.credentials &&
        @auth.credentials == ['admin', 'admin']
    end
  end


  def with_context(&block)
    if block.nil?
      raise "with_context called without block"
    elsif Fauna.connection.nil?
      raise "cannot use Fauna::Client.context without connection"
    else
      Fauna::Client.context(Fauna.connection) do
        block.call
      end
    end
  end

  if defined?(Fauna.connection)
    puts "phew, we have a connection"
  else
    puts "no fauna connection"
  end

  set :public_folder, 'public'

  get '/' do
    # TODO: Load N Pages, unfortunately .first only grants me a `resource` accessor.
    @pages = with_context { Page.all.page(:size => 3).first.resource.to_html_hash }
    pp @pages
    mustache :index
  end

  get '/create' do
    protected!
    mustache :create
  end

  post '/create' do
    protected!
    # TODO: validate post params
    data = params[:page]
    # TODO: ensure that unique_id is truly unique before creating entry.
    data[:unique_id] = data[:url]
    with_context { Page.create!(data) }
    redirect "/"
  end

  get '/edit' do
    protected!
  end

  post '/edit' do
    protected!
  end

  get '/t/:tag' do |tag|
    @pages = with_context { Tag.find_by_unique_id(tag).pages }
    mustache :index
  end

  get '/status' do
    # Are we connected to Fauna?
    mustache :status
  end

  get '/:url' do |url|
    # matches "GET /hello/foo" and "GET /hello/bar"
    # params[:name] is 'foo' or 'bar'
    # n stores params[:name]
    @pages = with_context { Page.find_by_unique_id(url) }
    mustache :render_page # TODO: bad name
  end

end

class Page < Fauna::Class
  field :title, :body, :url, :tags
  reference :tag
  after_save :update_tags

  def initialize(attrs = {})
    super(attrs)
  end

  def links_for_tags
    tags = self.data['tags']
    pp tags
    if tags.nil?
      []
    else
      tags.split(",").map do |tag_name|
        {tag_name: tag_name.strip}
      end
    end
  end

  def to_html_hash
    html_hash = data
    html_hash[:links_for_tags] = self.links_for_tags
    html_hash
  end

  def update_tags
    tags = self.data['tags']
    unless tags.nil?
      tags.split(",").each do |tag_name|
        tag_name.strip!
        tag =
          begin
            Tag.create!(unique_id: tag_name)
          rescue
            Tag.find_by_unique_id(tag_name)
          end
        tag.pages.add self
      end
    end
  end
end

class Tag < Fauna::Class
  reference :page
end

# Data Model
#
# A Site consists of Pages
# Pages belong to tags
# Tags are organized by time
#
#
Fauna.schema do
  with Tag do
    event_set :pages
  end

  with Page do
    event_set :tags
  end
end

