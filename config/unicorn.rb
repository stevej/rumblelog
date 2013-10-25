worker_processes 3
timeout 30
preload_app true

before_fork do |server, worker|
  puts "before_fork"
  # disconnect from fauna?
end

after_fork do |server, worker|
  # connect to fauna?
end

