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
users = {}


$my_name = "bkme_ny"
last_status = " "
me = Twitter.verify_credentials()
$my_name = me["screen_name"] if !me.nil?
t = Twitter.user_timeline({:count => 1})
last_status = t[0]["text"] if !t.nil?
#puts "last tweet: " + last_status




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
  status_id = status["id"]
  puts status_id
  
  if user != $my_name && $reports.find(:tweet_id => status_id).none?

    user_id = status["from_user_id"]
    entities = status["entities"]
      entities = entities.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    created_at =  status["created_at"]
    text = status["text"]
    geodata = status["geo"]
      geodata = geodata.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo} if !geodata.nil?

    puts '@'+ user +' says: '+text

    t = Time.parse(created_at).strftime("%b %d %H:%M")

    #look for urls
    #puts entities.inspect

    url = image = nil
    url = find_url(entities)
    puts "after url"
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
          new_status = "@"+ user + " we didn't miss your #{t} shot of # "+plate+"  at "+address+" "+ url + ". keep  clipping!"   
          new_status_short = "@"+ user + " we didn't miss your #{t} shot of # "+plate+" at "+address_short+" "+ url + "."   
        elsif !url.nil?
          new_status = "@"+ user + "  we didn't miss your #{t} shot at " + address + " " + url + ". keep  clipping!"
          new_status_short = "@"+ user + " we didn't miss your #{t} shot at " + address_short + " " + url + "."
        else
          new_status = ""  
        end
        if new_status.length > 140
          new_status = new_status_short
        end
      
      else 
        address = nil
       # new_status = "sorry @"+ user + " I only process location-enabled reports. please activate it in your device."
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
       #authorize credentials
       auth = $db.authenticate("bkme","youwerebiked1")
       puts "db authorized." if auth
       if $reports.find(:tweet_id => status_id).none?
          $reports.insert(tweetdata)
          puts "RECORD ADDED"
          
          if !users.key?(user)
            users[user] = 1
            send_tweet(new_status,options)
            
          else
            users[user] +=1
            if users[user] == 2
              send_tweet(new_status,options)
            end
            
          end
          # send out the tweet!
          
       else
      #   $reports.update({:tweet_id => status_id}, tweetdata)
         puts "RECORD IGNORED"
       end
      
       
    end #if address and photo
  puts "\n\n\n"#  puts "\nwaiting for a new #bkme...\n\n"
  
  end #end if not myself or already added
  
   
end



users.each_pair do |k,v| 
  if v > 3
    status = "@#{k} we indeed recovered #{v-1} more reports sent by you (we won't flood you with mentions). Keep defending the bikelanes!" 
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