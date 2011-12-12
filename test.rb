$LOAD_PATH << './lib'
#load local dependencies
require 'config'
require 'functions'

fileurl = "http://www.blogcdn.com/blog.moviefone.com/media/2011/01/fantastic-mr-fox1.jpg"
AWS::S3::S3Object.store("test/lala.jpg", open(fileurl), 'img.bkme.org', :access => :public_read)
