require 'colorize'
require 'terminfo'

class ConsoleTable

  def self.define(layout, options={}, &block)
    table = ConsoleTable.new(layout, options)
    table.print_header
    block.call(table)
    table.print_footer
  end

  def initialize(column_layout, options={})
    @original_column_layout = column_layout
    @left_margin = options[:left_margin] || 0
    @right_margin = options[:right_margin] || 0
    @out = options[:output] || $stdout
    @title = options[:title]

    @footer_lines = []

    @headings_printed = false
    @count = 0

    calc_column_widths
    Signal.trap('SIGWINCH', proc { calc_column_widths })
  end

  def print_header()
    @out.print " " * @left_margin
    @out.print "=" * @working_width
    @out.print "\n"

    if not @title.nil? and @title.length <= @working_width
      @out.print " "*@left_margin
      left_side = (@working_width - @title.uncolorize.length)/2
      right_side = (@working_width - @title.uncolorize.length) - left_side
      @out.print " "*left_side
      @out.print @title
      @out.print " "*right_side
      @out.print "\n"
    end
  end

  def print_headings()
    @headings_printed = true
    @out.print " "*@left_margin

    @column_widths.each_with_index do |column, i|
      justify = column[:justify] || :left
      title = (column[:title] || column[:key].to_s.capitalize).strip
      @out.print format(column[:size], title, false, justify)
      @out.print " " if i < @column_widths.size-1
    end
    @out.print "\n"

    @out.print " " * @left_margin
    @out.print "-" * @working_width
    @out.print "\n"
  end

  def add_footer(line)
    lines = line.split("\n")
    lines.each do |l|
      @footer_lines << l.strip unless l.nil? or l.uncolorize.strip == ""
    end
  end

  def print_footer()
    should_print_footer = @footer_lines.length > 0 && @footer_lines.any? { |l| l.uncolorize.length <= @working_width }

    if should_print_footer
      @out.print " " * @left_margin
      @out.print "-" * @working_width
      @out.print "\n"
    end

    @footer_lines.each do |line|
      if line.uncolorize.length <= @working_width
        @out.print " " * @left_margin
        @out.print " " * (@working_width - line.uncolorize.length)
        @out.print line
        @out.print "\n"
      end
    end

    @out.print " " * @left_margin
    @out.print "=" * @working_width
    @out.print "\n"
  end

  def print_plain(to_print)
    @out.print " "*@left_margin

    if to_print.is_a? String
      @out.print format(@working_width, normalize(to_print))
    elsif to_print.is_a? Hash
      color = to_print[:color] || :default
      background = to_print[:background] || :default
      text = normalize(to_print[:text]) || ""
      ellipsize = to_print[:ellipsize] || false
      justify = to_print[:justify] || :left
      mode = to_print[:mode] || :default

      formatted=format(@working_width, text, ellipsize, justify)
      if text != :default or background != :default or mode != :default
        formatted = formatted.colorize(:color => color, :background => background, :mode => mode)
      end
      @out.print formatted
    end

    @out.print "\n"
  end

  def print(options)
    print_headings unless @headings_printed

    @out.print " "*@left_margin
    #column order is set, so go through each column and look up values in the incoming options
    @column_widths.each_with_index do |column, i|
      to_print = options[column[:key]] || ""
      justify = column[:justify] || :left
      if to_print.is_a? String
        @out.print format(column[:size], normalize(to_print), false, justify)
      elsif to_print.is_a? Hash
        color = to_print[:color] || :default
        background = to_print[:background] || :default
        text = normalize(to_print[:text]) || ""
        ellipsize = to_print[:ellipsize] || false
        highlight = to_print[:highlight]
        justify = to_print[:justify] || justify #can override
        mode = to_print[:mode] || :default

        formatted=format(column[:size], text, ellipsize, justify)

        if color != :default or background != :default or mode != :default
          formatted = formatted.colorize(:color => color, :background => background, :mode => mode)
        end

        unless (to_print[:highlight].nil?)
          highlight_regex = to_print[:highlight][:regex] || /wontbefoundbecauseit'sgobbledygookblahblahblahbah/
          highlight_color = to_print[:highlight][:color] || :blue
          highlight_background = to_print[:highlight][:background] || :default

          formatted = formatted.gsub(highlight_regex, '\0'.colorize(:color => highlight_color, :background => highlight_background))
        end

        @out.print formatted
      else
        @out.print format(column[:size], normalize(to_print.to_s))
      end

      @out.print " " if i < @column_widths.size-1
    end
    @out.print "\n"

    @count = @count + 1
  end

  private
  def normalize(string)
    if string.nil?
      nil
    else
      string.to_s.gsub(/\s+/, " ").strip #Primarily to remove any tabs or newlines
    end
  end

  def calc_column_widths()
    @column_widths = []

    begin
      total_width = TermInfo.screen_columns
    rescue => ex
      total_width = ENV["COLUMNS"].to_i || 79
    end

    keys = @original_column_layout.reject{|d| d[:key].nil?}.collect { |d| d[:key] }.uniq
    if keys.length < @original_column_layout.length
      raise("ConsoleTable configuration invalid, same key defined more than once")
    end

    num_spacers = @original_column_layout.length - 1
    set_sizes = @original_column_layout.collect { |x| x[:size] }.find_all { |x| x.is_a? Integer }
    used_up = set_sizes.inject(:+) || 0
    available = total_width - used_up - @left_margin - @right_margin - num_spacers

    if available <= 0
      raise("ConsoleTable configuration invalid, current window is too small to display required sizes")
    end

    percentages = @original_column_layout.collect { |x| x[:size] }.find_all { |x| x.is_a? Float }
    percent_used = percentages.inject(:+) || 0

    if percent_used > 1.0
      raise("ConsoleTable configuration invalid, percentages total value greater than 100%")
    end

    percent_available = 1 - percent_used
    stars = @original_column_layout.collect { |x| x[:size] or x[:size].nil?}.find_all { |x| x.is_a? String }
    num_stars = [stars.length, 1].max
    percent_for_stars = percent_available.to_f / num_stars

    @original_column_layout.each do |column_config|
      if column_config[:size].is_a? Integer
        @column_widths << column_config #As-is when integer
      elsif column_config[:size].is_a? Float
        @column_widths << column_config.merge({:size => (column_config[:size]*available).floor})
      elsif column_config[:size].nil? or column_config[:size].is_a?(String) && column_config[:size] == "*"
        @column_widths << column_config.merge({:size => (percent_for_stars*available).floor})
      else
        raise("ConsoleTable configuration invalid, '#{column_config[:size]}' is not a valid size")
      end
    end

    @working_width = (@column_widths.inject(0) { |res, c| res+c[:size] }) + @column_widths.length - 1
  end

  def format(length, text, ellipsize=false, justify=:left)
    if text.length > length
      if ellipsize
        text[0, length-3] + '...'
      else
        text[0, length]
      end
    else
      if justify == :right
        (" "*(length-text.length)) + text
      elsif justify == :center
        space = length-text.length
        left_side = space/2
        right_side = space - left_side
        (" " * left_side) + text + (" "*right_side)
      else #assume left
        text + (" "*(length-text.length))
      end
    end
  end
end