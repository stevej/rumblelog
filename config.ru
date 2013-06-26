# Ruby > 1.9.2 doesn't automatically add the CWD to the load path
$: << '.'

require 'rubygems'
require 'bundler'

Bundler.require

require './rumblelog'

use Rack::ShowExceptions

run Rumblelog

