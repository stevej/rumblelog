Vagrant::Config.run do |config|
  config.vm.box = "heroku"
  config.vm.box_url = "https://dl.dropboxusercontent.com/s/rnc0p8zl91borei/heroku.box"
  config.vm.share_folder "fauna-ruby", "/fauna-ruby", "#{ENV['HOME']}/src/fauna-ruby"
  config.vm.forward_port 1234, 8082
end
