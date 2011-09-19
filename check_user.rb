#!/usr/bin/env ruby

require 'cluser'

@qconf_exec = `which qconf`.to_s
@qconf_exec = @qconf_exec.strip

usage_msg = "Usage:\n \
-au <username>       = Add cluster user\n \
-du <username>       = Delete cluster user\n \
-ap <project name>   = Add cluster project\n \
-dp <project name>   = Delete cluster project\n \
-as <sharetree file> = Add cluster sharetree policy\n \
-ds <sharetree file> = Delete cluster sharetree policy\n \
-nid                 = Supply next avail user/group id\n"

puts "PGFI Cluster User Check:\n\n"

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