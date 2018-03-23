#!/usr/bin/env ruby
require 'ffi-ncurses'
require 'ffi-ncurses/widechars'
# ----------------------------------------------------------------------------- #
#         File: lyra.rb
#  Description: a quick small directory lister aimed at being simple fast with minimal
#       features, and mostly for viewing files quickly through PAGER
#       Author: j kepler  http://github.com/mare-imbrium/
#         Date: 2018-03-09 
#      License: MIT
#  Last update: 2018-03-23 18:37
# ----------------------------------------------------------------------------- #
#  lyra.rb  Copyright (C) 2012-2018 j kepler
#  == TODO
#  [ ] make a help screen on ?
#  [ ] move to lyra or some gem and publish
#  [ ] pop directories
#  [ ] go back to start directory
#  [ ] go to given directory
# [x] open files on RIGHT arrow in view (?)
# [ ] in a long listing, how to get to a file name. first char or pattern TODO
# [ ] pressing p should open PAGER, e EDITOR, m MOST, v - view
# [x] on zip file show contents in pager. x to extract.
# [x] when going up a directory keep cursor on the directory we came from 
# [x] space bar to page down. also page up on c-n c-p top bottom
# [x] hide dot files 
# [x] reveal dot files on toggle 
# [x] long listing files on toggle 
# [x] long file names not getting cleared 
# [ ] allow entry of command and page output or show in PAGER
# [x] pressing ENTER should invoke EDITOR
# [x] scrolling up behavior not correct. we should scroll up from first row not last. 
#     see vifm for correct way. mc has different behavior
#  ----------
#  == CHANGELOG
#
#
#  --------
#


BOLD = FFI::NCurses::A_BOLD
REVERSE = FFI::NCurses::A_REVERSE
UNDERLINE = FFI::NCurses::A_UNDERLINE
NORMAL = FFI::NCurses::A_NORMAL
COLOR_BLACK = FFI::NCurses::BLACK
COLOR_WHITE = FFI::NCurses::WHITE
COLOR_BLUE = FFI::NCurses::BLUE
COLOR_RED = FFI::NCurses::RED
COLOR_GREEN = FFI::NCurses::GREEN

def init_curses
  FFI::NCurses.initscr
  FFI::NCurses.curs_set 1
  FFI::NCurses.raw
  FFI::NCurses.noecho
  FFI::NCurses.keypad FFI::NCurses.stdscr, true
  FFI::NCurses.scrollok FFI::NCurses.stdscr, true
  if FFI::NCurses.has_colors
    FFI::NCurses.start_color
    std_colors
  end

end

# COLOR_BLACK   0
# COLOR_RED     1
# COLOR_GREEN   2
# COLOR_YELLOW  3
# COLOR_BLUE    4
# COLOR_MAGENTA 5
# COLOR_CYAN    6
# COLOR_WHITE   7

# In case, the init_pairs are changed, then update these as well, so that the programs use the correct pairs.
 CP_BLACK    = 0
 CP_RED      = 1
 CP_GREEN    = 2
 CP_YELLOW   = 3
 CP_BLUE     = 4
 CP_MAGENTA  = 5
 CP_CYAN     = 6
 CP_WHITE    = 7
# defining various colors
# NOTE this should be done by application or else we will be changing this all the time.
def std_colors
  FFI::NCurses.use_default_colors
  # 2018-03-17 - changing it to ncurses defaults
  FFI::NCurses.init_pair(0,  FFI::NCurses::BLACK,   -1)
  FFI::NCurses.init_pair(1,  FFI::NCurses::RED,   -1)
  FFI::NCurses.init_pair(2,  FFI::NCurses::GREEN,     -1)
  FFI::NCurses.init_pair(3,  FFI::NCurses::YELLOW,   -1)
  FFI::NCurses.init_pair(4,  FFI::NCurses::BLUE,    -1)
  FFI::NCurses.init_pair(5,  FFI::NCurses::MAGENTA,  -1)
  FFI::NCurses.init_pair(6,  FFI::NCurses::CYAN,    -1)
  FFI::NCurses.init_pair(7,  FFI::NCurses::WHITE,    -1)
  # ideally the rest should be done by application
  #FFI::NCurses.init_pair(8,  FFI::NCurses::WHITE,    -1)
  #FFI::NCurses.init_pair(9,  FFI::NCurses::BLUE,    -1)
  #FFI::NCurses.init_pair(10,  FFI::NCurses::BLACK, FFI::NCurses::CYAN)
  # alert
  FFI::NCurses.init_pair(12, FFI::NCurses::BLACK,   FFI::NCurses::BLUE)
  #FFI::NCurses.init_pair(13, FFI::NCurses::BLACK,   FFI::NCurses::MAGENTA)
#
# needed by menu
  FFI::NCurses.init_pair(14,  FFI::NCurses::WHITE, FFI::NCurses::CYAN)
end

# create and return a color_pair for a combination of bg and fg.
# This will always return the same color_pair so a duplicate one will not be created.
# @param bgcolor [Integer] color of background e.g., COLOR_BLACK
# @param fgcolor [Integer] color of foreground e.g., COLOR_WHITE
# @return [Integer] - color_pair which can be passed to #printstring, or used directly as #COLOR_PAIR(int)
def create_color_pair(bgcolor, fgcolor)
  code = (bgcolor*10) + fgcolor
  FFI::NCurses.init_pair(code, fgcolor, bgcolor)
  return code
end
#
## Window class 
#  Creates and manages the underlying window in which we write or place a form and fields.
#  The two important methods here are the constructor, and +destroy()+.
#  +pointer+ is important for making further direct calls to FFI::NCurses.
class Window 
  # pointer to FFI routines, use when calling FFI directly.
  attr_reader :pointer     # window pointer
  attr_reader :panel      # panel associated with window
  attr_reader :width, :height, :top, :left

  # creates a window with given height, width, top and left.
  # If no args given, creates a root window (i.e. full size).
  # @param  height [Integer]
  # @param  width [Integer]
  # @param  top [Integer]
  # @param  left [Integer]
  def initialize h=0, w=0, top=0, left=0
    @height, @width, @top, @left = h, w, top, left

    @height = FFI::NCurses.LINES if @height == 0   # 2011-11-14 added since tired of checking for zero
    @width = FFI::NCurses.COLS   if @width == 0
    @pointer = FFI::NCurses.newwin(@height, @width, @top, @left) # added FFI 2011-09-6 

    @panel = FFI::NCurses.new_panel(@pointer)
    FFI::NCurses.keypad(@pointer, true)
    return @pointer
  end

  # print string at x, y coordinates. replace this with the original one below
  # @deprecated
  def printstr(str, x=0,y=0)
    win = @pointer
    FFI::NCurses.wmove(win, x, y)
    FFI::NCurses.waddstr win, str
  end

  # 2018-03-08 - taken from canis reduced
  # print given string at row, col with given color and attributes
  # @param row [Integer]  row to print on
  # @param col [Integer]  column to print on
  # @param color [Integer] color_pair created earlier
  # @param attr [Integer] any of the four FFI attributes, e.g. A_BOLD, A_REVERSE
  def printstring(r,c,string, color=0, att = FFI::NCurses::A_NORMAL)

    #$log.debug "printstring recvd nil row #{r} or col #{c}, color:#{color},att:#{att}."  if $log
    raise "printstring recvd nil row #{r} or col #{c}, color:#{color},att:#{att} " if r.nil? || c.nil?
    att ||= FFI::NCurses::A_NORMAL
    color ||= 0
    raise "color is nil " unless color
    raise "att is nil " unless att

    FFI::NCurses.wattron(@pointer, FFI::NCurses.COLOR_PAIR(color) | att)
    FFI::NCurses.mvwprintw(@pointer, r, c, "%s", :string, string);
    FFI::NCurses.wattroff(@pointer, FFI::NCurses.COLOR_PAIR(color) | att)
  end
  ##
  # Get a key from the standard input.
  #
  # This will get control keys and function keys but not Alt keys.
  # This is usually called in a loop by the main program.
  # It returns the ascii code (integer).
  # 1 is Ctrl-a .... 27 is Esc
  # FFI already has constants declared for function keys and control keys for checkin against.
  # Can return a 3 or -1 if user pressed Control-C.
  #
  # NOTE: For ALT keys we need to check for 27/Esc and if so, then do another read
  # with a timeout. If we get a key, then resolve. Otherwise, it is just ESC
  # @return [Integer] ascii code of key
  def getch
    ch = FFI::NCurses.wgetch(@pointer)
  rescue SystemExit, Interrupt 
    3      # is C-c
  rescue StandardError
    -1     # is C-c
  end
  alias :getkey :getch

  # refresh the window (wrapper)
  # To be called after printing on a window.
  def wrefresh
    FFI::NCurses.wrefresh(@pointer)
  end
  # destroy the window and the panel. 
  # This is important. It should be placed in the ensure block of caller application, so it happens.
  def destroy
    FFI::NCurses.del_panel(@panel) if @panel
    FFI::NCurses.delwin(@pointer)   if @pointer
    @panel = @pointer = nil # prevent call twice
  end
  # route other methods to ffi. {{{
  # This should preferable NOT be used. Better to use the direct call itself.
  # It attempts to route other calls to FFI::NCurses by trying to add w to the name and passing the pointer.
  # I would like to remove this at some time.
  def method_missing(name, *args)
    name = name.to_s
    raise "method missing !!! #{name}"
    if (name[0,2] == "mv")
      test_name = name.dup
      test_name[2,0] = "w" # insert "w" after"mv"
      if (FFI::NCurses.respond_to?(test_name))
        return FFI::NCurses.send(test_name, @pointer, *args)
      end
    end
    test_name = "w" + name
    if (FFI::NCurses.respond_to?(test_name))
      return FFI::NCurses.send(test_name, @pointer, *args)
    end
    FFI::NCurses.send(name, @pointer, *args)
  end # }}}

  # make a box around the window. Just a wrapper
  def box
    FFI::NCurses.box(@pointer, 0, 0)
  end
  # print a centered title on top of window
  # This should be called after box, or else box will erase the title
  # @param str [String] title to print
  # @param color [Integer] color_pair 
  # @param att [Integer] attribute constant
  def title str, color=0, att=BOLD
    strl = str.length
    col = (@width - strl)/2
    printstring(0,col, str, color, att)
  end
end # window 

# a midnight commander like mc_menu
# Pass a hash of key and label.
# menu will only accept keys or arrow keys or C-c Esc to cancel
# returns nil if C-c or Esc pressed.
# Otherwise returns character pressed.
# == TODO 
# depends on our window class which is minimal.
# [ ] cursor should show on the row that is highlighted
# [ ] Can we remove that dependency so this is independent
# Currently, we paint window each time user pressed up or down, but we can just repaint the attribute
# [ ] width of array items not checked. We could do that or have user pass it in.
# [ ] we are not scrolling if user sends in a large number of items. we should cap it to 10 or 20
# == CHANGELOG
#
class Menu

  def initialize title, hash, config={}

    @list = hash.values
    @keys = hash.keys.collect { |x| x.to_s }
    @hash = hash
    bkgd = config[:bkgd] || FFI::NCurses.COLOR_PAIR(14) | BOLD
    @attr = BOLD
    @color_pair = config[:color_pair] || 14
    ht = @list.size+2
    wid = config[:width] || 40
    top = (FFI::NCurses.LINES - ht)/2
    left = (FFI::NCurses.COLS - wid)/2
    @window = Window.new(ht, wid, top, left)
    FFI::NCurses.wbkgd(@window.pointer, bkgd)
    @window.box
    @window.title(title)
    @current = 0
    print_items @hash
  end
  def print_items hash
    ix = 0
    hash.each_pair {|k, val|
      attr = @attr
      attr = REVERSE if ix == @current
      @window.printstring(ix+1 , 2, "#{k}    #{val}", @color_pair, attr )
      ix += 1
    }
    @window.wrefresh
  end
  def getkey # in menu
    ch = 0
    char = nil
    begin
      while (ch = @window.getkey) != FFI::NCurses::KEY_CTRL_C
        break if ch == 27 # ESC
        tmpchar = FFI::NCurses.keyname(ch) rescue '?'
        if @keys.include? tmpchar
          char = tmpchar
          break
        end
        case ch
        when FFI::NCurses::KEY_DOWN
          @current += 1
        when FFI::NCurses::KEY_UP
          @current -= 1
        when ?g.getbyte(0)
          @current_index = 0
        when ?G.getbyte(0)
          @current_index = @list.size-1
        when FFI::NCurses::KEY_RETURN
          char = @keys[@current]
          break
        end
        @current = 0 if @current < 0
        @current = @list.size-1 if @current >= @list.size
        print_items @hash

        # trap arrow keys here
      end
    ensure
      @window.destroy
    end
    return char
  end
end

# main program

TOPLINE="| ` Menu  | = Toggle | q Quit | lyra 0.1"
$sorto = "on"
$hidden = nil
$long_listing = false
$patt = nil
_LINES = FFI::NCurses.LINES-1
def create_footer_window h = 2 , w = FFI::NCurses.COLS, t = FFI::NCurses.LINES-2, l = 0
  ewin = Window.new(h, w , t, l)
end
def create_input_window h = 1 , w = FFI::NCurses.COLS, t = FFI::NCurses.LINES-1, l = 0
  ewin = Window.new(h, w , t, l)
end
# accepts user input in current window
# and returns characters after RETURN pressed
def getchars win, max=20
  str = ""
  pos = 0
  filler = " "*max
  pointer = win.pointer
  y, x = FFI::NCurses.getyx(pointer)
  while (ch = win.getkey) != FFI::NCurses::KEY_RETURN
    #str << ch.chr
    if ch > 27 and ch < 127
      str.insert(pos, ch.chr)
      pos += 1
      #FFI::NCurses.waddstr(win.pointer, ch.chr)
    end
    case ch
    when FFI::NCurses::KEY_LEFT 
      pos -= 1
      pos = 0 if pos < 0
    when FFI::NCurses::KEY_RIGHT
      pos += 1
      pos = str.size if pos >= str.size
    when 127
      pos -= 1 if pos > 0
      str.slice!(pos,1) if pos >= 0 # no backspace if on first pos
    when 27, FFI::NCurses::KEY_CTRL_C
      return nil
    end
    FFI::NCurses.wmove(pointer, y,x)
    FFI::NCurses.waddstr(pointer, filler)
    FFI::NCurses.wmove(pointer, y,x)
    FFI::NCurses.waddstr(pointer, str)
    FFI::NCurses.wmove(pointer, y,pos+1) # set cursor to correct position
    break if str.size >= max
  end
  str
end
# runs given command and returns.
# Does not wait, so command should be like an editor or be paged to less.
def shell_out command
      FFI::NCurses.endwin
      ret = system command
      FFI::NCurses.refresh
end

## code related to long listing of files
GIGA_SIZE = 1073741824.0
MEGA_SIZE = 1048576.0
KILO_SIZE = 1024.0

# Return the file size with a readable style.
def readable_file_size(size, precision)
  case
    #when size == 1 : "1 B"
  when size < KILO_SIZE then "%d B" % size
  when size < MEGA_SIZE then "%.#{precision}f K" % (size / KILO_SIZE)
  when size < GIGA_SIZE then "%.#{precision}f M" % (size / MEGA_SIZE)
  else "%.#{precision}f G" % (size / GIGA_SIZE)
  end
end
## format date for file given stat
def date_format t
  t.strftime "%Y/%m/%d"
end
# clears window but leaves top line
def clearwin(pointer)
      FFI::NCurses.wmove(pointer, 1,0)
      FFI::NCurses.wclrtobot(pointer)
end
## 
def file_edit win, fp 
  #$log.debug " edit #{fp}"
  editor = ENV['EDITOR'] || 'vi'
  vimp = %x[which #{editor}].chomp
  shell_out "#{vimp} #{fp}"
end
def file_open win, fp 
  unless File.exists? fp
    pwd = %x[pwd]
    #alert "No such file. My pwd is #{pwd} "
    alert win, "No such file. My pwd is #{pwd} "
    return
  end
  ft=%x[file #{fp}]
  if ft.index("text")
    file_edit win, fp
  elsif ft.index(/zip/i)
    shell_out "tar tvf #{fp} | less"
  elsif ft.index(/directory/i)
    shell_out "ls -lh  #{fp} | less"
  else
    alert "#{fp} is not text, not opening (#{ft}) "
  end
end
def file_page win, fp 
  unless File.exists? fp
    pwd = %x[pwd]
    alert "No such file. My pwd is #{pwd} "
    return
  end
  ft=%x[file #{fp}]
  if ft.index("text")
    pager = ENV['PAGER'] || 'less'
    vimp = %x[which #{pager}].chomp
    shell_out "#{vimp} #{fp}"
  elsif ft.index(/zip/i)
    shell_out "tar tvf #{fp} | less"
  elsif ft.index(/directory/i)
    shell_out "ls -lh  #{fp} | less"
  else
    alert "#{fp} is not text, not paging "
    #use_on_file "als", fp # only zip or archive
  end
end
def get_files
  #files = Dir.glob("*")
  files = `zsh -c 'print -rl -- *(#{$sorto}#{$hidden}M)'`.split("\n")
  if $patt
    files = files.grep(/#{$patt}/)
  end
  return files
end
# a quick simple list with highlight row, and scrolling
# 
# mark directories in color 
# @return start row
  def listing win, path, files, cur=0, pstart
    curpos = 1
    width = win.width-1
    y = x = 1
    ht = win.height-2
    #st = 0
    st = pstart           # previous start
    pend = pstart + ht -1 # previous end
    if cur > pend
      st = (cur -ht) +1
    elsif cur < pstart
      st = cur
    end
    hl = cur
    #if cur >= ht
      #st = (cur - ht ) +1
      #hl = cur
      ## we need to scroll the rows
    #end
    y = 0
    ctr = 0
    filler = " "*width
    files.each_with_index {|f, y| 
      next if y < st
      colr = CP_WHITE # white on bg -1
      ctr += 1
      mark = " "
      if y == hl
        attr = FFI::NCurses::A_REVERSE
        mark = ">"
        curpos = ctr
      else
        attr = FFI::NCurses::A_NORMAL
      end
      fullp = path + "/" + f

      if $long_listing
        begin
          unless File.exist? f
            last = f[-1]
            if last == " " || last == "@" || last == '*'
              stat = File.stat(f.chop)
            end
          else
            stat = File.stat(f)
          end
          f = "%10s  %s  %s" % [readable_file_size(stat.size,1), date_format(stat.mtime), f]
        rescue Exception => e
          f = "%10s  %s  %s" % ["?", "??????????", f]
        end
      end
      if File.directory? fullp
        #ff = "#{mark} #{f}/"
        # 2018-03-12 - removed slash at end since zsh puts it there
        ff = "#{mark} #{f}"
        colr = CP_BLUE # blue on background color_pair COLOR_PAIR
        attr = attr | FFI::NCurses::A_BOLD
      elsif File.executable? fullp
        ff = "#{mark} #{f}*"
        colr = CP_WHITE # yellow on background color_pair COLOR_PAIR
        attr = attr | FFI::NCurses::A_BOLD
      else
        ff = "#{mark} #{f}"
      end
      win.printstring(ctr, x, filler, colr )
      win.printstring(ctr, x, ff, colr, attr)
      break if ctr >= ht
    }
    #curpos = cur + 1
    #if curpos > ht
      #curpos = ht 
    #end
    #statusline(win, "#{cur+1}/#{files.size} #{files[cur]}. cur = #{cur}, pos:#{curpos},ht = #{ht} , hl #{hl}")
    statusline(win, "#{cur+1}/#{files.size} #{files[cur]}. (#{$sorto})                                ")
    FFI::NCurses.wmove(win.pointer,  curpos , 0) # +1 depends on offset of ctr 
    win.wrefresh
    return st
  end
  def statusline win, str
    win.printstring(win.height-1, 2, str, 1) # white on default
  end
  def alert str 
    win = create_footer_window
    # 10 is too much BLACK on CYAN
    FFI::NCurses.wbkgd(win.pointer, FFI::NCurses.COLOR_PAIR(12))
    win.printstring(0,1, str)
    win.wrefresh
    win.getkey
    win.destroy
  end
  def main_menu
    h = { :s => :sort_menu, :M => :newdir, "%" => :newfile }
    m = Menu.new "Main Menu", h
    ch = m.getkey
    return nil if !ch

    binding = h[ch]
    binding = h[ch.to_sym] unless binding
    if binding
      if respond_to?(binding, true)
        send(binding)
      end
    end
    return ch, binding
  end

  def sort_menu
    lo = nil
    h = { :n => :newest, :a => :accessed, :o => :oldest, 
          :l => :largest, :s => :smallest , :m => :name , :r => :rname, :d => :dirs, :c => :clear }
      m = Menu.new "Sort Menu", h
      ch = m.getkey
      return nil if !ch
      menu_text = h[ch.to_sym]
      case menu_text
      when :newest
        lo="om"
      when :accessed
        lo="oa"
      when :oldest
        lo="Om"
      when :largest
        lo="OL"
      when :smallest
        lo="oL"
      when :name
        lo="on"
      when :rname
        lo="On"
      when :dirs
        lo="/"
      when :clear
        lo=""
      end
      ## This needs to persist and be a part of all listings, put in change_dir.
      $sorto = lo
      #$files = `zsh -c 'print -rl -- *(#{lo}#{$hidden}M)'`.split("\n") if lo
  end

begin
  init_curses
  txt = "Press cursor keys to move window"
  win = Window.new
  pointer = win.pointer
  $ht = win.height
  $wid = win.width
  $pagecols = $ht / 2
  $spacecols = $ht
  #win.printstr txt
  win.printstr("Press Ctrl-Q to quit #{win.height}:#{win.width}", win.height-1, 20)

  path = File.expand_path("./")
  win.printstring(0,0, "PATH: #{path}                 #{TOPLINE}",0)
  files = get_files
  current = 0
  prevstart = listing(win, path, files, current, 0)

  ch = 0
  xx = 1
  yy = 1
  y = x = 1
  while (ch = win.getkey) != 113
    #y, x = win.getbegyx(pointer)
    old_y, old_x = y, x
    case ch
    when FFI::NCurses::KEY_RIGHT
      # if directory then open it
      fullp = path + "/" + files[current]
      if File.directory? fullp
        Dir.chdir(files[current])
        $patt = nil
        path = Dir.pwd
        #win.printstring(0,0, "PATH: #{path}                 ",0)
        win.printstring(0,0, "PATH: #{path}                 #{TOPLINE}",0)
        files = get_files
        current = 0
        FFI::NCurses.wclrtobot(pointer)
        #win.wclrtobot
      elsif File.readable? fullp
        file_page win, fullp
        win.wrefresh
        # open file
      end
      x += 1
    when FFI::NCurses::KEY_LEFT
      # go back higher level
      oldpath = path
      Dir.chdir("..")
      path = Dir.pwd
      $patt = nil
      win.printstring(0,0, "PATH: #{path}                 #{TOPLINE}",0)
      files = get_files
      # when going up, keep focus on the dir we came from
      current = files.index(File.basename(oldpath) + "/")
      current = 0 if current.nil? or current == -1
      #win.wclrtobot
      FFI::NCurses.wclrtobot(pointer)
      x -= 1
    when FFI::NCurses::KEY_RETURN
      # if directory then open it
      fullp = path + "/" + files[current]
      if File.directory? fullp
        Dir.chdir(files[current])
        $patt = nil
        path = Dir.pwd
        #win.printstring(0,0, "PATH: #{path}                 ",0)
        win.printstring(0,0, "PATH: #{path}                 #{TOPLINE}",0)
        files = get_files
        #files = Dir.entries("./")
        #files.delete(".")
        #files.delete("..")
        current = 0
        FFI::NCurses.wclrtobot(pointer)
        #win.wclrtobot
      elsif File.readable? fullp
        # open file
        file_open win, fullp
        win.wrefresh
      end
    when FFI::NCurses::KEY_UP, ?k.getbyte(0)
      current -=1
    when FFI::NCurses::KEY_DOWN, ?j.getbyte(0)
      current +=1
    when FFI::NCurses::KEY_CTRL_N
      current += $pagecols
    when FFI::NCurses::KEY_CTRL_P
      current -= $pagecols
    when 32, FFI::NCurses::KEY_CTRL_D
      current += $spacecols
    when ?g.getbyte(0)
      current = 0
    when ?G.getbyte(0)
      current = files.size-1
    when FFI::NCurses::KEY_BACKSPACE, FFI::NCurses::KEY_CTRL_B, 127
      current -= $spacecols
    when FFI::NCurses::KEY_CTRL_X
    when ?=.getbyte(0)
      #list = ["x this", "y that","z other","a foo", "b bar"]
      list = { "h" => "hidden files toggle", "l" => "long listing toggle", "z" => "the other", "a" => "another one", "b" => "yet another" }
      m = Menu.new "Toggle Options", list
      key = m.getkey
      win.wrefresh # otherwise menu popup remains till next key press.
      case key
      when 'h'
        $hidden = $hidden ? nil : "D"
        files = get_files
        clearwin(pointer)
      when 'l'
        $long_listing = !$long_listing 
        clearwin(pointer)
      end
    when ?/.getbyte(0)
      # search grep
      # this is writing over the last line of the listing
      ewin = create_input_window
      ewin.printstr("/", 0, 0)
      #win.wmove(1, _LINES-1)
      str = getchars(ewin, 10)
      ewin.destroy
      #alert "Got #{str}"
      $patt = str #if str
      files = get_files
      clearwin(pointer)
    when ?`.getbyte(0)
      main_menu
      files = get_files
      clearwin(pointer)
    else
      alert("key #{ch} not known")
    end
    #win.printstr("Pressed #{ch} on #{files[current]}    ", 0, 70)
    current = 0 if current < 0
    current = files.size-1 if current >= files.size
    # listing does not refresh files, so if files has changed, you need to refresh
    prevstart = listing(win, path, files, current, prevstart)
    win.wrefresh
  end

rescue Object => e
  @window.destroy if @window
  FFI::NCurses.endwin
  puts e
  puts e.backtrace.join("\n")
ensure
  @window.destroy if @window
  FFI::NCurses.endwin
  puts 
end
