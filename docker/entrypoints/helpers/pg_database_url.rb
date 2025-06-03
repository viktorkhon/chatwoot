#!/usr/bin/env ruby
require 'uri'

database_url = ENV['DATABASE_URL']

if database_url
  uri = URI.parse(database_url)
  
  puts "export POSTGRES_HOST='#{uri.host}'"
  puts "export POSTGRES_PORT='#{uri.port}'"
  puts "export POSTGRES_USERNAME='#{uri.user}'"
  puts "export POSTGRES_PASSWORD='#{uri.password}'"
  puts "export POSTGRES_DB='#{uri.path[1..-1]}'"
else
  # Fallback to individual environment variables if DATABASE_URL is not set
  puts "export POSTGRES_HOST='#{ENV['DATABASE_HOST'] || 'localhost'}'"
  puts "export POSTGRES_PORT='#{ENV['DATABASE_PORT'] || '5432'}'"
  puts "export POSTGRES_USERNAME='#{ENV['DATABASE_USERNAME'] || 'postgres'}'"
  puts "export POSTGRES_PASSWORD='#{ENV['DATABASE_PASSWORD'] || ''}'"
  puts "export POSTGRES_DB='#{ENV['DATABASE_NAME'] || 'chatwoot_development'}'"
end
