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
    mountlist = ''
    if @mounts.to_s == ''
      return ''
    else
      @mounts.each do |m|
        mountlist += "-v #{m} "
      end
      return mountlist.strip
    end
  end

  def build_options
    run_opts = ''
    if @tty == true
      run_opts += '-t '
    end
    run_opts.strip
  end

  def build_ports
    port_config = ''
    @ports.each do |p|
      container_port = p[0]
      bind_ip = p[1][0]['HostIp']
      bind_port = p[1][0]['HostPort']
      if bind_ip == ''
        port_config += "-p #{bind_port}:#{container_port} "
      else
        port_config += "-p #{bind_ip}:#{bind_port}:#{container_port} "
      end
    end
    port_config.strip
  end

  def getImage
    @image
  end

  def getImageId
    @imageid
  end

  def getId
    @id
  end

  def getStop
    cmd_stop = "docker stop #{@id}"
    cmd_stop
  end

  def getDel
    cmd_del = "docker rm #{@id}"
    cmd_del
  end

  def getRun
    cmd_run = "docker run -d --restart=#{@restart} --name=#{@name} " + build_options.to_s + build_ports.to_s + " " + build_mounts.to_s + " #{@image}"
    cmd_run
  end
end

def inspect_container(id)
  info = `docker inspect #{id}`
  infohash = JSON.parse(info)
  infohash
end

def checkNewImage(image, id)
  latest = `docker images #{image} | grep latest | awk '{ print $3 }'`
  if id.strip != latest.strip
    return true
  else
    info = `docker pull #{image}`
    if info.include? 'Status: Image is up to date for'
      return false
    else
      return true
    end
  end
end

def getAllContainers
  list_containers = `docker ps -a | awk 'NR>1{print $1}'`
  list_containers
end

unless options[:container] == '' && options[:all] == false
  if options[:list] == false && options[:showcommand] == false && options[:refresh] == false
    puts 'Please provide one of the following: -l[--list] -r[--refreash] -p[--pull] or -s[--showcommand]'
  else
    if options[:all] == true
      container_list = getAllContainers()
    else
      container_list = options[:container]
    end

    containerList.each_line do |c|
      puts "--------RUNNING FOR CONTAINER #{c.strip}--------"
      container_info = inspect_container(c)

      container = DockerContainer.new(container_info)

      if options[:list] == true
        container.display_config
      end
      if options[:showcommand] == true
        puts container.getRun
      end
      if options[:refresh] == true
        refreshNeeded = checkNewImage(container.getImage, container.getImageId)
        if refreshNeeded == true || options[:force] == true
          puts 'Please run the below commands'
          puts 'Stopping container.....'
          runStop = `#{container.getStop}`
          puts runStop
          puts 'Deleting container.....'
          runDel = `#{container.getDel}`
          puts runDel
          puts 'Starting container.....'
          runRun = `#{container.getRun}`
          puts runRun
        else
          puts 'No Refresh Needed'
        end
      end
    end
  end
else
  puts '-c <contianer ID or NAME> or -a required'
end
