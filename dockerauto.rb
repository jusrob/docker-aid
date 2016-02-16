#!/usr/bin/ruby

require 'rubygems'
require 'json'
require 'optparse'

options = {}
options[:container] = ""
options[:list] = false
options[:refresh] = false

OptionParser.new do |opts|
  opts.banner = "Usage: dockerauto.rb [options]"

  opts.on("-c", "--container NAME or ID", "Container to run on") do |c|
    options[:container] = c
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
  def display
    puts "Container ID is #{$id}"
    puts "From #{$image}"
    puts "Mounted volumes are #{@mounts}"
    puts "Port Binding are #{@ports}"
    puts "Name is #{$name}"
    puts "Restart Policy is #{$restart}" 
  end
  def buildMounts 
    mountlist = ''
    @mounts.each do |m|
      mountlist = "-v #{m} "
    end     
    return mountlist.strip
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
  def buildRun
    puts "docker run -d --restart=#{$restart} --name=#{$name} " + self.buildPorts.to_s + " " + self.buildMounts.to_s + " #{$image}" 
  end
end

def inspectContainer(id)
  info = %x( docker inspect #{id} )
  infohash = JSON.parse(info)
  return infohash
end
unless options[:container] == ''
  containerInfo = inspectContainer(options[:container])

  containertest = DockerContainer.new(containerInfo)
  if options[:list] == true
    containertest.display
  end
  if options[:refresh] == true
    containertest.buildRun
  end
else
  puts "-c CONTAINER ID|NAME required"
end

