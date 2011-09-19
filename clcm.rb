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

puts "PGFI Cluster CML:\n\n"

if ClusterUser.num_groups == 0
  ClusterUser.search_by_group
end

if ClusterUser.num_users == 0
  ClusterUser.create_sge_users
end

puts "Number of PGFI Cluster Groups: #{ClusterUser.num_groups}"
puts "Number of PGFI Cluster Users: #{ClusterUser.num_users}"

if ARGV.size == 1
  if ARGV[0] == "-gen"
    puts "Generating current account and group information for SGE..."
    ClusterUser.create_sge_usersets
    ClusterUser.delete_sge_usersets
    ClusterUser.delete_sge_users
    # Line below is unnecessary since it's needed to calc ClusterUser.num_users
    # ClusterUser.create_sge_users
    ClusterUser.create_master_script
    puts "Completed."
  elsif ARGV[0] == "-next-id" || ARGV[0] == "-nid"
    ClusterUser.next_id
  else
    puts usage_msg
  end
elsif ARGV.size == 2
  case ARGV[0]
  when "-au"
    puts "Add user"
  when "-du"
    print "Are you sure you want to delete user \"#{ARGV[1]}\" (y/n)?"
    if STDIN.gets =~ /y/
      `#{@qconf_exec} -duser #{ARGV[1]}`
    else
      puts "Aborted deletion of user \"#{ARGV[1]}\"."
    end
  when "-ap"
    puts "Add project"
  when "-dp"
    print "Are you sure you want to delete project \"#{ARGV[1]}\" (y/n)?"
    if STDIN.gets =~ /y/
      `#{@qconf_exec} -dprj #{ARGV[1]}`
    else
      puts "Aborted deletion of project \"#{ARGV[1]}\"."
    end
  when "-as"
    puts "Add sharetree"
  when "-ds"
    print "Are you sure you want to delete sharetree \"#{ARGV[1]}\" (y/n)?"
    if STDIN.gets =~ /y/
      `#{@qconf_exec} -dstree #{ARGV[1]}`
    else
      puts "Aborted deletion of sharetree \"#{ARGV[1]}\"."
    end
  end
else
  puts usage_msg
end
  
