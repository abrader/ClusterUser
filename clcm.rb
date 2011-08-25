#!/usr/bin/env ruby

require 'cluser'

@qconf_exec = `which qconf`.to_s
@qconf_exec = @qconf_exec.strip

puts "PGFI Cluster CML:\n\n"

if ARGV.size == 1
  if ARGV[0] == "-gen"
    ClusterUser.create_sge_usersets
    ClusterUser.delete_sge_usersets
    ClusterUser.create_sge_users
    ClusterUser.delete_sge_users
    # ClusterUser.delete_sge_projects
    # ClusterUser.create_sge_projects
    #ClusterUser.create_sge_stree
    #ClusterUser.delete_sge_stree
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
  puts "Usage:\n \
  -au <username>       = Add cluster user\n \
  -du <username>       = Delete cluster user\n \
  -ap <project name>   = Add cluster project\n \
  -dp <project name>   = Delete cluster project\n \
  -as <sharetree file> = Add cluster sharetree policy\n \
  -ds <sharetree file> = Delete cluster sharetree policy\n"
end
  
