# ConsoleTable allows you to define a table with columns set to specific sizes,
# and then give that table rows of data which it will format into a view that fits
# inside a terminal/console.
#
# Author::    Rod Hilton
# License::   MIT
module ConsoleTable

  # Define a console table.  Requires a table layout which specifies column information
  # like sizes, titles, and key names.
  def self.define(layout, options={}, &block)
    table = ConsoleTableClass.new(layout, options)
    table.send(:print_header)
    block.call(table)
    table.send(:print_footer)
  end

  class ConsoleTableClass
    require 'terminfo'

    # Add strings to the footer array to have them formatted when the table closes
    attr_reader :footer

    # Add rows to the table.  Prints immediately, consult documentation for examples
    def <<(options)
      print(options)
    end

    protected

    def initialize(column_layout, options={})
      @original_column_layout = []

      if column_layout.is_a? Fixnum
        column_layout = (1..column_layout).collect{|i| "Column #{i}"}
      end

      if column_layout.is_a? Array
        column_layout.each_with_index do |layout, i|
          if layout.is_a? String
            @original_column_layout << {:key => "col#{i+1}".to_sym, :title=>layout, :size=>"*"}
          elsif layout.is_a? Fixnum
            @original_column_layout << {:key => "col#{i+1}".to_sym, :title=>"Column #{i+1}", :size=>layout}
          elsif layout.is_a? Float
            @original_column_layout << {:key => "col#{i+1}".to_sym, :title=>"Column #{i+1}", :size=>layout}
          elsif layout[:key].nil? and layout[:title].nil?
            @original_column_layout << layout.merge({:key => "col#{i+1}".to_sym, :title=>"Column #{i+1}"})
          elsif layout[:title].nil?
            @original_column_layout << layout.merge({:title => layout[:key].to_s.capitalize})
          elsif layout[:key].nil?
            @original_column_layout << layout.merge({:key => "col#{i+1}".to_sym})
          else
            @original_column_layout << layout
          end
        end
      else
        raise("Column layout invalid, must be a num of columns or an array of column definitions")
      end

      #Mostly used for mocking/testing
      @out = options[:output] || $stdout
      @set_width = options[:width]

      @title = options[:title]
      @borders = options[:borders] || false #Lines between every cell, implies outline
      @left_margin = options[:left_margin] || 0
      @right_margin = options[:right_margin] || 0
      @headings = options[:headings].nil? ? true : options[:headings]
      @ellipse = options[:ellipse] || "..."

      #Set outline, just the upper and lower lines
      if @borders
        @outline = true
      elsif not options[:outline].nil?
        @outline = options[:outline]
      else
        @outline = true
      end

      @footer = []
      @headings_printed = false
      @count = 0

      calc_column_widths
      Signal.trap('SIGWINCH', proc { calc_column_widths })
    end

    def print_header()
      #Kind of weird but basically if there's a title, there will be a space between the top border and the actual data, meaning we don't
      #want special characters printed for the "joining" of the lines.  If there's no title, however, we do.
      if @title.nil?
        print_line("=", "*", false)
      else
        print_line("=", "*", true)
      end if @outline

      unless @title.nil?
        @out.print " "*@left_margin
        @out.print "|" if @borders
        @out.print format(@working_width, @title, false, :center)
        @out.print "|" if @borders
        @out.print "\n"
        print_line if @borders
      end
    end

    def print_footer()
      if should_print_footer
        print_line
      end

      footer_lines.each do |line|
          @out.print " " * @left_margin
          @out.print "|" if @borders
          @out.print format(@working_width, line, false, :right)
          @out.print "|" if @borders
          @out.print "\n"
      end

      if should_print_footer
        print_line("=", "*", true)
      else
        print_line("=", "*", false)
      end if @outline
    end

    private

    def print_headings()
      @headings_printed = true

      @out.print " "*@left_margin
      if @borders
        @out.print "|"
      end

      @column_widths.each_with_index do |column, i|
        justify = column[:justify] || :left
        ellipsize = column[:ellipsize] || false
        title = column[:title].strip
        @out.print format(column[:size], title, ellipsize, justify)

        if @borders
          @out.print "|"
        else
          @out.print " " if i < @column_widths.size-1
        end
      end
      @out.print "\n"

      print_line unless @borders #this line will be printed when the NEXT LINE of actual data prints out if borders are on, because that call PRE-prints the separator line
    end

    def print_line(char="-", join_char="+", edge_join_only=false)
      if @borders #use +'s to join columns
        @out.print " " * @left_margin
        @out.print join_char
        @column_widths.each_with_index do |column, i|
          @out.print char*column[:size]
          if edge_join_only and i < @column_widths.length - 1
            @out.print char
          else
            @out.print join_char
          end
        end
        @out.print "\n"
      else #just print long lines
        @out.print " " * @left_margin
        @out.print "#{char}" * (@working_width + (@borders ? 2 : 0))
        @out.print "\n"
      end
    end

    def should_print_footer
      footer_lines.length > 0
    end

    def footer_lines
      footer_lines = []
      @footer.each do |line|
        lines = line.split("\n")
        lines.each do |l|
          footer_lines << l.strip unless l.nil? or uncolorize(l).strip == ""
        end
      end
      footer_lines
    end

    def print(options)

      if options.is_a? String
        print_plain(options)
        return
      end

      print_headings unless @headings_printed or not @headings

      if options.is_a? Array #If an array or something is supplied, infer the order from the heading order
        munged_options = {}
        options.each_with_index do |element, i|
          munged_options[@original_column_layout[i][:key]] = element
        end

        options = munged_options
      end


      print_line if @borders unless not @headings and @count == 0

      @out.print " "*@left_margin
      if @borders
        @out.print "|"
      end
      #column order is set, so go through each column and look up values in the incoming options
      @column_widths.each_with_index do |column, i|
        to_print = options[column[:key]] || ""
        justify = column[:justify] || :left
        ellipsize = column[:ellipsize] || false

        if to_print.is_a? String
          justify = infer_justify_from_string(to_print, justify)

          @out.print format(column[:size], normalize(to_print), ellipsize, justify)
        elsif to_print.is_a? Hash
          justify = infer_justify_from_string(to_print[:text], justify)

          text = normalize(to_print[:text]) || ""

          ellipsize = to_print[:ellipsize] unless to_print[:ellipsize].nil?
          justify = to_print[:justify] unless to_print[:justify].nil?

          formatted=format(column[:size], text, ellipsize, justify)

          @out.print formatted
        else
          text = to_print.to_s
          justify = infer_justify_from_string(text, justify)
          @out.print format(column[:size], normalize(text), ellipsize, justify)
        end

        if @borders
          @out.print "|"
        else
          @out.print " " if i < @column_widths.size-1
        end
      end
      @out.print "\n"

      @count = @count + 1
    end

    def infer_justify_from_string(to_print, justify)
      uncolorized = uncolorize(to_print)
      if uncolorized.start_with?("\t") and uncolorized.end_with?("\t")
        justify = :center
      elsif uncolorized.start_with?("\t")
        justify = :right
      elsif uncolorized.end_with?("\t")
        justify = :left
      end
      justify
    end

    def normalize(string)
      if string.nil?
        nil
      else
        normalized = string.to_s
        normalized = normalized.sub(/^(\e\[\d[^m]*?m)(\s+)/, '\2\1') #Any leading spaces preceeded by a color code should be swapped with the color code itself, so the spaces themselves aren't colored
        normalized = normalized.sub(/(\s+)(\e\[\d[^m]*?m)$/, '\2\1')
        normalized = normalized.gsub(/\s+/, " ").strip #Primarily to remove any tabs or newlines
        normalized
      end
    end

    def calc_column_widths()
      @column_widths = []

      total_width = @set_width
      begin
        total_width = TermInfo.screen_columns
      rescue => ex
        total_width = ENV["COLUMNS"].to_i unless ENV["COLUMNS"].nil?
        total_width = 79 if total_width.nil?
      end if total_width.nil?

      keys = @original_column_layout.collect { |d| d[:key] }.uniq
      if keys.length < @original_column_layout.length
        raise("ConsoleTable configuration invalid, same key defined more than once")
      end

      num_spacers = @original_column_layout.length - 1
      num_spacers = num_spacers + 2 if @borders
      set_sizes = @original_column_layout.collect { |x| x[:size] }.find_all { |x| x.is_a? Integer }
      used_up = set_sizes.inject(:+) || 0
      available = total_width - used_up - @left_margin - @right_margin - num_spacers

      if available < 0
        raise("ConsoleTable configuration invalid, current window is too small to display required sizes")
      end

      percentages = @original_column_layout.collect { |x| x[:size] }.find_all { |x| x.is_a? Float }
      percent_used = percentages.inject(:+) || 0

      if percent_used > 1.0
        raise("ConsoleTable configuration invalid, percentages total value greater than 100%")
      end

      percent_available = 1 - percent_used
      stars = @original_column_layout.collect { |x| x[:size] or x[:size].nil? }.find_all { |x| x.is_a? String }
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


    def uncolorize(string)
      string.gsub(/\e\[\d[^m]*?m/m, "")
    end

    def format(length, text, ellipsize=false, justify=:left)
      uncolorized = uncolorize(text)
      if uncolorized.length > length

        ellipsize = false if uncolorize(@ellipse).length >= length

        if ellipsize
          goal_length = length-uncolorize(@ellipse).length
        else
          goal_length = length
        end

        parts = text.scan(/(\e\[\d.*?m)|(.)/) #The idea here is to break the string up into control codes and single characters
        #We're going to now count up until we hit goal length, but we're not going to ever count control codes against the count
        #We're also going to keep track of if a non-resetting control code is 'active', so we know to reset at the end if need-be

        #I can't think of a better way to do this, it's probably dumb
        current_length = 0
        current_index = 0
        final_string_parts = []
        color_active = false

        while current_length < goal_length
          color_code, regular_text = parts[current_index]
          if not regular_text.nil?
            current_length = current_length + 1
            final_string_parts << regular_text
          elsif not color_code.nil?
            if color_code == "\e[0m"
              color_active = false if color_active
            else
              color_active = true
            end
            final_string_parts << color_code
          end
          current_index = current_index + 1
        end

        final_string_parts << @ellipse if ellipsize
        final_string_parts << "\e[0m" if color_active

        final_string_parts.join("")
      else
        space = length-uncolorized.length
        if justify == :right
          (" "*space) + text
        elsif justify == :center
          left_side = space/2
          right_side = space - left_side
          (" " * left_side) + text + (" "*right_side)
        else #assume left
          text + (" "*space)
        end
      end
    end

    def print_plain(to_print)
      print_line if @borders

      @out.print " "*@left_margin
      @out.print "|" if @borders

      if to_print.is_a? String
        justify = infer_justify_from_string(to_print, :left)
        @out.print format(@working_width, normalize(to_print), false, justify)
      end

      @out.print "|" if @borders
      @out.print "\n"
    end
  end
end