class Utils
  COLUMN_WIDTH = 30

  def self.podspec_version(file = 'SwiftGen')
    JSON.parse(`bundle exec pod ipc spec SwiftGen/#{file}.podspec`)["version"]
  end

  def self.plist_version
    Plist::parse_xml('SwiftGen/Sources/Info.plist')['CFBundleVersion']
  end

  # print a header
  def self.print_header(str)
    puts "== #{str.chomp} ==".format(:yellow, :bold)
  end

  # print an info message
  def self.print_info(str)
    puts str.chomp.format(:green)
  end

  # print an error message
  def self.print_error(str)
    puts str.chomp.format(:red)
  end

  # format an info message in a 2 column table
  def self.table_info(label, msg)
    puts "#{label.ljust(COLUMN_WIDTH)} 👉  #{msg}"
  end

  # format a result message in a 2 column table
  def self.table_result(result, label, error_msg)
    if result
      puts "#{label.ljust(COLUMN_WIDTH)} ✅"
    else
      puts "#{label.ljust(COLUMN_WIDTH)} ❌  - #{error_msg}"
    end
    result
  end
end

class String
  def to_bool
    return true if self =~ (/^(true|t|yes|y|1)$/i)
    return false if self.empty? || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new "invalid value: #{self}"
  end

  # colorization
  FORMATTING = {
    # text styling
    :bold => 1,
    :faint => 2,
    :italic => 3,
    :underline => 4,
    # foreground colors
    :black => 30,
    :red => 31,
    :green => 32,
    :yellow => 33,
    :blue => 34,
    :magenta => 35,
    :cyan => 36,
    :white => 37,
    # background colors
    :bg_black => 40,
    :bg_red => 41,
    :bg_green => 42,
    :bg_yellow => 43,
    :bg_blue => 44,
    :bg_magenta => 45,
    :bg_cyan => 46,
    :bg_white => 47
  }

  def format(*styles)
    if `tput colors`.chomp.to_i >= 8
      styles.reduce("") { |r, s| r << "\e[#{FORMATTING[s]}m" } << "#{self}\e[0m"
    else
      self
    end
  end
end
