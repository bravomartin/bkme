#BKME stream collect
#Created by Martin Bravo on 2011-11-10.
#Copyright (c) 2011 #BKME. Defend the bike lane!.
#version: 0.3

# require 'bundler'
# Bundler.require
 
 
waiting = "\nwaiting for a new #bkme...\n\n"
retries = 0
last = Time.now

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
require 'messages'


#folder where the images will go
route = "reports/images/"

 me = Twitter.verify_credentials()
 if !me.nil? then $my_name = me["screen_name"] else $my_name = "bkme" end
 t = Twitter.user_timeline({:count => 1})
if !t.nil? then last_status = t[0]["text"] else last_status =  " " end 
 puts "last tweet: " + last_status unless last_status == " "
 
track_terms = ['#bkme', '#BKME', '#Bkme', '@bkme_ny']

track_terms = ['#test', "photo","pic", "here", "now"] if TEST


begin
  back = "Back on track! get me some cars, amigo..."
  if back != last_status
    Twitter.update(back) unless SAFE
    puts back
  else
    puts "I didnt send the message, but still get me some cars, amigo..."
  end
rescue Exception => e
  puts e.inspect
  puts "I coudn't send the message, but still get me some cars, amigo..."
end

begin

puts waiting 

TweetStream::Client.new.on_delete{ |status_id, user_id|  
  next
  }.on_limit { |skip_count|  
    sleep 10
  }.track(track_terms) do |status|  

  user = status.user.screen_name
  
  next if status.geo.nil? and TEST
  
  #if myself, skip this one
  if user == $my_name then puts "myself, skipping"; next end

  t = Time.now
  now = t.strftime("at %I:%M%p %m/%d/%Y")
  puts "\n\nnew message received from @#{user} #{now}"
     
  status_id = status.id
  user_id = status.user.id
  hashtags =  status.entities.hashtags
  entities = status.entities
  created_at =  status.created_at
  text = status.text
  geodata = status.geo
  
  
  puts "@#{user} says: \"#{text}\""

  #look for urls
  url = find_url(entities)

  #keep going only if there is a photo in the report
  if url.nil? then puts "no url, next #{waiting}"; next end


  tags = nil #get_tags(entities)
  #look for images
  #image_url = find_media(entities)
  file_url = find_file_url(entities)
  puts "got here..."
  puts file_url
  puts status_id
  filename = store_media(status_id, file_url)
  puts "got here too"

  address = get_address(geodata)
  
 # plate = find_plate(text)
 
  
  response = create_response(user, url, geodata, address, tags)

  options = tweet_options(user_id, geodata)

  send_tweet(response, options) if !response.nil?


  if geodata.nil? then puts "no geo, not stored #{waiting}"; next end


    
  #store the data in the database
  tweetdata = {}
  tweetdata[:tweet_id] = status_id
  tweetdata[:user_id] = user_id
  tweetdata[:user_name] = user
  tweetdata[:text] = text
  tweetdata[:geolocation] = geodata[:coordinates].join(",")
  tweetdata[:address] = address
  tweetdata[:url] = url if !url.nil?
  tweetdata[:image_url] = image_url[:media_url]
  tweetdata[:filename] = filename
  tweetdata[:created_at] = created_at
  tweetdata[:response] = status
  
  #send data to mongo
  send_to_mongo(tweetdata)

  
  puts waiting
end

rescue Interrupt => e
  puts "\nProgram finished by the user."
  
rescue Exception => e
  puts "somewhere else"
  puts e.message
  retries = 0 if last < Time.now-60*60
  if retries < 5
    retries += 1 if last > Time.now-60*10
    sleep 15*retries
    
    puts "restarting the Twitter filter for the #{retries.ordinal} time."
    last = Time.now
    retry
  else 
  Twitter.direct_message_create("brvmrtn", "problemas! #{e.message}"[0,140]) unless SAFE
    puts "Asking for help!"
  end
end