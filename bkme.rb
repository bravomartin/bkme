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

#now = Time.now.strftime("%I:%M%p")

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
  process_tweet(status)
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