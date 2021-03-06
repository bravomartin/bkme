

#extend numeric with a cardinal function.
class Numeric
  def ordinal
    cardinal = self.to_i.abs
    if (10...20).include?(cardinal%100) then
      cardinal.to_s << 'th'
    else
      cardinal.to_s << %w{th st nd rd th th th th th th}[cardinal % 10]
    end
  end
end

# string extension to check if a string is too long for tweeting
class String
  def toolong
    if self.length > 119
      return true
    else
      return false
    end
  end
end



def get_address(geodata)
  return nil if geodata.nil?
  geo = geodata[:coordinates].join(",")
  puts "geolocation: " + geo
  uri_for_google = "http://maps.googleapis.com/maps/api/geocode/json?latlng="+geo+"&sensor=true"
  begin
    data = Net::HTTP.get(URI.parse(uri_for_google))
    result = JSON.parse(data)
    number = result["results"][0]["address_components"][0]["short_name"]
    street = result["results"][0]["address_components"][1]["short_name"]
    neighborhood = result["results"][0]["address_components"][2]["short_name"]
    city = result["results"][0]["address_components"][5]["short_name"]
    puts city
    address = number +" " + street + ", "+ neighborhood + ", "+ city
    address_short = number +" " + street + ", "+ neighborhood
    address_short = shorten(address_short)
    area = neighborhood + ", "+ city
    puts "address: " + address
    return [address, address_short,area]
  rescue Exception => e
    puts "couldn't get address from google"
    return nil      
  end
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
  #we need to add a list of tags used and add them to a relation map (and have a list of uncatched terms)
  tags = []

  if !entities[:hashtags].nil?
    return nil
  else
    return nil
  end
end

def find_url entities
  #we need to add a list of img service providers (and have a list of uncatched terms)
  url = nil
  if entities[:urls] != [] && !entities[:urls].nil?
    # puts entities[:urls]
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
  return url
end

def find_media entities
  #for yfrog: Construct URL like <YOURURL>:iphone. For example, http://yfrog.com/0kratsj:iphone.
  return nil if entities[:media].nil?
  media_url = entities[:media][0]["media_url"]
  return nil if media_url.nil? 
  #if there is an image, store it in the server.
  filename = media_url.split("/")[-1]
  file_route = nil
  # route = route.chomp("/")
  #   File.open(route+"/"+filename, 'wb') do |f|
  #     f.write(open(media_url).read)
  #   end  
  f = {:media_url => media_url,:file_route => file_route}  
  puts "photo found: " + media_url
  return f
end



def find_file_url entities
  begin
  services = ["yfrog", "pic.twitter.com", "twitpic", "lockerz.com", "mobypicture.com", "twitgoo","posterous", "img.ly"]

  image_url = entities[:media][0]["media_url"] if !entities[:media].nil?
  url = find_url(entities)

  fullurl = "http://"+url
  fullurl = expand_url(fullurl) if fullurl.include? "t.co"
  service = url.split("/")[0]
  # if !services.to_s.include? service
  #   
  #   Twitter.direct_message_create(ADMIN, service + " not in my list!") unless SAFE or DEBUG
  #   puts service + " not in my list!"
  #   return nil
  # end
  
  fileurl = nil
  if service.include? "lockerz"
    fileurl = "http://api.plixi.com/api/tpapi.svc/imagefromurl?url=#{fullurl}&size=big"
  elsif service.include? "pic.twitter.com"
    fileurl = image_url if defined? image_url
  elsif service.include? "twitpic.com"
    doc = Nokogiri::HTML(open(fullurl))  
    fileurl = doc.xpath('//img[@class="photo"]').first["src"]
  elsif service.include? "yfrog"
    fileurl = fullurl+":medium"
  end
  if fileurl.nil?
    problemas = "problemas! don't know how to process #{service} images!"
    Twitter.direct_message_create(ADMIN, problemas) unless SAFE or DEBUG
    puts problemas
    fileurl = nil
  end

  return fileurl
rescue Exception => e
  puts e.message
  puts e.backtrace
end  

end

def expand_url url
  e = Expurrel.new(url)
  exp = e.decode
  if exp != url and !exp.nil?
    expand_url(exp)
  else
    return exp
  end
end
  
def store_media id, fileurl
  unless fileurl.nil? or fileurl == -1
    filename = "gets/#{id.to_s}.jpg" unless DEBUG
    filename = "test/#{id.to_s}.jpg" if DEBUG
    AWS::S3::S3Object.store(filename, open(fileurl), 'img.bkme.org', :access => :public_read) unless SAFE
  else
    puts "ERROR!!!" 
    filename = nil
  end
  return filename
end


def find_plate text
  plate = nil
  re = /\b(\w{5,8})\s/
  plate = re.match(text)[1] unless !re.match(text)
  if plate.nil? 
    puts "no plate found" 
  else 
    puts "found plate no: #{plate}" 
  end
  return plate
end

def shorten (string, count = 50, keeplast = false)
  return string if string.length <= count
  
	if keeplast
    last = string.split(' ')[-1]
    shortened = string[0, count-last.length]
  	splitted = shortened.split(' ')
  	words = splitted.length
		if string[count-last.length].chr == " "  then shorter = splitted[0, words].join(" ")
  	else  shorter = splitted[0, words-1].join(" ") end
		shorter << " #{last}"  
	else
    shortened = string[0, count]
  	splitted = shortened.split(' ')
  	words = splitted.length
  	if string[count].chr == " " then splitted[0, words].join(" ")
    else splitted[0, words-1].join(" ") end
  end
end


t = Twitter.user_timeline({:count => 1})
if t.nil? then l = nil else l = t[0]["created_at"] end
l = Time.parse(l) unless l.class == Time
if l.nil? then $last_time = Time.now- 60*10 else $last_time = l end


def send_tweet(status , options)
  
  if Time.now - $last_time < 5 
    puts "waiting 5 seconds before sending the next tweet"
    sleep 5
  end
  begin
    if !status.nil?
     Twitter.update(status, options)  unless SAFE or TEST
      puts "REPLIED: " +  status
      $last_time = Time.now 
    end
  rescue Exception => e
    puts e.message
    puts "\nThere was an error sending the tweet"
  end


end


def send_to_mongo (tweetdata)
  begin
  #re-authorize credentials
  auth = $db.authenticate(MONGO_USER,MONGO_PASS)
  puts "db authorized." if auth
  if $reports.find("tweet_id" => tweetdata[:tweet_id]).none?
    $reports.insert(tweetdata) unless SAFE or DEBUG
    test = $db.collection("test")
    test.insert(tweetdata) if DEBUG
    puts "RECORD ADDED"
  else
    $reports.update({"tweet_id" => tweetdata[:tweet_id]}, tweetdata)  unless SAFE or DEBUG
    $db.collection("test").update({"tweet_id" => tweetdata[:tweet_id]}, tweetdata)  if DEBUG
    puts "RECORD UPDATED"
  end
  rescue Exception => e
    puts e.message
    puts e.backtrace
  end
end



def is_following user
  if Twitter.user?(user)
    Twitter.friendship($my_name, user)["target"]["following"]
  else
    false
  end
end

def how_many(user)
  how_many = {}
  how_many[:hour] = 1
  how_many[:day] = 1
  how_many[:week] = 1 
  how_many[:month] = 1  
  how_many[:ever] =  $reports.find(:user_name => user).count() + 1
  
  
  n = Time.now
  wday = (n.wday == 0) ? 7 : n.wday
  hour = n.hour+1
  lasthour = n - 60*60
  lastday = n - 60*60*24
  lastweek = n - 60*60*hour*wday
  lastmonth = n - 60*60*hour*n.day 

  $reports.find(:user_name => user).each do |e|
    t = e["created_at"]
    t = Time.parse(t) unless t.class == Time
    how_many[:hour] += 1 if t > lasthour
    how_many[:day] += 1 if t > lastday
    how_many[:week] += 1 if t > lastweek
    how_many[:month] += 1 if t > lastmonth
  end
  
  if TEST
    how_many[:hour] = 1
    how_many[:day] = 1
    how_many[:week] = 1
    how_many[:month] = 1 +rand(10)   
    how_many[:ever] =  1 + how_many[:month] + rand(10)   
  end

  return how_many
end

def rel_date(date)
  date = Date.parse(date, true) unless /Date.*/ =~ date.class.to_s
  days = (date - Date.today).to_i
  
  return 'today'     if days >= 0 and days < 1
  return 'tomorrow'  if days >= 1 and days < 2
  return 'yesterday' if days >= -1 and days < 0
  
  return "in #{days} days"      if days.abs < 60 and days > 0
  return "#{days.abs} days ago" if days.abs < 60 and days < 0
  
  return date.strftime('%A, %B %e') if days.abs < 182
  return date.strftime('%A, %B %e, %Y')
end

def tweet_options(user_id, geodata)

  options = {}
  options[:in_reply_to_status_id]  = user_id 
  if !geodata.nil?
    options[:lat]= geodata[:coordinates][0]
    options[:long] = geodata[:coordinates][1]
  end
  return options
end


def create_response(user=nil, status_id=nil, url=nil, geodata =nil, address=nil, tags=nil, recovered = false, created_at=nil)
  bkmeurl = "http://BKME.ORG/get/#{status_id}"
  
  if user.nil? then return nil end
  if url.nil? && geodata.nil? then return nil end
  
  nogeo = {}
  nogeo["unknown"] = "Sorry @#{user} we can't get your location! Is it activated on the app and the tweet? Learn here how http://bkme.org/faq#geolocation"
  nogeo["error"] = "sorry @#{user}, there was a problem processing your address. This doesn't happen often, don't let this stop you from GETTING more RIDES!"

  nogeo.each do |k,m|
    nogeo[k] = shorten(m,140, true) if m.toolong
  end
  
  return nogeo["unknown"] if geodata.nil?
  return nogeo["error"] if address.nil?
  
  how_many = how_many(user)
  follows = is_following(user)
  
  got =   [ ".@#{user} GOT one at #{address[0]}.", 
            ".@#{user} GOT a RIDE at #{address[0]}.", 
            ".@#{user} GOT a WHIP at #{address[0]}."]
  got_s = [ ".@#{user} GOT one at #{address[1]}.", 
            ".@#{user} GOT a RIDE at #{address[1]}.", 
            ".@#{user} GOT a WHIP at #{address[1]}."]
  got_a = [ ".@#{user} GOT one in #{address[2]}.", 
            ".@#{user} GOT a RIDE in #{address[2]}.", 
            ".@#{user} GOT a WHIP in #{address[2]}."]
  
  nth_hour = ["That's #{how_many[:hour]} in a row!",
                "#{how_many[:hour]} in a row! you're on fire!",
                "#{how_many[:hour]} in a row! no one can stop you!"
                ]
  nth_day = ["That's your #{how_many[:day].ordinal} in the last 24h!"]
  nth_week = ["That's your #{how_many[:week].ordinal} of the week!"]
  nth_month = ["That's #{how_many[:month]} RIDES this month!"] 
  nth_ever =  ["That's #{how_many[:ever]} RIDES!"]
  first = ["Congrats on your 1st GET :) You're now one of us."]
  

  follow = ["Don't forget to follow @BKME_NY for updates.",
            "Remember to follow @BKME_NY."]
  if recovered
    t = Time.parse(created_at)
    if t.strftime("%a") == Time.now.strftime("%a") then pre = "at"
    else pre = t.strftime("%A") end
    created = pre +" "+ t.strftime("%a %I:%M%p")
    got = ["We just catched a GET from you #{created} at #{address[0]}"]
    got_s = ["We just catched a GET from you #{created} at #{address[1]}"]
  end

  if recovered then r = 0 
  else  r = rand(3) end
  
  if how_many[:hour] > 10
    response = "#{got[r]} #{nth_hour[2]}"
    response = "#{got_s[r]} #{nth_hour[2]}" if response.toolong
  elsif how_many[:hour] > 4
    response = "#{got[r]} #{nth_hour[1]}"
    response = "#{got_s[r]} #{nth_hour[1]}" if response.toolong
  elsif how_many[:hour] > 1
    response = "#{got[r]} #{nth_hour[0]}"
    response = "#{got_s[r]} #{nth_hour[0]}" if response.toolong
  elsif how_many[:day] > 1
    response = "#{got[r]} #{nth_day[0]}"
    response = "#{got_s[r]} #{nth_day[0]}" if response.toolong
  elsif how_many[:week] > 2
    response = "#{got[r]} #{nth_week[0]}"
    response = "#{got_s[r]} #{nth_week[0]}" if response.toolong
  elsif how_many[:month] > 3
    response = "#{got[r]} #{nth_month[0]}"
    response = "#{got_s[r]} #{nth_month[0]}" if response.toolong
  elsif how_many[:ever] > 1
    response = "#{got[r]} #{nth_ever[0]}"
    response = "#{got_s[r]} #{nth_ever[0]}" if response.toolong
  elsif how_many[:ever] == 1
    response = "#{got[r]} #{first[0]}"
    response = "#{got_s[r]} #{first[0]}" if response.toolong
  end
  
  if rand < 0 and !is_following(user) and !TEST
    response = "#{got[r]} #{follow[0]}"
    response = "#{got_s[r]} #{follow[0]}" if response.toolong
  end

  #the messages should be less than 119 by now. this is a brute force shortener.
  response = shorten(response,119) if response.toolong

  return response+" "+ bkmeurl

  
end
