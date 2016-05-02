#!/usr/bin/ruby

require 'rubygems'
require 'json'
require 'optparse'

options = {}
options[:container] = ""
options[:list] = false
options[:refresh] = false
options[:showcommand] = false
options[:force] = false
options[:all] = false


OptionParser.new do |opts|
  opts.banner = "Usage: docker-auto.rb -c[--container] <container name or id> [options]"

  opts.on("-c", "--container NAME or ID", "Container to run on") do |c|
    options[:container] = c
  end

  opts.on("-a", "--all", "do for all containers") do |a|
    options[:all] = a
  end

  opts.on("-s", "--showcommand", "Show run command") do |s|
    options[:showcommand] = s
  end

  opts.on("-l", "--list", "List container info") do |l|
    options[:list] = l
  end

  opts.on("-r", "--refresh", "Refresh container if needed") do |r|
    options[:refresh] = r
  end

  opts.on("-f", "--force", "Force refresh of container") do |f|
    options[:force] = f
  end
end.parse!

class DockerContainer
  def initialize info
    @info = info[0]
    $id = info[0]["Config"]["Hostname"]
    $image = info[0]["Config"]["Image"]
    $imageid = info[0]["Image"][7, 12]
    $name = info[0]["Name"]
    @mounts = info[0]["HostConfig"]["Binds"]
    @ports = info[0]["HostConfig"]["PortBindings"]
    $restart = info[0]["HostConfig"]["RestartPolicy"]["Name"]
    $tty = info[0]["Config"]["Tty"]
  end
  def displayConfig
    puts "Container ID => #{$id}"
    puts "Container Image ID => #{$imageid}"
    puts "Container Image => #{$image}"
    puts "Mounted Volumes => #{@mounts}"
    puts "Port Bindings => #{@ports}"
    puts "Container Name => #{$name}"
    puts "Restart Policy => #{$restart}"
    puts "TTY Flag => #{$tty}"
  end
  def buildMounts
    mountlist = ''
    if @mounts.to_s == ''
      return ""
    else
      @mounts.each do |m|
        mountlist += "-v #{m} "
      end
      return mountlist.strip
    end
  end
  def buildOptions
    runOpts = ''
    if $tty == true
      runOpts += "-t "
    end
    return runOpts.strip
  end
  def buildPorts
    portConfig = ''
    @ports.each do |p|
      containerPort = p[0]
      bindIP = p[1][0]["HostIp"]
      bindPort = p[1][0]["HostPort"]
      if bindIP == ''
        portConfig += "-p #{bindPort}:#{containerPort} "
      else
        portConfig += "-p #{bindIP}:#{bindPort}:#{containerPort} "
      end
    end
    return portConfig.strip
  end
  def getImage
    return $image
  end
  def getImageId
    return $imageid
  end
  def getId
    return $id
  end
  def getStop
    cmdStop = "docker stop #{$id}"
    return cmdStop
  end
  def getDel
    cmdDel = "docker rm #{$id}"
    return cmdDel
  end
  def getRun
    cmdRun = "docker run -d --restart=#{$restart} --name=#{$name} " + self.buildOptions.to_s + self.buildPorts.to_s + " " + self.buildMounts.to_s + " #{$image}"
    return cmdRun
  end
end

def inspectContainer(id)
  info = %x( docker inspect #{id} )
  infohash = JSON.parse(info)
  return infohash
end

def checkNewImage(image, id)
  latest = %x( docker images #{image} | grep latest | awk '{ print $3 }' )
  if id.strip != latest.strip
    return true
  else
    info = %x( docker pull #{image} )
    if info.include? "Status: Image is up to date for"
      return false
    else
      return true
    end
  end
end

def getAllContainers
  listContainers = %x( docker ps -a | awk 'NR>1{print $1}' )
  return listContainers
end

unless options[:container] == '' && options[:all] == false
  if options[:list] == false && options[:showcommand] == false && options[:refresh] == false
    puts "Please provide one of the following: -l[--list] -r[--refreash] -p[--pull] or -s[--showcommand]"
  else
    if options[:all] == true
      containerList = getAllContainers()
    else
      containerList= options[:container]
    end

    containerList.each_line do |c|
      puts "--------RUNNING FOR CONTAINER #{c.strip}--------"
      containerInfo = inspectContainer(c)

      containertest = DockerContainer.new(containerInfo)

      if options[:list] == true
        containertest.displayConfig
      end
      if options[:showcommand] == true
        puts containertest.getRun
      end
      if options[:refresh] == true
        refreshNeeded = checkNewImage(containertest.getImage, containertest.getImageId)
        if refreshNeeded == true || options[:force] == true
          puts "Please run the below commands"
          puts "Stopping container....."
          runStop = `#{containertest.getStop}`
          puts runStop
          puts "Deleting container....."
          runDel = `#{containertest.getDel}`
          puts runDel
          puts "Starting container....."
          runRun = `#{containertest.getRun}`
          puts runRun
        else
          puts "No Refresh Needed"
        end
      end
    end
  end
else
  puts "-c <contianer ID or NAME> required"
end
