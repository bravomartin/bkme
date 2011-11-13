#BKME stream collect
#Created by Martin Bravo on 2011-11-10.
#Copyright (c) 2011 #BKME. Defend the bike lane!.
#version: 0.21

begin
$LOAD_PATH << './lib'
#load gems
require 'rubygems'
require 'net/http'
require 'net/https'
require 'JSON'

#clean screen, show art.
print "\e[2J\e[f"
art = File.open("bkme.art")
art.each do |l|
  puts l
end

#load local dependencies
require 'twitter_config'
require 'functions'


uri = "http://search.twitter.com/search.json?q=%23bkme&rpp=100&include_entities=true"
data = Net::HTTP.get(URI.parse(uri))
tweets = JSON.parse(data)
tweets["results"].each do |status|
  
  
  
  #get last tweet
  last_status = " "
  t = Twitter.user_timeline({:count => 1})
  last_status = t[0]["text"] if !t.nil?
  # get from the object the data we need 
  user = status["from_user"]
  if user != $my_name
    status_id = status["id"]
    puts status_id
    user_id = status.["from_user_id"]
    entities = status.["entities"]
    created_at =  status.created_at
    text = status.text
    geodata = status.geo

    puts '@'+ user +' says: '+text

    #look for urls
    #puts entities.inspect

    url = image = nil
    url = find_url(entities)
    #look for images
    image_urls = find_media(entities)
    #keep going only if there is a photo in the report
    if !url.nil? or !image_urls.nil?
      
      #get the address info (if not present send instructions)
      if !geodata.nil? 
        a = get_address(geodata)
        address = a["address"]
        puts "address: "+ address
        address_short = shorten(a["address_short"])
        #find the plate
        plate = find_plate(text)

        # generate the tweet
        if !plate.nil? && !url.nil?
          new_status = "@"+ user + " just BKED car license plate "+plate+" in the bikelane on "+address+" "+ url + ". follow me for updates."   
          new_status_short = "@"+ user + " just BKED license plate "+plate+" in the bikelane on "+address_short+" "+ url + "."   
        elsif !url.nil?
          new_status = "@"+ user + " just BKED a car in the bikelane on " + address + " " + url + ". follow me for updates."
          new_status_short = "@"+ user + " just BKED a car in the bikelane on " + address_short + " " + url + "."
        else
          new_status = ""  
        end
        if new_status.length > 140
          new_status = new_status_short
        end
      
      else 
        address = nil
        new_status = "sorry @"+ user + " I only process location-enabled reports. please activate it in your device."
      end #if geodata
    else
      puts "no photo, no tweet."
    end #if media

    if !new_status.nil? && new_status != last_status
      # add options
      options = {}
      options[:in_reply_to_status_id]  = user_id 
      if !geodata.nil?
        options[:lat]= geodata[:coordinates][0]
        options[:long] = geodata[:coordinates][1]
      end  
      # send out the tweet!
      begin
#       Twitter.update(new_status, options)
        puts "REPLIED: " +  new_status
      rescue Exception => e
        puts "related to send tweet back"
        puts e.message
      end
    end #if status not empty

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
        tweetdata[:image_url] = image_urls["media_url"]
        tweetdata[:local_filename] = image_urls["file_route"]
      end
      if !plate.nil?
        tweetdata[:plate] = plate
      end
      tweetdata[:created_at] = created_at
      tweetdata[:response] = status
      
      
#send data to mongo
      # #authorize credentials
      # auth = $db.authenticate("bkme","youwerebiked1")
      # puts "db authorized." if auth
      # if $reports.find(:tweet_id => status_id).none?
      #    $reports.insert(tweetdata)
      #    puts "RECORD ADDED"
      # else
      #   $reports.update({:tweet_id => status_id}, tweetdata)
      #   puts "RECORD UPDATED"
      # end
      
       
    end #if address and photo
    puts "\nwaiting for a new #bkme...\n\n"
  end #end if not myself
  
  
  
  
  
  
  
  
  
  
   
end

rescue Exception => e
  puts e.inspect
end