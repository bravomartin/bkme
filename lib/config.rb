
begin
require 'rubygems'
require 'tweetstream'
puts "got here"
gem 'twitter' , '= 1.7.2'
require 'twitter'
require 'mongo'

require 'net/http'
require 'net/https'
require 'JSON'

#connect to AWS S3
# AWS::S3::Base.establish_connection!(
#     :access_key_id     => 'AKIAJQPOWZKALWX23IBQ',
#     :secret_access_key => '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'
#   )


#connect to mongo
  $db = Mongo::Connection.new("dbh84.mongolab.com", 27847).db("bkme")


#production keys
CONSUMER_KEY = 'ocnQkTD0dYfD7o2elj2Og'
CONSUMER_SECRET = 'RDu2tk6kzbXjQtNlH07QYJjpkENQ7NUdstfl2THloU'
OAUTH_TOKEN = '397570607-vm9Se5BnZVkblyUNeJwsx1ftFMKQ4ftIlgMwpUpK'
OAUTH_TOKEN_SECRET = 'Vf8tA3ujoVYTLmgr5reiDsDHCbEI40yRjMmij0JZO0'

#test keys
# CONSUMER_KEY = 'Ce8Ciu1HXAEBXBg1O3qaw'
# CONSUMER_SECRET = 'gPHYdkzmWHsdF1vuoyDcLvkGEgPYHODAvmFS3cgww'
# OAUTH_TOKEN = '407596227-Xg2zSIs3jmTaBaVCxv7aIH970B6OVd5v1G7izhev'
# OAUTH_TOKEN_SECRET = 'f55gs6THCZuMxUW6aNtuLxC8Mw1vS9ushKsXXmyn4vM'



  #load collection to insert reports in
  $reports = $db.collection("records")
  auth = $db.authenticate("bkme","youwerebiked1")

#authtenticating the TweetStream object
TweetStream.configure do |config|
  config.consumer_key = CONSUMER_KEY
  config.consumer_secret = CONSUMER_SECRET
  config.oauth_token = OAUTH_TOKEN
  config.oauth_token_secret = OAUTH_TOKEN_SECRET
  config.auth_method = :oauth
  config.parser   = :yajl
end
# authenticating the Twitter object
Twitter.configure do |config|
  config.consumer_key = CONSUMER_KEY
  config.consumer_secret = CONSUMER_SECRET
  config.oauth_token = OAUTH_TOKEN
  config.oauth_token_secret = OAUTH_TOKEN_SECRET
  puts "Twitter authenticated successfully"
end


rescue Exception => e
  puts  e.inspect
  
end

