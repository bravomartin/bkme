#global modes

$LOAD_PATH << './lib'
$LOAD_PATH << './'

  DEBUG = false
  SAFE = true
  TEST = true
  ADMIN = "brvmrtn"

puts "*********************************************************************" if TEST or DEBUG or SAFE
puts "*** Running in safe mode, nothing will be actually stored or sent ***" if SAFE
puts "***       Running in debug mode, using @bkmetst credentials       ***" if DEBUG
puts "***         Running a test with test values and keywords          ***" if TEST
puts "*********************************************************************" if TEST or DEBUG or SAFE

begin
require 'rubygems'
require 'tweetstream'
require 'twitter'
require 'mongo'
require 'nokogiri'   

require 'open-uri'
require 'net/http'
require 'net/https'
require 'JSON'
require 'time'
require 'aws/s3'
require LOCALPATH+'/lib/expurrel'
  
  
require 'credentials'
  
  #connect to AWS S3
  AWS::S3::Base.establish_connection!(
      :access_key_id     => AWS_ID,
      :secret_access_key => AWS_SECRET
    )
  
  
  
  #connect to mongo
  $db = Mongo::Connection.new(MONGO_SERVER, 27847).db(MONGO_DB)
  
  #load collection to insert reports in
  $reports = $db.collection("records")
  $reports = $db.collection("test") if DEBUG
  $flags = $db.collection("flags")
  

  auth = $db.authenticate(MONGO_USER,MONGO_PASS)
  puts "Database authenticated successfully" if auth


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
  puts "in the config"
  puts  e.inspect
  
end