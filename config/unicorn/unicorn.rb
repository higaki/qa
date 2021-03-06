# https://github.com/sosedoff/capistrano-unicorn
require "pathname"
app_path = Pathname(__FILE__).dirname.parent.parent.expand_path.to_path

# Set unicorn options
worker_processes 3
preload_app true
timeout 180
listen "/tmp/unicorn-qa.sock"
listen "127.0.0.1:9000"

# Spawn unicorn master worker for user app (group: app)
user 'app', 'app'

# Fill path to your app
working_directory app_path

# Should be 'production' by default, otherwise use other env
rails_env = ENV['RAILS_ENV'] || 'production'

# Log everything to one file
stderr_path "log/unicorn.log"
stdout_path "log/unicorn.log"

# Set master PID location
pid "#{app_path}/tmp/pids/unicorn.pid"

before_fork do |server, worker|
  ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection
end
