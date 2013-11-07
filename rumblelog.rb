require 'sinatra/base'
require 'mustache/sinatra'
require 'fauna'
# for mattr_accessor
require 'active_support/core_ext/module/attribute_accessors'

load 'lib/fauna_helper.rb'

module Fauna
  def self.validate_env(key)
    if !ENV.has_key?(key)
      abort("#{key} must be set")
    end
  end

  mattr_accessor :connection

  validate_env('RUMBLELOG_FAUNA_SECRET')
  validate_env('RUMBLELOG_ADMIN_USERNAME')
  validate_env('RUMBLELOG_ADMIN_PASSWORD')

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

  def validate(params)
    data = params[:page]
    data["tags"] = data["rawtags"].split(",").map { |t| t.strip }
    data.delete("rawtags")

    constraints = {}
    constraints["permalink"] = data.delete("permalink")

    return data, constraints
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
    begin
      if params.has_key?("page")
        @pages = Fauna.with_context do
          [Page.find_by_permalink(params["page"])]
        end
        mustache :edit_single_page
      else
        build_frontpage
        mustache :edit
      end
    rescue Fauna::Connection::NotFound
      redirect '/edit'
    end
  end

  post '/edit' do
    protected!

    redirect '/edit' unless params.has_key?("permalink")

    data, constraints = validate(params)

    begin
      @page = Fauna.with_context do
        Page.find_by_permalink(params["permalink"])
      end

      Fauna.with_context do
        @page.resource.data.merge!(data)
        @page.resource.save
      end
      redirect "/edit"
    rescue Fauna::Connection::NotFound
      status 404
      body '404 - page to edit not found'
    end
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

  post '/delete' do
    protected!
    redirect '/edit' unless params.has_key?("ref")
    Fauna.with_context do
      Fauna::Resource.find(params["ref"]).delete
     end
    redirect '/edit'
  end

  get '/:permalink' do |permalink|
    # matches "GET /hello/foo" and "GET /hello/bar"
    begin
      @pages = Fauna.with_context do
        [Page.find_by_permalink(permalink)]
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
    @pages = Fauna::Set.match('classes/Pages', 'constraints.permalink', permalink).page(:size => 1)
    if @pages.empty?
      raise Fauna::Connection::NotFound, "no pages match #{permalink}"
    else
      @pages.map { |ref| Page.find(ref) }[0]
    end
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
end
