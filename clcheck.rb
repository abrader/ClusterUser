#!/usr/bin/env ruby

require 'cluser'

@qconf_exec = `which qconf`.to_s
@qconf_exec = @qconf_exec.strip

usage_msg = "Usage:\n \
-u <username>   = Check for user\n \
-g <group>       = Check for group\n"

puts "PGFI Cluster User/Group Check:\n\n"

class CheckUser
  
  def self.user_search
    puts "Searching for \"#{ARGV[1]}\"..."
    result = `getent passwd #{ARGV[1]}`
    if result.size > 0
      puts result
    else
      puts "User not found."
      ClusterUser.next_id
    end
  end

  def self.group_search
    puts "Searching for \"#{ARGV[1]}\"..."
    result = `getent group #{ARGV[1]}`
    if result.size > 0
      puts result
    else
      puts "Group not found."
      ClusterUser.next_id
    end
  end
  
  if ARGV.size == 1
    puts "Searching for \"#{ARGV[0]}\"..."
    result = `getent passwd #{ARGV[0]}`
    if result.size > 0
      puts result
    else
      puts "User not found."
      ClusterUser.next_id
    end
  elsif ARGV.size == 2
    if ARGV[0] == "-g"
      CheckUser.group_search
    elsif ARGV[0] == "-u"
      CheckUser.user_search
    end
  else
    puts usage_msg
  end

end