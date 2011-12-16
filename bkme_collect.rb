#BKME stream collect
#Created by Martin Bravo on 2011-11-10.
#Copyright (c) 2011 #BKME. Defend the bike lane!.
#version: 0.21

begin
$LOAD_PATH << './lib'


#clean screen, show art.
print "\e[2J\e[f"
art = File.open("bkme.art")
art.each do |l|
  puts l
end

#load local dependencies
require 'config'
require 'functions'
users = {}


tweets = Twitter.search("#bkme", options={:include_entities => true, :count =>200})

  tweets.each do |twitterobject|
  
  
  
    status =  twitterobject.attrs
    user = status["from_user"]
    status_id = status["id"]
    text = status["text"]

    next unless text.include?("#bkme")
    next unless $reports.find(:tweet_id => status_id).none?

    t = Time.now
    now = t.strftime("at %I:%M%p %m/%d/%Y")
    puts "\n\nnew message received from @#{user} #{now}"


    user_id = status["from_user_id"]
    entities = status["entities"]
    entities = entities.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    created_at =  status["created_at"]
    geodata = status["geo"]
    geodata = geodata.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo} if !geodata.nil?

    puts "@#{user} says: \"#{text}\""

    #look for urls
    url = find_url(entities)

    #keep going only if there is a photo in the report
    if url.nil? then puts "no url, next"; next end

    tags = nil #get_tags(entities)
    #look for images
    file_url = find_file_url(entities)
    filename = store_media(status_id, file_url)

    address = get_address(geodata)

    # plate = find_plate(text)

    response = create_response(user, status_id, url, geodata, address, tags, recovered = true, created_at)
    
    if !users.key?(user)
      users[user] = 1
      send_tweet(response,options)
      
    else
      users[user] +=1
    end
    
    options = tweet_options(user_id, geodata)

   # send_tweet(response, options) if !response.nil?

    if geodata.nil? then puts "no geo, not stored"; next end

    #store the data in the database
    tweetdata = {}
    tweetdata[:tweet_id] = status_id
    tweetdata[:user_id] = user_id
    tweetdata[:user_name] = user
    tweetdata[:text] = text
    tweetdata[:geolocation] = geodata[:coordinates].join(",")
    tweetdata[:geo] = geodata[:coordinates]
    tweetdata[:address] = address
    tweetdata[:url] = url if !url.nil?
    tweetdata[:filename] = filename
    tweetdata[:created_at] = Time.parse(created_at)
    tweetdata[:created_at_i] = Time.parse(created_at).to_i
    tweetdata[:response] = status
    tweetdata[:verified] = -1

    #send data to mongo
    send_to_mongo(tweetdata)
    



  end






          



users.each_pair do |k,v| 
  if v > 2
    status = "@#{k} we indeed recovered #{v-1} more of your GETS  you (we won't flood you with mentions). Keep defending the bikelanes!" 
  else
    status = nil
  end
  options = {}
  options[:in_reply_to_status_id]  = k
  send_tweet(status,options)
end









rescue Exception => e
  puts e.inspect
end