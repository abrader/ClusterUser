#!/usr/bin/env ruby

require File.join('/root/ClusterUser', 'cluser')


puts "PGFI Cluster User/Group Check:\n\n"

class CheckUser

  @usage_msg = "Usage:\n \
  -u <username or uid>   = Check for user\n \
  -g <groupname or gid>      = Check for group\n \
  -j <groupname or gid>      = Number of SGE jobs running within a group\n"
  
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

  def self.group_jobs
    run_jobs = 0
    pen_jobs = 0
    users = Array.new
    result = `getent group #{ARGV[1]}`
    if result.size == 0
      puts "Group does not exist."
      exit
    end

    res_sp = result.split(":")
    puts "Number of jobs running under lab/group \"#{res_sp[0]}\"..."
    u_res = `getent passwd | grep #{res_sp[2]}`
    u_res.each do |line|
      uid = line.split(":")[0]
      run_jobs += `qstat -u \"#{uid}\" | grep -iv qw | wc -l`.to_i
      pen_jobs += `qstat -u \"#{uid}\" | grep -i qw | wc -l`.to_i
    end
    puts "Running SGE jobs: #{run_jobs}"
    puts "Pending SGE jobs: #{pen_jobs}"
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
    elsif ARGV[0] == "-j"
      CheckUser.group_jobs
    end
  else
    puts @usage_msg
  end

end