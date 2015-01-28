#!/usr/bin/ruby

class DockerContainer
  def initialize id
    @id = id
  end
  def display
    puts "My Container ID is #{@id}"
  end
end

test = DockerContainer.new(5)

test.display
