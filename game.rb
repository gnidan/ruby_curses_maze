#!/usr/bin/ruby -w
#
# (c) 2007 G. Nicholas D'Andrea
#

require 'curses'
include Curses

require 'maze'

def make_maze
  rows = (Curses::lines - 2) / 2
  columns = (Curses::cols - 1) / 4

  m = Maze.new(rows, columns)
  m.generate!(&$dfs)

  return m
end

def draw_maze(m)
  s = ""
  class <<s
    def write(s)
      concat(s)
    end
  end

  m.display s
  setpos(0, 0)
  addstr(s)
  addstr("Use arrows; (n)ew; (r)estart; (q)uit\n")
  refresh
end

init_screen
m = make_maze

begin
  crmode
  noecho
  stdscr.keypad(true)

  c = m[0][0]

  draw_maze m

  loop do
    direction = case getch
                when ?Q, ?q     : break
                when Key::UP    : :north
                when Key::DOWN  : :south
                when Key::LEFT  : :west
                when Key::RIGHT : :east
                when ?N, ?n     : m = make_maze; c = m[0][0]; nil
                when ?R, ?r     : c = m[0][0]; m.solve!(c, c, &$solve); nil
                end
    if c[direction] and not c.has_wall?(direction)
      c = c[direction] unless direction == nil
      m.solve!(m[0][0], c, &$solve)
    end

    draw_maze m
  end
ensure
  close_screen
end

