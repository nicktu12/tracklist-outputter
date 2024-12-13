require 'io/console'
require 'curses'

# Initialize Curses
Curses.init_screen
Curses.start_color
Curses.init_pair(1, Curses::COLOR_GREEN, Curses::COLOR_BLACK) # Green stars on black
Curses.init_pair(2, Curses::COLOR_WHITE, Curses::COLOR_BLACK) # White text on black
Curses.init_pair(3, Curses::COLOR_BLUE, Curses::COLOR_BLACK) # Blue stars
Curses.init_pair(4, Curses::COLOR_RED, Curses::COLOR_BLACK) # Red stars
Curses.init_pair(5, Curses::COLOR_YELLOW, Curses::COLOR_BLACK) # Yellow stars
Curses.init_pair(6, Curses::COLOR_MAGENTA, Curses::COLOR_BLACK) # Magenta stars for pulsing
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

  # Shooting stars state
  stars = Array.new(10) do
    {
      position: [rand(screen.maxy), rand(screen.maxx)],
      size: rand(5..8),
      color: rand(1..5),
      pulse: rand(0..1),
    }
  end

  # Background grid effect
  grid = Array.new(screen.maxy) { Array.new(screen.maxx) { rand(10) == 0 ? '.' : ' ' } }

  # Animation loop
  loop do
    screen.clear

    # Draw background grid
    screen.attron(Curses.color_pair(2)) do
      grid.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          screen.setpos(y, x)
          screen.addstr(cell)
        end
      end
    end

    # Update grid for subtle animation
    grid.each_with_index do |row, y|
      row.map! { |cell| rand(10) == 0 ? '.' : ' ' }
    end

    # Draw shooting stars
    stars.each do |star|
      y, x = star[:position]
      size = star[:size]
      color = star[:color]
      pulse = star[:pulse]

      screen.attron(Curses.color_pair(pulse.zero? ? color : 6)) do
        size.times do |i|
          break if y + i >= screen.maxy || x + i >= screen.maxx
          screen.setpos(y + i, x + i)
          screen.addstr("*")
        end
      end

      # Move star down and to the right
      star[:position][0] += 1
      star[:position][1] += 1

      # Toggle pulse state
      star[:pulse] = 1 - star[:pulse]

      # Reset star position if it goes off screen
      if star[:position][0] >= screen.maxy || star[:position][1] >= screen.maxx
        star[:position] = [rand(screen.maxy / 4), rand(screen.maxx)]
        star[:size] = rand(5..8)
        star[:color] = rand(1..5)
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
