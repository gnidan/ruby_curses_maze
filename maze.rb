#!/usr/bin/ruby -w
#
# maze.rb
# (c) 2007 G. Nicholas D'Andrea
#
# Maintains the Maze class
#

require "node"

def opposite(direction)
  case direction
  when :north: :south
  when :south: :north
  when :east:  :west
  when :west:  :east
  end
end

class Maze
  def initialize(rows, columns)
    @cells = []

    0.upto(rows - 1) do |i|
      @cells[i] = []
      0.upto(columns - 1) do |j|
        @cells[i][j] = Node.new
        
        add_maze_support(@cells[i][j], i, j) \
          unless @cells[i][j].methods.include?("has_wall?")
        
        @cells[i][j][:north] = @cells[i-1][j] unless i==0
        @cells[i][j][:west]  = @cells[i][j-1] unless j==0
      end
    end

    @display_method = nil
    @solved = false
  end

  def height
    @cells.size
  end

  def width
    @cells[0].size
  end

  def [](row)
    @cells[row]
  end

  def generate!
    @cells = yield @cells if block_given?
  end

  def solve!(start = @cells[0][0], stop = @cells[-1][-1])
    return unless block_given?

    @cells.each do |row|
      row.each do |cell|
        unless cell.methods.include?("correct?")
          class <<cell
            def correct!
              @correct = true
            end

            def incorrect!
              @correct = false
            end

            def correct?
              @correct
            end

            def unknown!
              @correct = nil
            end
              
            def next=(direction)
              @next = @neighbors[direction]
              @next_direction = direction
            end

            def next
              @next_direction
            end

            def previous=(direction)
              @previous = @neighbors[direction]
              @previous_direction = direction
            end

            def previous
              @previous_direction 
            end
          end
        end
        
        cell.unknown!
        cell.next = nil
      end
    end

    @solved = yield start, stop if block_given?
  end

  def solved?
    @solved
  end

  def display_method=(p)
    @display_method = p
  end

  def display(port=$>)
    if block_given?
      port.write yield(@cells)
    elsif @display_method
      port.write @display_method.call(@cells)
    else
      port.write @@display_large.call(@cells)
    end
  end

  def to_s
    "<#{super}: #{height}x#{width} maze>"
  end

private

  def add_maze_support(cell, i, j)
    class <<cell
      def update(i, j)
        @x = j
        @y = i

        @walls = {}
      end

      def add_to_neighbors(direction, neighbor)
        super(direction, neighbor)
        
        @walls[neighbor] = true
      end

      def remove_from_neighbors(direction)
        @walls.delete(@neighbors[direction])
        
        super(direction)
      end

      def alter_wall(neighbor, value)
        @walls[neighbor] = value
      end
      
      def set_wall!(direction)
        if @neighbors.has_key?(direction)
          @walls[@neighbors[direction]] = true
          @neighbors[direction].alter_wall(self, true)
        end
      end

      def unset_wall!(direction)
        if @neighbors.has_key?(direction)
          @walls[@neighbors[direction]] = false
          @neighbors[direction].alter_wall(self, false)
        end
      end

      def has_wall?(direction)
        @walls[@neighbors[direction]] if @neighbors.has_key?(direction)
      end

      def unblocked_neighbors
        @neighbors.reject { |direction, neighbor| has_wall?(direction) }
      end

      protected :add_to_neighbors, :remove_from_neighbors, :alter_wall 
    end

    cell.update(i, j)
  end

  @@display_small = Proc.new do |maze|
    str = ""
    maze.each do |row|
      if row==maze[0]
        str << ' '
        row.each do |cell|
          str << '__' unless cell == row[0]
          str << '  ' if cell == row[0]
          str << '_' unless cell == row[-1] or cell == row[0]
          str << ' ' if cell == row[0]
        end
        str << "\n"
      end

      row.each do |cell|
        if cell.has_wall? :west or cell == row[0]
          str << '|'
        elsif (cell[:west] and cell[:west].has_wall? :south and
            cell.has_wall? :south) or row == maze[-1]
          str << '_'
        else
          str << ' '
        end

        if cell.has_wall?(:south) or row==maze[-1]
          str << '__' unless cell == row[-1] and row == maze[-1]
          str << '  ' if cell == row[-1] and row == maze[-1]
        else
          str << '  '
        end

        str << '|' if cell==row[-1]
      end
      
      str << "\n"
    end

    str
  end

  @@display_large = Proc.new do |maze|
    str = ""

    solved = maze[0][0].methods.include?("correct?") and
      maze[0][0].correct? ? true : false

    maze.each do |row|
      if row==maze[0]
        str << ' '
        row.each do |cell|
          str << '___' unless cell == row[0]
          str << '   ' if cell == row[0] unless solved
          str << ' . ' if cell == row[0] if solved
          str << '_' unless cell == row[-1] or cell == row[0]
          str << ' ' if cell == row[0]
        end
        str << "\n"
      end

      row.each do |cell|
        if cell.has_wall? :west or cell == row[0]
          str << '|'
        elsif solved and cell.correct? and 
          (cell.previous == :west or cell.next == :west)
          str << '.'
        else
          str << ' '
        end

        str << '   ' unless solved and cell.correct?
        if solved and cell.correct?
          str << (cell.previous == :west || cell.next == :west ? '.' : ' ')
          unless cell.previous == nil
            str << '.' unless cell.previous == :north or cell.next == :north
            str << ':' if cell.previous == :north or cell.next == :north
          else
            str << ':'
          end
          str << (cell.next == :east || cell.previous == :east ? '.' : ' ')
        end

        str << '|' if cell==row[-1]
      end

      str << "\n"

      row.each do |cell|
        if cell.has_wall? :west or cell == row[0]
          str << '|'
        elsif (cell[:west] and cell[:west].has_wall? :south and
            cell.has_wall? :south) or row == maze[-1]
          str << '_'
        else
          str << ' '
        end

        if cell.has_wall?(:south) or row==maze[-1]
          str << '___' unless cell == row[-1] and row == maze[-1]
          str << '   ' if cell == row[-1] and row == maze[-1] unless solved \
            and cell.correct? and cell.next == nil
          str << ' : ' if cell == row[-1] and row == maze[-1] and solved \
            and cell.correct? and cell.next == nil
        elsif solved and cell.correct? and 
          (cell.next == :south or cell.previous == :south)
          str << ' : '
        else
          str << '   '
        end

        str << '|' if cell==row[-1]
      end



      str << "\n"
    end

    str
  end
end

$dfs = Proc.new do |maze|
  y = rand(maze.size)
  x = rand(maze[y].size)


  maze.each do |row|
    row.each do |cell|
      class <<cell
        def visited=(value)
          @visited = value
        end
        
        def visited?
          @visited
        end

        def unvisited_neighbors
          @neighbors.reject { |directory, neighbor| neighbor.visited? }
        end
      end
      cell.visited = false
    end
  end

  unless defined? recurse_maze
    def recurse_maze(cell)
      cell.visited = true

      until (unvisited_neighbors = cell.unvisited_neighbors) == {}
        class <<unvisited_neighbors
          def random_key
            return keys[rand(keys.size)]
          end
        end 
        direction = unvisited_neighbors.random_key
        neighbor = cell[direction]

        cell.unset_wall! direction
        recurse_maze(neighbor)
      end
    end
  end

  recurse_maze(maze[y][x])

  maze

end

$solve = Proc.new do |start, stop|
  unless defined? solve_maze
    def solve_maze(cell, stop, previous=nil)
      unless cell.methods.include?("possible_neighbors")
        class <<cell
          def possible_neighbors
            unblocked_neighbors.reject { |d, n| n.correct? == false }
          end
        end
      end

      if cell==stop
        cell.correct!
        cell.previous = opposite(
          previous.unblocked_neighbors.reject { |d, n| n != cell }.keys[0]
                                ) if previous

        return true
      end
      
      cell.incorrect!

      until (possible_neighbors = cell.possible_neighbors) == {}
        class <<possible_neighbors
          def random_key
            return keys[rand(keys.size)]
          end
        end 
        direction = possible_neighbors.random_key
        neighbor = cell[direction]

        if solve_maze(neighbor, stop, cell)
          cell.next = direction

          cell.previous = nil unless previous

          cell.previous = opposite(
            previous.unblocked_neighbors.reject { |d, n| n != cell }.keys[0]
                                  ) if previous
            
          cell.correct!
          return true
        end
      end

      cell.next = nil
      cell.previous = nil

      return false
    end
  end

  solve_maze(start, stop)
end

