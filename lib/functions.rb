def get_address(geodata)
  address = nil
    begin
        geo = geodata[:coordinates].join(",")
        puts "geolocation: " + geo
        uri_for_google = "http://maps.googleapis.com/maps/api/geocode/json?latlng="+geo+"&sensor=true"
        data = Net::HTTP.get(URI.parse(uri_for_google))
        result = JSON.parse(data)
        number = result["results"][0]["address_components"][0]["short_name"]
        street = result["results"][0]["address_components"][1]["short_name"]
        neighborhood = result["results"][0]["address_components"][2]["short_name"]
        city = result["results"][0]["address_components"][5]["short_name"]
        address = number +" " + street + ", "+ neighborhood + ", "+ city
        address_short = number +" " + street + ", "+ neighborhood

    rescue 
      puts "ERROR GETTING THE ADDRESS!"
    end
    a = {"address" => address, "address_short" => address_short}
  return a
end

def send_to_cakemix(data)
    begin
      url = URI.parse("http://www.itpcakemix.com")
       url_add = URI.parse("http://www.itpcakemix.com/add")
       response = Net::HTTP.post_form(url_add, data)
       puts "Data saved to cakemix"
    rescue
      puts "ERROR UPLOADING TO CAKEMIX!"
    end
end

def find_url entities
  url = nil
  if entities[:urls] != [] && !entities[:urls].nil?
    puts entities[:urls]
    #for yfrog: Construct URL like <YOURURL>:iphone. For example, http://yfrog.com/0kratsj:iphone.
    urls = entities[:urls]
    if urls != []
      urls.each do |u| 
        candidate = u["display_url"]
        if candidate != "" && candidate.scan("bkme") == []
          url = candidate
        end
      end
    end
  elsif !entities[:media].nil?
    url = entities[:media][0]["display_url"]
  end
  if !url.nil? then puts "url found: " + url end
  return url
end

def find_media entities
  #for yfrog: Construct URL like <YOURURL>:iphone. For example, http://yfrog.com/0kratsj:iphone.
  if !entities[:media].nil?
    media_url = entities[:media][0]["media_url"]
    if !media_url.nil? 
      #if there is an image, store it in the server.
      filename = media_url.split("/")[-1]
      file_route = nil
      # route = route.chomp("/")
      # File.open(route+"/"+filename, 'wb') do |f|
      #   f.write(open(media_url).read)
      # end  
      f = {"media_url" => media_url,"file_route" => file_route}  
      puts "photo found: " + media_url       
      return f
    else
      return nil
    end
  else
    return nil
  end
end

def find_plate text
  plate = nil
  words = text.split(/\s/)
  words.first(2).each do |word|
    isbk = word =~ /#[Bb][Kk][Mm][Ee]/ 
    if word =~/\w{5,8}/ && !isbk
      plate = word.upcase
    end
  end
  if plate.nil? then puts "no plate found" end
  return plate
end

def shorten (string, count = 50)
	if string.length >= count
		shortened = string[0, count]
		splitted = shortened.split(/\s/)
		words = splitted.length
		if string[count].chr == " "
	    splitted[0, words].join(" ")
  	else
		  splitted[0, words-1].join(" ")
	  end
	else 
		string
	end
end


def send_tweet(status,options)
  too_often = false
  t = Twitter.user_timeline({:count => 1})
  l = t[0]["created_at"] if !t.nil?
  last_time = Time.parse(l)
  if Time.now - last_time < 10 then too_often = true end
    
  begin
    if !status.nil?
     Twitter.update(status, options)
      puts "REPLIED: " +  status
      if too_often
        puts "sleeping 5 seconds..."
        sleep(5)
      end
    end
  rescue Exception => e
    puts "Related to send tweet"
    puts e.message
  end


end

############################### MAIN FUNCTION ###############################

def process_tweet status
  #get last tweet
  last_status = " "
  t = Twitter.user_timeline({:count => 1})
  last_status = t[0]["text"] if !t.nil?
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
        Twitter.update(new_status, options)
        puts "REPLIED: " +  new_status
      rescue Exception => e
        puts "related to send tweet"
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