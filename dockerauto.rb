#!/usr/bin/ruby

require 'rubygems'
require 'json'
require 'optparse'

options = {}
options[:name] = ""
options[:list] = false
options[:refresh] = false
options[:command] = false

OptionParser.new do |opts|
  opts.banner = "Usage: dockerauto.rb [options]"

  opts.on("-n", "--name NAME or ID", "Container to run on") do |n|
    options[:name] = n
  end

  opts.on("-c", "--command", "Show run command") do |c|
    options[:command] = c
  end

  opts.on("-l", "--list", "List container info") do |l|
    options[:list] = l
  end

  opts.on("-r", "--refresh", "Refresh container if needed") do |r|
    options[:refresh] = r
  end
  
end.parse!
 
class DockerContainer
  def initialize info
    @info = info[0]
    $id = info[0]["Config"]["Hostname"]
    $image = info[0]["Config"]["Image"]
    $name = info[0]["Name"]
    @mounts = info[0]["HostConfig"]["Binds"]
    @ports = info[0]["HostConfig"]["PortBindings"]
    $restart = info[0]["HostConfig"]["RestartPolicy"]["Name"]
  end
  def displayConfig
    puts "Container ID => #{$id}"
    puts "Container From => #{$image}"
    puts "Mounted Volumes => #{@mounts}"
    puts "Port Bindings => #{@ports}"
    puts "Container Name => #{$name}"
    puts "Restart Policy => #{$restart}" 
  end
  def buildMounts 
    mountlist = ''
    if @mounts.to_s == ''
      return ""
    else
      @mounts.each do |m|
        mountlist = "-v #{m} "
      end     
      return mountlist.strip
    end
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
  def getStop
    cmdStop = "docker stop #{$id}"
    return cmdStop
  end
  def getDel
    cmdDel = "docker rm #{$id}"
    return cmdDel
  end
  def getRun
    cmdRun = "docker run -d --restart=#{$restart} --name=#{$name} " + self.buildPorts.to_s + " " + self.buildMounts.to_s + " #{$image}" 
    return cmdRun
  end
end

def inspectContainer(id)
  info = %x( docker inspect #{id} )
  infohash = JSON.parse(info)
  return infohash
end
unless options[:name] == ''
  if options[:list] == false && options[:command] == false && options[:refresh] == false
    puts "please provide -l(list config) -r(refreash container) or -c(show run command)" 
  else
    containerInfo = inspectContainer(options[:name])

    containertest = DockerContainer.new(containerInfo)

    if options[:list] == true
      containertest.displayConfig
    end
    if options[:command] == true
      puts containertest.getRun
    end
    if options[:refresh] == true
      puts containertest.getStop
      puts containertest.getDel
      puts containertest.getRun
    end
  end
else
  puts "-n contianer ID|NAME required"
end
