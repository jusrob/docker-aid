#!/usr/bin/ruby

require 'rubygems'
require 'json'

# set to hardcoded container ID for now
id = "e00d28c84924"

containerInfo = inspectContainer(id)

class DockerContainer
  def initialize id
    @id = id
    @mounts = containerInfo[0]["Volumes"]
  end
  def display
    puts "My Container ID is #{@id} and my volumes are #{@mounts}"
  end
end

def inspectContainer(id)
  info = %x{ docker inspect #{$id}}
  infohash = JSON.parse(info)
  return infohash
end
