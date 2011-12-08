def get_address(geodata)
  address = nil
        geo = geodata[:coordinates].join(",")
        puts "geolocation: " + geo
        uri_for_google = "http://maps.googleapis.com/maps/api/geocode/json?latlng="+geo+"&sensor=true"
      begin
        data = Net::HTTP.get(URI.parse(uri_for_google))
        result = JSON.parse(data)
      rescue Exception => e
        puts "related to get address"
        puts e.message
        return [0,0]
        
      end
        number = result["results"][0]["address_components"][0]["short_name"]
        street = result["results"][0]["address_components"][1]["short_name"]
        neighborhood = result["results"][0]["address_components"][2]["short_name"]
        city = result["results"][0]["address_components"][5]["short_name"]
        address = number +" " + street + ", "+ neighborhood + ", "+ city
        address_short = number +" " + street + ", "+ neighborhood
        address_short = shorten(address_short)

    a = [address, address_short]
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


def find_tags entities
  tags = []
  if !entities[:hashtags].nil?
    for entities[:hashtags]
    tags < 
  
  else
    return nil
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
  re = /\b(\w{5,8})\s/
  plate = re.match(text)[1] unless !re.match(text)
  if plate.nil? then puts "no plate found" 
  else puts "found plate no: #{plate}" end
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


t = Twitter.user_timeline({:count => 1})
if t.nil? then l = nil else l = t[0]["created_at"] end
if l.nil? then $last_time = Time.now- 60*10 else $last_time = Time.parse(l) end

def send_tweet(options = {:status =>"nil", :options => nil})
  
  if Time.now - $last_time < 10 
    puts "waiting 10 seconds before sending the next tweet"
    sleep(10) 
  end
  begin
    if !status.nil?
     Twitter.update(:status, :options)
      puts "REPLIED: " +  status
      $last_time = Time.now 
    end
  rescue Exception => e
    puts e.message
    puts "\nThere was an error sending the tweet"
  end


end







############################### MAIN FUNCTION ###############################

def create_response user=nil, plate=nil, url=nil, geodata =nil address=[nil,nil], tags=nil
  
  
  
  options = {}
  options[:in_reply_to_status_id]  = user_id 
  if !geodata.nil?
    options[:lat]= geodata[:coordinates][0]
    options[:long] = geodata[:coordinates][1]
  end
  
  if url.nil? and address[0].nil?
    return 
  
  if !address[0].nil?
      # generate the tweet
      if !plate.nil? && !url.nil?
        new_status = "@"+ user + " just got "+plate+" in the bikelane at "+address[0]+" "+ url + ". more to come soon"   
        new_status_short = "@"+ user + " just got "+plate+" in the bikelane at "+address[1]+" "+ url + "."   
      elsif !url.nil?
        new_status = "@"+ user + " just got a car in the bikelane at " + address[0] + " " + url + ". follow me for updates."
        new_status_short = "@"+ user + " just got a car in the bikelane at " + address[1] + " " + url + "."
      else
        new_status = ""  
      end
      # if status too long, use short status
      if new_status.length > 140
        new_status = new_status_short
      end
    elsif geodata.nil?
        new_status = "sorry @"+ user + " I only process location-enabled reports. please activate it in your device."
      else
        new_status = "sorry @#{user}, there was a problem processing your address. Please "
        address = nil
      end
    end #if geodata
  else
    puts "no photo, no tweet."
  end #if media


end