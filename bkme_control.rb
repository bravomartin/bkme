require 'rubygems'        # if you use RubyGems
require 'daemons'

options = {
    :backtrace  => true,
    :log_output => true,
    :dir_mode => :script,
    :hard_exit => true
  } 

Daemons.run('bkme.rb', options)