require 'rubygems'
require 'tweetstream'
require 'twitter'
require 'mongo'

require 'net/http'
require 'net/https'
require 'JSON'

#production keys
CONSUMER_KEY = 'ocnQkTD0dYfD7o2elj2Og'
CONSUMER_SECRET = 'RDu2tk6kzbXjQtNlH07QYJjpkENQ7NUdstfl2THloU'
OAUTH_TOKEN = '397570607-vm9Se5BnZVkblyUNeJwsx1ftFMKQ4ftIlgMwpUpK'
OAUTH_TOKEN_SECRET = 'Vf8tA3ujoVYTLmgr5reiDsDHCbEI40yRjMmij0JZO0'


db = Mongo::Connection.new("staff.mongohq.com", 10033).db("bkme")
auth = db.authenticate("bkme","youwerebiked")
if auth then puts "db authorized." end
#load collection to insert reports in
$reports = db.collection("reports")


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
end



