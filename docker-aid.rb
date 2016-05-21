#!/usr/bin/ruby

require 'rubygems'
require 'json'
require 'optparse'

options = {}
options[:container] = ''
options[:list] = false
options[:refresh] = false
options[:showcommand] = false
options[:force] = false
options[:all] = false

OptionParser.new do |opts|
  opts.banner = 'Usage: docker-auto.rb -c[--container] <container name or id> [options]'

  opts.on('-c', '--container NAME or ID', 'Container to run on') do |c|
    options[:container] = c
  end

  opts.on('-a', '--all', 'do for all containers') do |a|
    options[:all] = a
  end

  opts.on('-s', '--showcommand', 'Show run command') do |s|
    options[:showcommand] = s
  end

  opts.on('-l', '--list', 'List container info') do |l|
    options[:list] = l
  end

  opts.on('-r', '--refresh', 'Refresh container if needed') do |r|
    options[:refresh] = r
  end

  opts.on('-f', '--force', 'Force refresh of container') do |f|
    options[:force] = f
  end
end.parse!

# initialize docker container info
class DockerContainer
  def initialize(info)
    @info = info[0]
    @id = info[0]['Config']['Hostname']
    @image = info[0]['Config']['Image']
    @imageid = info[0]['Image'][7, 12]
    @name = info[0]['Name']
    @mounts = info[0]['HostConfig']['Binds']
    @ports = info[0]['HostConfig']['PortBindings']
    @restart = info[0]['HostConfig']['RestartPolicy']['Name']
    @tty = info[0]['Config']['Tty']
  end

  def display_config
    puts "Container ID => #{@id}"
    puts "Container Image ID => #{@imageid}"
    puts "Container Image => #{@image}"
    puts "Mounted Volumes => #{@mounts}"
    puts "Port Bindings => #{@ports}"
    puts "Container Name => #{@name}"
    puts "Restart Policy => #{@restart}"
    puts "TTY Flag => #{@tty}"
  end

  def build_mounts
    return '' if @mounts.to_s == ''
    mountlist = ''
    @mounts.each do |m|
      mountlist += "-v #{m} "
    end
    mountlist.strip
  end

  def build_options
    run_opts = ''
    run_opts += '-t ' if @tty == true
    run_opts.strip
  end

  def build_ports
    port_config = ''
    @ports.each do |p|
      container_port = p[0]
      bind_ip = p[1][0]['HostIp']
      bind_port = p[1][0]['HostPort']
      port_config += if bind_ip.nil?
                       "-p #{bind_port}:#{container_port}"
                     else
                       "-p #{bind_ip}:#{bind_port}:#{container_port}"
                     end
    end
    port_config.strip
  end

  def show_image
    @image
  end

  def show_imageid
    @imageid
  end

  def show_id
    @id
  end

  def show_cmd_stop
    "docker stop #{@id}"
  end

  def show_cmd_del
    "docker rm #{@id}"
  end

  def show_cmd_run
    "docker run -d --restart=#{@restart} --name=#{@name} " + build_options.to_s + ' ' + build_ports.to_s + ' ' + build_mounts.to_s + " #{@image}"
  end
end

def inspect_container(id)
  info = `docker inspect #{id}`
  infohash = JSON.parse(info)
  infohash
end

def check_new_image(image, id)
  latest = `docker images #{image} | grep latest | awk '{ print $3 }'`
  return true if id.strip != latest.strip
  info = `docker pull #{image}`
  return false if info.include? 'Status: Image is up to date for'
  true
end

def show_all_containers
  `docker ps -a | awk 'NR>1{print $1}'`
end

if options[:container] != '' && options[:all] != false
  puts '-c <contianer ID or NAME> or -a required'
elsif options[:list] == false && options[:showcommand] == false && options[:refresh] == false
  puts 'Please provide one of the following: -l[--list] -r[--refreash] or -s[--showcommand]'
else
  container_list = if options[:all] == true
                     show_all_containers
                   else
                     options[:container]
                   end

  container_list.each_line do |c|
    puts "--------RUNNING FOR CONTAINER #{c.strip}--------"
    container_info = inspect_container(c)

    container = DockerContainer.new(container_info)

    container.display_config if options[:list] == true
    puts container.show_cmd_run if options[:showcommand] == true
    next unless options[:refresh] == true
    refresh_needed = check_new_image(container.show_image, container.show_imageid)
    if refresh_needed == true || options[:force] == true
      puts 'Please run the below commands'
      puts 'Stopping container.....'
      run_stop = `#{container.show_cmd_stop}`
      puts run_stop
      puts 'Deleting container.....'
      run_del = `#{container.show_cmd_del}`
      puts run_del
      puts 'Starting container.....'
      run_run = `#{container.show_cmd_run}`
      puts run_run
    else
      puts 'No Refresh Needed'
    end
  end
end
