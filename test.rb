$LOAD_PATH << './lib'
#load local dependencies
require 'config'
require 'functions'
require 'time'




# 
# photos = [
#   ["https://p.twimg.com/AgwNbLKCIAIn2bz.jpg", 147507648298885120 ],
#   ["https://p.twimg.com/AgwNBb9CIAA5oV-.jpg", 147507206126968833],
#   ["https://p.twimg.com/AgwMpmyCAAANtZf.jpg", 147506796716752896],
#   ["https://p.twimg.com/Agp_NYZCQAIRVUh.jpg", 147069805705445376],
#   ["https://twitpic.com/show/large/7t9ent", 147010317505925120],
#   ["https://twitpic.com/show/large/7t9eim", 147010210983198721],
#   ["https://p.twimg.com/AgpFV2uCAAEPhwu.jpg", 147006179606921217],
#   ["https://p.twimg.com/AgpFOM3CMAA4uUa.jpg", 147006048111308801],
#   ["https://twitpic.com/show/large/7ssi1r", 146610500438999040]
# ]
# 
# filename = "gets/#{photos[0][1].to_s}.jpg" unless DEBUG
# fileurl = photos[0][0]
# 
# AWS::S3::S3Object.store(filename, open(fileurl), 'img.bkme.org', :access => :public_read)
# 
# 







coll = $db.collection("records")



# # coll.create_index([["geo", Mongo::GEO2D]])
# geo = [40.71031832,-73.95863793]
# gs = geo.inspect
# coll.find( { "geo" => {"$near" => geo, "$maxDistance" => 0.01 } } ).each { |t|
#   puts t["geolocation"]
#   }

# 
tests = coll.find().to_a
# tests = tests.sort{|a,b| b["created_at_i"]<=>a["created_at_i"]}
tests.each do |t|
  # g =  t["geolocation"].split(",")
  # geo = [g[0].to_f,g[1].to_f]
  # puts geo.inspect
  # puts t["geo"]
  # puts t["response"]["geo"]["coordinates"]
  # created = t["created_at"]
  # rcreated = t["response"]["created_at"]
  # puts created.class
  # puts created.class
  # parsed = Time.parse(rcreated)# unless created.class == Time
  # puts parsed
  # puts "               "+ parsed.to_s
  id = t["tweet_id"]
  # puts t["created_at_i"]
  puts t["filename"]
  filename = "gets/#{id.to_s}.jpg"
  puts filename + " original"
  # coll.update({"tweet_id" => id}, {"$set" => {"filename" =>  filename }})
end

