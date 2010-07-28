#!/usr/bin/ruby -w
#
# node.rb
# (c) 2007 G. Nicholas D'Andrea
#
# Maintains the Node class
#

class Node
  def initialize(neighbors = {})
    @neighbors = {}

    neighbors.each { |direction, neighbor| add_neighbor(direction, neighbor) }
  end

  def [](direction)
    @neighbors[direction]
  end

  def []=(direction, neighbor)
    add_neighbor(direction, neighbor)
  end

  def add_neighbor(direction, neighbor)
    neighbor.remove_neighbor(opposite(direction))
    
    add_to_neighbors(direction, neighbor)
    neighbor.add_to_neighbors(opposite(direction), self)
  end

  def remove_neighbor(direction)
    if @neighbors[direction]
      @neighbors[direction].remove_from_neighbors(opposite(direction))
    end

    remove_from_neighbors(direction)
  end

  def size
    @neighbors.size
  end

protected
  
  def add_to_neighbors(direction, neighbor)
    @neighbors[direction] = neighbor
  end

  def remove_from_neighbors(direction)
    @neighbors.delete(direction)
  end
end
