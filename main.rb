require 'io/console'
require 'curses'

# Initialize Curses
Curses.init_screen
Curses.start_color
Curses.init_pair(1, Curses::COLOR_GREEN, Curses::COLOR_BLACK) # Matrix green on black
Curses.init_pair(2, Curses::COLOR_WHITE, Curses::COLOR_BLACK) # White on black
Curses.noecho
Curses.curs_set(0)
Curses.timeout = 0 # Non-blocking input

begin
  # Load songs from a text file passed as a command-line argument
  if ARGV.empty?
    puts "Usage: ruby lofi_tv_display.rb <playlist.txt>"
    exit
  end

  playlist_file = ARGV[0]
  unless File.exist?(playlist_file)
    puts "Error: File \"#{playlist_file}\" not found."
    exit
  end

  # Read file in binary mode and force UTF-8 encoding
  songs = File.readlines(playlist_file, mode: 'rb').map do |line|
    line.force_encoding('UTF-8')
        .encode('UTF-8', invalid: :replace, undef: :replace)
        .gsub("\0", '')
        .gsub(/[\p{C}]/, '') # Remove non-printable characters
        .strip
  end.reject(&:empty?)

  screen = Curses.stdscr
  screen.keypad(true)
  
  # Simulate a Matrix-style rain effect
  matrix_columns = Array.new(screen.maxx) { rand(screen.maxy) }

  # Animation loop
  loop do
    screen.clear
    screen.attron(Curses.color_pair(1)) do
      # Draw Matrix-style rain
      matrix_columns.each_with_index do |y, x|
        next if x % 2 != 0 # Add spacing between columns
        screen.setpos(y, x)
        screen.addstr((33 + rand(93)).chr) # Random printable character
        matrix_columns[x] = (y + 1) % screen.maxy
      end
    end

    # Display song titles in the center
    screen.attron(Curses.color_pair(2)) do
      songs.each_with_index do |song, idx|
        y = screen.maxy / 2 + idx - songs.size / 2
        x = (screen.maxx - song.length) / 2
        screen.setpos(y, x)
        screen.addstr(song)
      end
    end

    screen.refresh
    sleep(0.1)

    # Break loop on user input
    break if screen.getch
  end
ensure
  # Restore terminal settings
  Curses.close_screen
end
