
$LOAD_PATH << './lib'
#load local dependencies
require 'config'
require 'functions' 
 
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
 
 [1, 22, 123, 112, 10, -3.1415].each {|i| puts i.ordinal}
 
 
 
def how_many(user)
  how_many = {}
  how_many[:hour] = 0
  how_many[:day] = 0
  how_many[:week] = 0 
  how_many[:month] = 0  
  how_many[:ever] =  $reports.find(:user_name => user).count()
  
  
  n = Time.now
  lasthour = n - 60*60
  lastday = n - 60*60*24
  lastweek = n - 60*60*24*7
  lastmonth = n - 60*60*24*30 

  $reports.find(:user_name => user).each do |e|
    t = Time.parse(e["created_at"])
    how_many[:hour] += 1 if t > lasthour
    how_many[:day] += 1 if t > lastday
    how_many[:week] += 1 if t > lastweek
    how_many[:month] += 1 if t > lastmonth
  end
  return how_many
end

long = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ac nibh erat, a rutrum enim. Etiam sit amet erat mi, sed faucibus elit. Morbi ut tincidunt lectus. Duis est est, mattis ac posuere viverra, accumsan at nibh. Maecenas rhoncus euismod ornare. Mauris ac libero sed enim commodo placerat vitae sed erat. Sed ultricies mattis odio at suscipitlalala."

puts shorten(long, 140)
puts shorten(long, 140, true)
