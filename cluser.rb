#!/usr/bin/env ruby

require 'rubygems'
require File.join('/root/ClusterUser', 'cu-config')
require 'net/ldap'
require 'fileutils'

class ClusterUser
  @groups = Hash.new
  @num_users = 0
  @num_groups = 0
  
  class << self; attr_accessor :groups, :num_users, :num_groups end

  @qconf_exec = `which qconf`.to_s
  @qconf_exec = @qconf_exec.strip
  
  @scripts_dir = "scripts"
  
  # SGE Settings
  FUNC_TICKETS = 100000
  FUNC_FACTOR = 1.85

  def self.init
    # Compile group list
    ClusterUser.set_group
    
    # Get an LDAP connection
    @ldap = Net::LDAP.new(
      :host => LDAP_SERVER,
      :port => LDAP_PORT,
      :auth => {
        :method => :simple,
        :encryption => :simple_tls,
        :username => LDAP_USERNAME,
        :password => LDAP_PASSWORD,
      }
    )
    @ldap.bind
  end
  
  def self.search_by_group
    if @ldap.nil?
      ClusterUser.init
    end
    
    groups_array = Array.new
    
    ClusterUser.groups.each do |gid, group_name|
      
      filter = Net::LDAP::Filter.eq("gidnumber", gid)  
      search = { :base =>"dc=genomics,dc=upenn,dc=edu", :filter => filter }
      
      user_list = String.new
      @ldap.search(search) do |entry|
        entry.each do |attribute, values|
          values.each do |value|
            #puts "#{attribute.to_s} : #{value}"
            if attribute.to_s == "uid"
              if user_list.length == 0
                user_list += value
              else
                user_list += ",#{value}"
              end
            end
          end
        end
      end
      if user_list.length > 0
        group_array = Array.new
        group_array << group_name
        group_array << user_list
        groups_array << group_array
      end
    end
    @num_groups = groups_array.size
    return groups_array
  end

  def self.get_uids
    if @ldap.nil?
      ClusterUser.init
    end
    
    users = Hash.new
      
    #filter = Net::LDAP::Filter.eq("gidnumber", gid)  
    search = { :base =>"ou=people,dc=genomics,dc=upenn,dc=edu"}#, :filter => filter }
    
    @ldap.search(search) do |entry|
      uid = String.new
      uidnumber = String.new
      entry.each do |attribute, values|
        values.each do |value|
          #puts "#{attribute.to_s} : #{value}"
          case attribute.to_s
          when "uid"
            uid = value.to_s
          when "uidnumber"
            uidnumber = value.to_s
          end
        end
      end
      users[uid] = uidnumber unless uid == "" || uidnumber == "" || uid == "eberwine" || uid == "kai" || uid == "chekh" ||uidnumber.to_i < 500
    end
    return users
  end

  def self.set_group
    group_list = `getent group`
    group_list.each do |group|
      group_array = group.split(":")
      if group_array[2].to_i > 500
        ClusterUser.groups[group_array[2]] = group_array[0]
      end
    end
  end

  def self.create_sge_stree
    if ClusterUser.groups.size == 0
      ClusterUser.init
    end
    
    exec_script = "#{@scripts_dir}/create_sge_stree.sh"
    
    if File.file?(exec_script)
      File.delete(exec_script)
    end
    
    sge_childnodes = String.new
    
    ClusterUser.get_uids.values.each do |value|
      if sge_childnodes.length == 0
        sge_childnodes += value
      else
        sge_childnodes += ",#{value}"
      end
    end
    
    css_script_file = File.new(exec_script, "w")    
    css_script_file.write("#!/usr/bin/env bash\n# This is an automatically generated file from the ClusterUser ruby script\n\n#{@qconf_exec} -Astree #{Dir.getwd}/pgfi_cluster.stree\n")

    css_file = File.new("#{@scripts_dir}/pgfi_cluster.stree", "w")
    css_file.write("id=0\n")
    css_file.write("name=Root\n")
    css_file.write("type=0\n")
    css_file.write("shares=1\n")
    css_file.write("childnodes=1\n")
    css_file.write("id=1\n")
    css_file.write("name=sge\n")
    css_file.write("type=0\n")
    css_file.write("shares=#{ClusterUser.get_uids.size}\n")
    css_file.write("childnodes=#{sge_childnodes},499\n")
    
    ClusterUser.get_uids.each do |uid,uidnumber|
      css_file.write("id=#{uidnumber}\n")
      css_file.write("name=#{uid}\n")
      css_file.write("shares=1\n")
      css_file.write("childnodes=NONE\n")
    end
    
    css_file.write("id=1\n")
    css_file.write("name=default\n")
    css_file.write("type=0\n")
    css_file.write("shares=1\n")
    css_file.write("childnodes=NONE\n")
    
    css_file.close
    
    css_script_file.close

    File.chmod(0700, "#{Dir.getwd}/#{exec_script}")
  end
  
  def self.delete_sge_stree
    dsp_file = File.new("#{@scripts_dir}/delete_sge_stree.sh", "w")
    dsp_file.write("#!/usr/bin/env bash\n# This is an automatically generated file from the ClusterUser ruby script\n\n#{@qconf_exec} -dstree")
    dsp_file.close
    File.chmod(0700, "#{@scripts_dir}/delete_sge_stree.sh")
  end
  
  def self.delete_sge_users
    dsp_file = File.new("#{@scripts_dir}/delete_sge_users.sh", "w")
    dsp_file.write("#!/usr/bin/env bash\n# This is an automatically generated file from the ClusterUser ruby script\n\n")
    ClusterUser.search_by_group.each do |group_array|
      group_array[1].each do |user_list|
        user_list.split(",").each do |user|
          dsp_file.write("#{@qconf_exec} -duser #{user}\n")
        end
      end
    end
    dsp_file.close
    File.chmod(0700, "#{@scripts_dir}/delete_sge_users.sh")
  end
  
  def self.create_sge_users
    @num_users = 0
  
    if ClusterUser.groups.size == 0
      ClusterUser.init
    end
    
    exec_script = "#{@scripts_dir}/create_sge_users.sh"
    
    if File.file?(exec_script)
      File.delete(exec_script)
    end
    
    csu_script_file = File.new(exec_script, "w")    
    csu_script_file.write("#!/usr/bin/env bash\n# This is an automatically generated file from the ClusterUser ruby script\n\n")
    
    ClusterUser.search_by_group.each do |group_array|
      group_array[1].each do |user_list|
        user_list.split(",").each do |user|
          csu_file = File.new("#{@scripts_dir}/#{user}.usr", "w")
          csu_file.write("name            #{user}\n")
          csu_file.write("oticket         0\n")
          csu_file.write("fshare          0\n")
          csu_file.write("delete_time     0\n")
          csu_file.write("default_project NONE\n")
          csu_file.close
          File.chmod(0600, "#{@scripts_dir}//#{user}.usr")
          csu_script_file.write("#{@qconf_exec} -Auser #{Dir.getwd}/#{@scripts_dir}/#{user}.usr\n")
          @num_users += 1
        end
      end
    end
    
    csu_script_file.close

    File.chmod(0700, "#{Dir.getwd}/#{exec_script}")
  end
  
  # def self.delete_sge_projects
  #   dsp_file = File.new("#{@scripts_dir}/delete_sge_projects.sh", "w")
  #   dsp_file.write("#!/usr/bin/env bash\n# This is an automatically generated file from the ClusterUser ruby script\n\n")
  #   ClusterUser.search_by_group.each do |group_array|
  #     dsp_file.write("#{@qconf_exec} -dprj #{group_array[0]}\n")
  #   end
  #   dsp_file.close
  #   File.chmod(0700, "#{@scripts_dir}/delete_sge_projects.sh")
  # end
  
  # def self.create_sge_projects
  #   if ClusterUser.groups.size == 0
  #     ClusterUser.init
  #   end
  #   
  #   exec_script = "#{@scripts_dir}/create_sge_projects.sh"
  #   
  #   if File.file?(exec_script)
  #     File.delete(exec_script)
  #   end
  #   
  #   csp_script_file = File.new(exec_script, "w")    
  #   csp_script_file.write("#!/usr/bin/env bash\n# This is an automatically generated file from the ClusterUser ruby script\n\n")
  #       
  #   ClusterUser.search_by_group.each do |group_array|
  #     csp_file = File.new("#{@scripts_dir}/#{group_array[0]}.prj", "w")
  #     csp_file.write("name    #{group_array[0]}\n")
  #     csp_file.write("oticket 0\n")
  #     csp_file.write("fshare  #{FUNC_TICKETS/ClusterUser.groups.size}\n")
  #     csp_file.write("acl     NONE\n")
  #     csp_file.write("xacl    NONE\n")
  #     csp_file.close
  #     File.chmod(0600, "#{Dir.getwd}/#{@scripts_dir}/#{group_array[0]}.prj")
  #     csp_script_file.write("#{@qconf_exec} -Aprj #{Dir.getwd}/#{@scripts_dir}/#{group_array[0]}.prj\n")
  #   end
  #   
  #   csp_script_file.close
  # 
  #   File.chmod(0700, "#{Dir.getwd}/#{exec_script}")   
  # end
  
  def self.delete_sge_usersets
    dsu_file = File.new("#{@scripts_dir}/delete_sge_usersets.sh", "w")
    dsu_file.write("#!/usr/bin/env bash\n# This is an automatically generated file from the ClusterUser ruby script\n\n")
    ClusterUser.groups.each do |gid, group_name|
      dsu_file.write("#{@qconf_exec} -dul #{group_name}\n")
    end
    dsu_file.close
    File.chmod(0700, "#{@scripts_dir}/delete_sge_usersets.sh")
  end
  
  def self.create_sge_usersets
    if ClusterUser.groups.size == 0
      ClusterUser.init
    end
    
    exec_script = "#{@scripts_dir}/create_sge_usersets.sh"
    
    if File.file?(exec_script)
      File.delete(exec_script)
    end
    
    csu_script_file = File.new(exec_script, "w")    
    csu_script_file.write("#!/usr/bin/env bash\n# This is an automatically generated file from the ClusterUser ruby script\n\n")
    
    # Remove previously created usersets from scripts dir
    Dir.glob('scripts/*.lst') do |of|
      FileUtils.rm(of)
    end
    
    priv_entries = Array.new
    
    Dir.glob('*.lst').each do |dept|
      # Copy the modified userset into the scripts dir
      FileUtils.cp(dept, "scripts/#{dept}")
      File.readlines(dept).each do |line|
        if line =~ /^entries/
          la = line.split(" ")
          priv_entries = la[1].split(",")
        end
      end
    end
    
    ClusterUser.search_by_group.each do |group_array|
      # Remove users who already exist in privledged usersets
      users = String.new
      ga = group_array[1].split(",")
      ga.each do |user|
        if ! priv_entries.include?(user)
          users += user
          users += ","
        end
      end
      
      users = users[0...-1]
      
      #puts "Users: #{users}"
      
      if ! users.empty?
        csu_file = File.new("#{@scripts_dir}/#{group_array[0]}_userset.lst", "w")
        csu_file.write("name    #{group_array[0]}\n")
        csu_file.write("type    ACL DEPT\n")
        csu_file.write("fshare  #{((FUNC_TICKETS * FUNC_FACTOR).floor/ClusterUser.groups.size).floor.to_i}\n")
        csu_file.write("oticket 0\n")
        csu_file.write("entries #{users}\n")
        csu_file.write("\n")
        csu_file.close    
        File.chmod(0600, "#{Dir.getwd}/#{@scripts_dir}/#{group_array[0]}_userset.lst")
        csu_script_file.write("#{@qconf_exec} -Au #{Dir.getwd}/#{@scripts_dir}/#{group_array[0]}_userset.lst\n")
      end
    end
    
    csu_script_file.close
    
    File.chmod(0700, "#{Dir.getwd}/#{exec_script}")
  end

  def self.next_id
    base_uid = 21496
    base_gid = 3000
    users = `getent passwd`
    groups = `getent group`
    
    uid_array = Array.new
    users.each do |line|
      seg_line = line.split(":")
      uid_array << seg_line[2].strip.to_i
    end
    while uid_array.include?(base_uid)
      base_uid += 1
    end
    
    gid_array = Array.new
    groups.each do |line|
      seg_line = line.split(":")
      gid_array << seg_line[2].strip.to_i
    end
    while gid_array.include?(base_gid)
      base_gid += 1
    end 
    
    puts "\n"
    puts "Next available UID for a PGFI cluster user: #{base_uid}"
    puts "Next available GID for a PGFI cluster group: #{base_gid}"
    puts "\n"
  end
  
  def self.create_master_script
    master_exec_script = "#{@scripts_dir}/commit_sge_changes.sh"
    master_script_file = File.new(master_exec_script, "w")    
    master_script_file.write("#!/usr/bin/env bash\n# This is an automatically generated file from the ClusterUser ruby script\n\n")
    master_script_file.write("/root/ClusterUser/#{@scripts_dir}/delete_sge_users.sh;\n")
    master_script_file.write("/root/ClusterUser/#{@scripts_dir}/delete_sge_usersets.sh;\n")
    master_script_file.write("/root/ClusterUser/#{@scripts_dir}/create_sge_usersets.sh;\n")
    master_script_file.write("/root/ClusterUser/#{@scripts_dir}/create_sge_users.sh;\n")
    master_script_file.write("\n")
    master_script_file.close
    File.chmod(0700, "#{Dir.getwd}/#{master_exec_script}")
  end
  
end


# ClusterUser.create_sge_usersets
# ClusterUser.delete_sge_usersets
# ClusterUser.delete_sge_projects
# ClusterUser.create_sge_projects
# ClusterUser.create_sge_users
# ClusterUser.delete_sge_users
#ClusterUser.create_sge_stree
#ClusterUser.delete_sge_stree
