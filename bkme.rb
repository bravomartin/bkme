#BKME stream collect
#Created by Martin Bravo on 2011-11-10.
#Copyright (c) 2011 #BKME. Defend the bike lane!.
#version: 0.21

# require 'bundler'
# Bundler.require
# 


begin
$LOAD_PATH << './lib'

#clean screen, show art.
print "\e[2J\e[f"
art = File.open("bkme.art")
art.each do |l|
  puts l
end

#load local dependencies
require './lib/config'
require './lib/functions'


#folder where the images will go
route = "reports/images/"

 $my_name = "bkme"
 last_status = " "
 me = Twitter.verify_credentials()
 $my_name = me["screen_name"] if !me.nil?
 t = Twitter.user_timeline({:count => 1})
 last_status = t[0]["text"] if !t.nil?
 puts "last tweet: " + last_status
 
track_terms = ['#bkme', '#BKME', '#Bkme']


begin
  back = "Back on track! get me some cars, amigo..."
  if back != last_status
    #Twitter.update(back)
    puts back
  else
    puts back + " (not sent)"
  end
rescue Exception => e
  puts e.inspect
  puts "I coudn't send the message, but still get me some cars, amigo..."
end


TweetStream::Client.new.track(track_terms) do |status|


  # get from the object the data we need 
  user = status.user.screen_name
  if user != $my_name
    status_id = status.id
    user_id = status.user.id
    hashtags =  status.entities.hashtags
    entities = status.entities
    created_at =  status.created_at
    text = status.text
    geodata = status.geo

    puts '@'+ user +' says: '+text

    #look for urls
    #puts entities.inspect

    url = image_url = nil
    url = find_url(entities)
    ####    tags = get_tags(hashtags)
    #look for images
    image_url = find_media(entities)
    #keep going only if there is a photo in the report
    if !url.nil? or !image_url.nil?
      
      
    geodata.nil? ? (address=[nil,nil]) : (get_address(geodata))
    plate = find_plate(text)

    
    response = create_response(user, plate, url, geodata, address, tags)
    


    #if there is address and photo, post the info to the database
    if !geodata.nil? && !url.nil? 
      tweetdata = {}
      tweetdata[:tweet_id] = status_id
      tweetdata[:user_id] = user_id
      tweetdata[:user_name] = user
      tweetdata[:text] = text
      tweetdata[:geolocation] = geodata[:coordinates].join(",")
      tweetdata[:address] = address
      if !url.nil?
        tweetdata[:url] = url
      end
      if !image_urls.nil?
        tweetdata[:image_url] = image_url["media_url"]
        tweetdata[:local_filename] = image_url["file_route"]
      end
      if !plate.nil?
        tweetdata[:plate] = plate
      end
      tweetdata[:created_at] = created_at
      tweetdata[:response] = status
      
      #send data to mongo
      #authorize credentials
      auth = $db.authenticate("bkme","youwerebiked1")
      puts "db authorized." if auth
      if $reports.find(:tweet_id => status_id).none?
        $reports.insert(tweetdata)
        puts "RECORD ADDED"
      else
        $reports.update({:tweet_id => status_id}, tweetdata)
        puts "RECORD UPDATED"
      end
       
    end #if address and photo
    puts "\nwaiting for a new #bkme...\n\n"
  end #end if not myself




end


rescue Interrupt => e
  puts "\nProgram finished by the user."
rescue Exception => e
  puts "somewhere else"
  puts e.message
  puts e.backtrace
  error = "problemas! help @brvmrtn!"
  if error != last_status
    #Twitter.update(error)
    puts error
    
  end
end