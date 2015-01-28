#!/usr/bin/ruby

require 'rubygems'
require 'json'

id = "e00d28c84924"

class DockerContainer
  def initialize info
    @info = info
    @id = info[0]["Config"]["Hostname"]
    @mounts = info[0]["HostConfig"]["Binds"]
    @image = info[0]["Config"]["Image"]
  end
  def display
    puts "My Container ID is #{@id} from #{@image} and my volumes are #{@mounts}"
  end
end

def inspectContainer(id)
  info = %x( docker inspect #{id} )
  infohash = JSON.parse(info)
  return infohash
end

containerInfo = inspectContainer(id)

nzbget = DockerContainer.new(containerInfo)
nzbget.display
