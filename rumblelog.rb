require 'sinatra/base'
require 'mustache/sinatra'
require 'fauna'
# for mattr_accessor
require 'active_support/core_ext/module/attribute_accessors'

# TODO: make this nicer
load 'lib/fauna_helper.rb'

# TODO: this is not awesome but works for now.
module Fauna
  mattr_accessor :connection

  self.connection = Fauna::Connection.new(:secret => ENV['RUMBLELOG_FAUNA_SECRET'])
end

class Rumblelog < Sinatra::Base
  register Mustache::Sinatra
  require 'views/layout'

  set :mustache, {
    :views     => 'views/',
    :templates => 'templates/'
  }

  configure do
    set :title, "Rumbleblog"
    set :subtitle, <<-eos
A sample blog powered by <a href="http://fauna.org">Fauna</a>, <a href="http://sinatrarb.com">Sinatra</a>, <a href="http://purecss.io">Pure</a>, and <a href="http://heroku.com">Heroku</a>
    eos
    set :full_url_prefix, "http://rumblelog.herokuapp.com"
  end

  helpers do
    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Rumblelog Admin"'
      halt 401, "Not authorized\n"
    end

    # FIXME: move the password into a config file.
    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)

      @auth.provided? &&
        @auth.basic? &&
        @auth.credentials &&
        @auth.credentials == [ENV['RUMBLELOG_ADMIN_USERNAME'],
                              ENV['RUMBLELOG_ADMIN_PASSWORD']]
    end
  end

  set :public_folder, 'public'

  before do
    # FIXME: this is terrible, sinatra.
    @title = settings.title
    @subtitle = settings.subtitle
    @full_url_prefix = settings.full_url_prefix
  end

  def build_frontpage
    Fauna.with_context do
      @pages_set = Fauna::Set.new('classes/Pages/instances')
      @pages = @pages_set.page(:size => 10).map { |p| Page.find(p) }
    end
  end

  get '/' do
    build_frontpage
    mustache :index
  end

  get '/create' do
    protected!
    mustache :create
  end

  def validate(params)
    data = params[:page]
    data["tags"] = data["rawtags"].split(",").map { |t| t.strip }
    data.delete("rawtags")

    constraints = {}
    constraints["permalink"] = data.delete("permalink")

    return data, constraints
  end

  post '/create' do
    protected!
    # TODO: validate post params
    data, constraints = validate(params)
    Fauna.with_context do
      page = Fauna::Resource.create('classes/Pages',
                                    :data        => data,
                                    :constraints => constraints)
    end
    redirect "/"
  end

  get '/edit' do
    protected!
    data, constraints = validate(params)
    Fauna.with_context do
      # Fauna::Resource.update ???
    end
    redirect "/edit"
  end

  post '/edit' do
    protected!
  end

  get '/t/:tag' do |tag|
    @pages = Fauna.with_context do
      Page.find_by_tag(tag).page(:size => 10).map { |p| Page.find(p) }
    end
    mustache :index
  end

  get '/status' do
    # Are we connected to Fauna?
    mustache :status
  end

  get '/atom.xml' do
    build_frontpage
    content_type 'application/atom+xml'
    mustache :atom, {:layout => false}
  end

  get '/:permalink' do |permalink|
    # matches "GET /hello/foo" and "GET /hello/bar"
    begin
      @pages = Fauna.with_context do
        Page.find_by_permalink(permalink).page(:size => 1).map { |p| Page.find(p) }
      end

      mustache :render_page
    rescue Fauna::Connection::NotFound
      status 404
      body '404 - page not found'
    end
  end
end

class Page
  attr_accessor :resource

  def self.find(ref)
    Page.new(Fauna::Resource.find(ref))
  end

  def self.find_by_permalink(permalink)
    Fauna::Set.match('classes/Pages', 'constraints.permalink', permalink)
  end

  def self.find_by_tag(tag)
    Fauna::Set.match('classes/Pages', 'data.tags', tag)
  end

  def title
    self.resource.data['title']
  end

  def permalink
    self.resource.constraints['permalink']
  end

  def body
    self.resource.data['body']
  end

  def tags
    self.resource.data['tags']
  end

  def ts
    self.resource.ts
  end

  def ts_for_atom
    ts.to_datetime.to_s
  end

  def ref
    self.resource.ref
  end

  def initialize(resource)
    self.resource = resource
  end

  def links_for_tags
    tags = self.tags
    if tags.nil?
      []
    else
      tags.map do |tag_name|
        {tag_name: tag_name.strip}
      end
    end
  end

  def to_html_hash
    html_hash = self.resource.data
    html_hash[:links_for_tags] = self.links_for_tags
    html_hash
  end

  def update_tags
    tags = self.tags
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

class Tag < Fauna::Resource
  #reference :page
end

# Data Model
#
# A Site consists of Pages
# Pages belong to tags
# Tags are organized by time
#
#
# Fauna.schema do
#   with Tag do
#     event_set :pages
#   end

#   with Page do
#     event_set :tags
#   end
# end

