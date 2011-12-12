$LOAD_PATH << './lib'
#load local dependencies
require 'config'
require 'functions'




r = $reports.find_one(:tweet_id => 144793430734802945)

puts r