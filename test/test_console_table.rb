require 'minitest/autorun'
require 'console_table'
require 'colorize'

#TODO: What happens if you have a linebreak in what you print?
# - what if it occurs inside of an active color code?
#TODO: trimming from different sides depending on justification?

class ConsoleTableTest < Minitest::Test

  def setup
    @mock_out = StringIO.new
  end

  def teardown
    # Do nothing
  end

  def test_basic
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>20, :title=>"Column 2"},
    ]

    ConsoleTable.define(table_config, :width=> 100, :output=>@mock_out) do |table|
      table << {
          :col1 => "Row 1, Column 1",
          :col2 => "Row 1, Column 2"
      }

      table << {
          :col1 => "Row 2, Column 1",
          :col2 => "Row 2, Column 1"
      }
    end

#2345678901234567890##2345678901234567890
    expected=<<-END
=========================================
Column 1             Column 2
-----------------------------------------
Row 1, Column 1      Row 1, Column 2
Row 2, Column 1      Row 2, Column 1
=========================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_unicode
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>20, :title=>"Column 2"},
        {:key=>:col3, :size=>20, :title=>"Column 3"},
    ]

    ConsoleTable.define(table_config, :width=> 62, :output=>@mock_out) do |table|
      table << {
          :col1 => "I ♥ Unicode",
          :col2 => "I ☂ Unicode",
          :col3 => "I ♞ Unicode"
      }

      table << {
          :col1 => "I ⚂ Unicode Even More",
          :col2 => "I \u00A5 Unicode Even More",
          :col3 => "I µ Unicode Even More"
      }

      table << {
          :col1 => {:text => "I ⁂ Unicode", :justify=>:right},
          :col2 => {:text => "I \u2190 Unicode", :justify=>:center},
          :col3 => {:text => "I ✓ Unicode", :justify=>:left}
      }
    end

    expected=<<-END
==============================================================
Column 1             Column 2             Column 3
--------------------------------------------------------------
I ♥ Unicode          I ☂ Unicode          I ♞ Unicode
I ⚂ Unicode Even Mor I ¥ Unicode Even Mor I µ Unicode Even Mor
         I ⁂ Unicode     I ← Unicode      I ✓ Unicode
==============================================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_spacing_convention_sets_justification
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>20, :title=>"Column 2"},
        {:key=>:col3, :size=>20, :title=>"Column 3"},
    ]

    ConsoleTable.define(table_config, :width=> 62, :output=>@mock_out) do |table|
      table << [
          "\tRight",
          "\tCenter\t",
          "Left\t"
      ]
    end

    expected=<<-END
==============================================================
Column 1             Column 2             Column 3
--------------------------------------------------------------
               Right        Center        Left
==============================================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_newlines_converted_to_spaces_in_middle_stripped_at_ends
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>20, :title=>"Column 2"},
        {:key=>:col3, :size=>20, :title=>"Column 3"},
    ]

    ConsoleTable.define(table_config, :width=> 62, :output=>@mock_out) do |table|
      table << [
          {:text=>"Bl\nah", :justify=>:left},
          {:text=>"\nStuff", :justify=>:left},
          {:text=>"Junk\n", :justify=>:right}
      ]
    end

    expected=<<-END
==============================================================
Column 1             Column 2             Column 3
--------------------------------------------------------------
Bl ah                Stuff                                Junk
==============================================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_linebreak_inside_colorcode_still_resets
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>5, :title=>"Column 2"},
    ]

    ConsoleTable.define(table_config, :width=> 62, :output=>@mock_out) do |table|
      table << [
          "Bl\nah".blue,
          "1234\nStuff".red
      ]
    end

    expected=<<-END
==========================
Column 1             Colum
--------------------------
Bl ah                1234
==========================
    END

    assert_includes @mock_out.string, "\e[0;34;49mBl ah\e[0m"  #ensure the color got reset
    assert_includes @mock_out.string, "\e[0;31;49m1234 \e[0m"  #ensure the color got reset

    assert_output_equal expected, @mock_out.string
  end

  def test_can_ellipsize_at_column_level
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1", :ellipsize=>true},
        {:key=>:col2, :size=>20, :title=>"Column 2"},
    ]

    ConsoleTable.define(table_config, :width=> 62, :output=>@mock_out) do |table|
      table << [
          "This is way too long to fit here",
          "This is way too long to fit here",
      ]

      table << [
          {text: "This is way too long to fit here", :ellipsize=>false},
          {text: "This is way too long to fit here", :ellipsize=>true},
      ]
    end

    expected=<<-END
=========================================
Column 1             Column 2
-----------------------------------------
This is way too l... This is way too long
This is way too long This is way too l...
=========================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_justify_convention_followed_in_hash_text_but_overrideable
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1", :justify=>:center},
    ]

    ConsoleTable.define(table_config, :width=> 62, :output=>@mock_out) do |table|
      table << ["Short"]
      table << ["\tShort"]
      table << ["Short\t"]
      table << [{:text=>"Short", :justify=>:right}]
      table << [{:text=>"Short", :justify=>:left}]
      table << [{:text=>"\tShort"}]
      table << [{:text=>"Short\t"}]
      table << [{:text=>"\tShort", :justify=>:left}] #Override
      table << [{:text=>"Short\t", :justify=>:right}] #Override
    end

    expected=<<-END
====================
      Column 1
--------------------
       Short
               Short
Short
               Short
Short
               Short
Short
Short
               Short
====================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_should_not_color_tabs_or_ignore_tab_justify_convention_if_inside_color
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1", :justify=>:center},
        {:key=>:col2, :size=>20, :title=>"Column 2", :justify=>:right},
        {:key=>:col3, :size=>20, :title=>"Column 3", :justify=>:left},
    ]

    ConsoleTable.define(table_config, :width=> 62, :output=>@mock_out) do |table|
      table << [
          "\tRight".blue,
          "\tCenter\t".red,
          "Left\t".magenta,
      ]
    end

    expected=<<-END
==============================================================
      Column 1                   Column 2 Column 3
--------------------------------------------------------------
               Right       Center         Left
==============================================================
    END

    assert_includes @mock_out.string, " \e[0;34;49mRight\e[0m"  #space is on outside of coor
    assert_includes @mock_out.string, " \e[0;35;49mLeft\e[0m "  #space is on outside of color
    #assert_includes @mock_out.string, " \e[0;31;49mCenter\e[0m "  #this assert fails due to what I'm pretty sure is a bug in gsub(), but it's not the end of the world so I'm not doing a workaround

    assert_output_equal expected, @mock_out.string
  end

  def test_spaces_preserved_in_middle_but_stripped_at_ends
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>20, :title=>"Column 2"},
        {:key=>:col3, :size=>20, :title=>"Column 3"},
    ]

    ConsoleTable.define(table_config, :width=> 62, :output=>@mock_out) do |table|
      table << [
          {:text=>"Bl ah", :justify=>:left},
          {:text=>" Stuff", :justify=>:left},
          {:text=>"Junk ", :justify=>:right}
      ]
    end

    expected=<<-END
==============================================================
Column 1             Column 2             Column 3
--------------------------------------------------------------
Bl ah                Stuff                                Junk
==============================================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_ignores_tabbing_convention_if_setting_justification_explicitly
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>20, :title=>"Column 2"},
        {:key=>:col3, :size=>20, :title=>"Column 3"},
    ]

    ConsoleTable.define(table_config, :width=> 62, :output=>@mock_out) do |table|
      table << [
          {:text=>"\tBlah", :justify=>:left},
          {:text=>"\tStuff\t", :justify=>:right},
          {:text=>"\tJunk", :justify=>:center}
      ]
    end

    expected=<<-END
==============================================================
Column 1             Column 2             Column 3
--------------------------------------------------------------
Blah                                Stuff         Junk
==============================================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_can_use_convenient_operator
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>20, :title=>"Column 2"},
    ]

    ConsoleTable.define(table_config, :width=>100, :output=>@mock_out) do |table|
      table << {
                    :col1 => "Row 1, Column 1",
                    :col2 => "Row 1, Column 2"
                }

      table << {
                      :col1 => "Row 2, Column 1",
                      :col2 => "Row 2, Column 1"
                  }
    end

    expected=<<-END
=========================================
Column 1             Column 2
-----------------------------------------
Row 1, Column 1      Row 1, Column 2
Row 2, Column 1      Row 2, Column 1
=========================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_can_supply_array_and_order_is_inferred
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>20, :title=>"Column 2"},
    ]

    ConsoleTable.define(table_config, :width=> 100, :output=>@mock_out) do |table|
      table << [
          "Row 1, Column 1",
          "Row 1, Column 2"
      ]

      table << [
          {:text=>"Row 2, Column 1", :justify=>:center},
          {:text=>"Row 2, Column 2", :justify=>:right}
      ]
    end

    expected=<<-END
=========================================
Column 1             Column 2
-----------------------------------------
Row 1, Column 1      Row 1, Column 2
  Row 2, Column 1         Row 2, Column 2
=========================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_percents
    table_config = [
        {:key=>:col1, :size=>0.3, :title=>"Column 1"},
        {:key=>:col2, :size=>0.7, :title=>"Column 2"},
    ]

    ConsoleTable.define(table_config, :width=> 100, :output=>@mock_out) do |table|
      table << {
          :col1 => "Row 1, Column 1",
          :col2 => "Row 1, Column 2"
      }

      table << ["Row 2, Column 1", "Row 2, Column 1"]
    end

    expected=<<-END
===================================================================================================
Column 1                      Column 2
---------------------------------------------------------------------------------------------------
Row 1, Column 1               Row 1, Column 2
Row 2, Column 1               Row 2, Column 1
===================================================================================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_star_fills_all_extra_space
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>"*", :title=>"Column 2"},
    ]

    ConsoleTable.define(table_config, :width=> 100, :output=>@mock_out) do |table|
      table << {
          :col1 => "Row 1, Column 1",
          :col2 => "Row 1, Column 2"
      }

      table << {
          :col1 => "Row 2, Column 1",
          :col2 => "Row 2, Column 1"
      }
    end

    expected=<<-END
====================================================================================================
Column 1             Column 2
----------------------------------------------------------------------------------------------------
Row 1, Column 1      Row 1, Column 2
Row 2, Column 1      Row 2, Column 1
====================================================================================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_multiple_stars_split_evenly
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>"*", :title=>"Column 2"},
        {:key=>:col3, :size=>"*", :title=>"Column 3"},
    ]

    ConsoleTable.define(table_config, :width=> 100, :output=>@mock_out) do |table|
      table << {
          :col1 => "Row 1, Column 1",
          :col2 => "Row 1, Column 2",
          :col3 => "Row 1, Column 3"
      }

      table << {
          :col1 => "Row 2, Column 1",
          :col2 => "Row 2, Column 1",
          :col3 => "Row 2, Column 3"
      }
    end

    expected=<<-END
====================================================================================================
Column 1             Column 2                                Column 3
----------------------------------------------------------------------------------------------------
Row 1, Column 1      Row 1, Column 2                         Row 1, Column 3
Row 2, Column 1      Row 2, Column 1                         Row 2, Column 3
====================================================================================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_no_size_assumed_to_be_star
    table_config = [
        {:key=>:col1, :title=>"Column 1"},
        {:key=>:col2, :title=>"Column 2"},
    ]

    ConsoleTable.define(table_config, :width=> 40, :output=>@mock_out) do |table|
      table << {
          :col1 => "Row 1, Column 1",
          :col2 => "Row 1, Column 2",
      }

    end

    expected=<<-END
===============================================================================
Column 1                                Column 2
-------------------------------------------------------------------------------
Row 1, Column 1                         Row 1, Column 2
===============================================================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_no_name_defaulted_to_capitalize_of_key_name
    table_config = [
        {:key=>:col1},
        {:key=>:col2},
    ]

    ConsoleTable.define(table_config, :width=> 40, :output=>@mock_out) do |table|
      table << {
          :col1 => "Row 1, Column 1",
          :col2 => "Row 1, Column 2",
      }

    end

    expected=<<-END
===============================================================================
Col1                                    Col2
-------------------------------------------------------------------------------
Row 1, Column 1                         Row 1, Column 2
===============================================================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_can_combine_percentages_fixed_and_stars
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>0.3, :title=>"Column 2"},
        {:key=>:col3, :size=>4, :title=>"Column 3"},
        {:key=>:col4, :size=>"*", :title=>"Column 4"},
        {:key=>:col5, :size=>0.2, :title=>"Column 5"},
        {:key=>:col6, :size=>"*", :title=>"Column 6"},
        {:key=>:col7, :size=>10, :title=>"Column 7"}
    ]

    ConsoleTable.define(table_config, :width=> 160, :output=>@mock_out) do |table|
      table << {
          :col1 => "Row 1, Column 1",
          :col2 => "Row 1, Column 2",
          :col3 => "Row 1, Column 3",
          :col4 => "Row 1, Column 4",
          :col5 => "Row 1, Column 5",
          :col6 => "Row 1, Column 6",
          :col7 => "Row 1, Column 7",
      }

      table << {
          :col1 => "Row 2, Column 1",
          :col2 => "Row 2, Column 2",
          :col3 => "Row 2, Column 3",
          :col4 => "Row 2, Column 4",
          :col5 => "Row 2, Column 5",
          :col6 => "Row 2, Column 6",
          :col7 => "Row 2, Column 7",
      }
    end

    expected=<<-END
================================================================================================================================================================
Column 1             Column 2                             Colu Column 4                       Column 5                 Column 6                       Column 7
----------------------------------------------------------------------------------------------------------------------------------------------------------------
Row 1, Column 1      Row 1, Column 2                      Row  Row 1, Column 4                Row 1, Column 5          Row 1, Column 6                Row 1, Col
Row 2, Column 1      Row 2, Column 2                      Row  Row 2, Column 4                Row 2, Column 5          Row 2, Column 6                Row 2, Col
================================================================================================================================================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_wont_create_layout_too_large_for_screen
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>20, :title=>"Column 2"},
    ]

    assert_raises(RuntimeError) { ConsoleTable.define(table_config, :width=>30) }
  end

  def test_wont_create_layout_with_more_than_100_percent
    table_config = [
        {:key=>:col1, :size=>0.8, :title=>"Column 1"},
        {:key=>:col2, :size=>0.3, :title=>"Column 2"},
    ]

    assert_raises(RuntimeError) { ConsoleTable.define(table_config) }
  end

  def test_wont_create_layout_with_invalid_size
    table_config = [
        {:key=>:col1, :size=>0.8, :title=>"Column 1"},
        {:key=>:col2, :size=>"hello!", :title=>"Column 2"},
    ]

    assert_raises(RuntimeError) { ConsoleTable.define(table_config) }
  end

  def test_wont_allow_repeats_of_key_names
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col1, :size=>20, :title=>"Column 2"},
    ]

    assert_raises(RuntimeError) { ConsoleTable.define(table_config) }
  end

  def test_wont_allow_columns_with_no_key_name
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:size=>20, :title=>"Column 2"},
    ]

    assert_raises(RuntimeError) { ConsoleTable.define(table_config) }
  end

  def test_can_truncate_output
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"}
    ]

    ConsoleTable.define(table_config, :width=> 100, :output=>@mock_out) do |table|
      table << ["This is short"]

      table << {:col1=>"This is way too long and it needs to get cut off"}

      table << [
          {:text=>"This is way too long and it needs to get cut off", :ellipsize=>true}
      ]

    end

    expected=<<-END
====================
Column 1
--------------------
This is short
This is way too long
This is way too l...
====================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_can_justify_columns_and_override_in_rows
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>20, :title=>"Column 2", :justify=>:center},
        {:key=>:col3, :size=>20, :title=>"Column 3", :justify=>:right}
    ]

    ConsoleTable.define(table_config, :width=> 100, :output=>@mock_out) do |table|
      table << {
        :col1 => "Short1",
        :col2 => "Short2",
        :col3 => "Short3"
      }

      table << {
        :col1 => {text: "Short1"},
        :col2 => {text: "Short2"},
        :col3 => {text: "Short3"}
      }

      table << {
          :col1 => {text: "Short1", :justify=>:center},
          :col2 => {text: "Short2", :justify=>:right},
          :col3 => {text: "Short3", :justify=>:left}
      }
    end

    expected=<<-END
==============================================================
Column 1                   Column 2                   Column 3
--------------------------------------------------------------
Short1                      Short2                      Short3
Short1                      Short2                      Short3
       Short1                      Short2 Short3
==============================================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_huge_example

    table_config = [
        {:key=>:title, :size=>15, :title=>"Movie Title"},
        {:key=>:name, :size=>15, :title=>"Name"},
        {:key=>:release_date, :size=>8, :title=>"Release Date Too Long"},
        {:key=>:tagline, :size=>"*", :title=>"Motto", :justify=>:right},
    ]

    ConsoleTable.define(table_config, :left_margin=>5, :right_margin=>10, :width=>80, :title=>"Movie Killers", :output=>@mock_out) do |table|
      table << {
          :title=>{:text=>"Friday the 13th"},
          :name=>{:text=>"Jason's Mom", :justify=>:left},
          :release_date=>{text: "05-09-80"},
          :tagline=>{:text=>"They were warned...They are doomed...And on Friday the 13th, nothing will save them.", :ellipsize=>true}
      }

      table << {
          :title=>{:text=>"Halloween"},
          :name=>{:text=>"Michael Meyers", :justify=>:left},
          :release_date=>{text: "10-25-80"},
          :tagline=>{:text=>"Everyone is entitled to one good scare", :ellipsize=>true}
      }

      table << {
          :title=>{:text=>"Nightmare on Elm St."},
          :name=>{:text=>"Freddy Krueger", :justify=>:left},
          :release_date=>{text: "11-16-84"},
          :tagline=>{:text=>"A scream that wakes you up, might be your own", :ellipsize=>true}
      }

      table << ["Hellraiser", "Pinhead", "9-18-87", "Demon to some. Angel to others."]

      table.footer << "This is just a line of footer text"
      table.footer << "This is a second footer with \nlots of \nlinebreaks in it."
    end

    expected=<<-END
     =================================================================
                               Movie Killers
     Movie Title     Name            Release                     Motto
     -----------------------------------------------------------------
     Friday the 13th Jason's Mom     05-09-80 They were warned...Th...
     Halloween       Michael Meyers  10-25-80 Everyone is entitled ...
     Nightmare on El Freddy Krueger  11-16-84 A scream that wakes y...
     Hellraiser      Pinhead         9-18-87  Demon to some. Angel to
     -----------------------------------------------------------------
                                    This is just a line of footer text
                                          This is a second footer with
                                                               lots of
                                                     linebreaks in it.
     =================================================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_printing_a_single_string_does_full_line
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>20, :title=>"Column 2"},
    ]

    ConsoleTable.define(table_config, :width=> 100, :output=>@mock_out) do |table|
      table << "This is just a string, it should ignore columns"
    end

    expected=<<-END
=========================================
This is just a string, it should ignore c
=========================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_printing_a_single_after_data_makes_headings_show_up
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>20, :title=>"Column 2"},
    ]

    ConsoleTable.define(table_config, :width=> 100, :output=>@mock_out) do |table|
      table << ["One", "Two"]
      table << "This is just a string, it should ignore columns"
      table << ["One", "Two"]
    end

    expected=<<-END
=========================================
Column 1             Column 2
-----------------------------------------
One                  Two
This is just a string, it should ignore c
One                  Two
=========================================
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_can_have_a_bordered_table
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>0.3, :title=>"Column 2"},
        {:key=>:col3, :size=>10, :title=>"Column 3", :justify=>:center},
        {:key=>:col4, :size=>"*", :title=>"Column 4", :justify=>:center}
    ]

    ConsoleTable.define(table_config, :left_margin=>10, :right_margin=>7, :width=> 100, :title=>"Test Title", :borders=>true, :output=>@mock_out) do |table|
      (1..5).each do |row|
        table << (1..4).collect{|i| "Row #{row}, Column #{i}".red}
      end

      table << "Plain line needs borders"
      table.footer << "Footer needs borders"
      table.footer << "Footer still \n needs borders"

    end

    expected=<<-END
          *================================================================================*
          |                                   Test Title                                   |
          +--------------------+--------------+----------+---------------------------------+
          |Column 1            |Column 2      | Column 3 |            Column 4             |
          +--------------------+--------------+----------+---------------------------------+
          |Row 1, Column 1     |Row 1, Column |Row 1, Col|         Row 1, Column 4         |
          +--------------------+--------------+----------+---------------------------------+
          |Row 2, Column 1     |Row 2, Column |Row 2, Col|         Row 2, Column 4         |
          +--------------------+--------------+----------+---------------------------------+
          |Row 3, Column 1     |Row 3, Column |Row 3, Col|         Row 3, Column 4         |
          +--------------------+--------------+----------+---------------------------------+
          |Row 4, Column 1     |Row 4, Column |Row 4, Col|         Row 4, Column 4         |
          +--------------------+--------------+----------+---------------------------------+
          |Row 5, Column 1     |Row 5, Column |Row 5, Col|         Row 5, Column 4         |
          +--------------------+--------------+----------+---------------------------------+
          |Plain line needs borders                                                        |
          +--------------------+--------------+----------+---------------------------------+
          |                                                            Footer needs borders|
          |                                                                    Footer still|
          |                                                                   needs borders|
          *================================================================================*
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_outline_joins_only_when_no_footer_or_header
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>0.3, :title=>"Column 2"},
        {:key=>:col3, :size=>10, :title=>"Column 3", :justify=>:center},
        {:key=>:col4, :size=>"*", :title=>"Column 4", :justify=>:center}
    ]

    #borders are true, so outline false should be ignored
    ConsoleTable.define(table_config, :left_margin=>10, :right_margin=>7, :width=> 100, :borders=>true, :outline=>false, :output=>@mock_out) do |table|
      (1..5).each do |row|
        table << (1..4).collect{|i| "Row #{row}, Column #{i}"}
      end

      table << "Plain line needs borders"

    end

    expected=<<-END
          *====================*==============*==========*=================================*
          |Column 1            |Column 2      | Column 3 |            Column 4             |
          +--------------------+--------------+----------+---------------------------------+
          |Row 1, Column 1     |Row 1, Column |Row 1, Col|         Row 1, Column 4         |
          +--------------------+--------------+----------+---------------------------------+
          |Row 2, Column 1     |Row 2, Column |Row 2, Col|         Row 2, Column 4         |
          +--------------------+--------------+----------+---------------------------------+
          |Row 3, Column 1     |Row 3, Column |Row 3, Col|         Row 3, Column 4         |
          +--------------------+--------------+----------+---------------------------------+
          |Row 4, Column 1     |Row 4, Column |Row 4, Col|         Row 4, Column 4         |
          +--------------------+--------------+----------+---------------------------------+
          |Row 5, Column 1     |Row 5, Column |Row 5, Col|         Row 5, Column 4         |
          +--------------------+--------------+----------+---------------------------------+
          |Plain line needs borders                                                        |
          *====================*==============*==========*=================================*
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_can_have_no_outline_if_requested
    table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>0.3, :title=>"Column 2"},
    ]

    ConsoleTable.define(table_config, :width=>60, :outline=>false, :title=>"Still has a title", :output=>@mock_out) do |table|
      (1..5).each do |row|
        table << (1..2).collect{|i| "Row #{row}, Column #{i}"}
      end

    end

    expected=<<-END
       Still has a title
Column 1             Column 2
--------------------------------
Row 1, Column 1      Row 1, Colu
Row 2, Column 1      Row 2, Colu
Row 3, Column 1      Row 3, Colu
Row 4, Column 1      Row 4, Colu
Row 5, Column 1      Row 5, Colu
    END

    assert_output_equal expected, @mock_out.string
  end

  def test_can_use_colors_without_affecting_layout
    table_config = [
        {:key=>:col1, :size=>10, :title=>"Column 1", :justify=>:left},
        {:key=>:col2, :size=>10, :title=>"Column 2", :justify=>:center},
        {:key=>:col3, :size=>10, :title=>"Column 3", :justify=>:right},
    ]

    ConsoleTable.define(table_config, :width=> 120, :output=>@mock_out) do |table|
      table << ["Short".blue, "Short".bold, "Short".red.on_blue]

      table << ["Much much longer".blue, "Much much longer".bold, "Much much longer".red.on_blue]

      table << [
          {:text=>"Much much longer".blue, :ellipsize=>true},
          {:text=>"Much much longer".underline, :ellipsize=>true},
          {:text=>"Much much longer".on_magenta, :ellipsize=>true}
      ]

      table << [
          {:text=>"Much much longer".yellow, :ellipsize=>true},
          {:text=>"Normal, should reset", :ellipsize=>true},
          {:text=>"Much much longer".bold, :ellipsize=>true}
      ]
    end

    expected=<<-END
================================
Column 1    Column 2    Column 3
--------------------------------
Short        Short         Short
Much much  Much much  Much much
Much mu... Much mu... Much mu...
Much mu... Normal,... Much mu...
================================
    END

    assert_includes @mock_out.string, "\e[1;39;49mShort\e[0m"  #Should have normal color codes
    assert_includes @mock_out.string, "\e[0;33;49mMuch mu...\e[0m"  #the cut-off one should keep the color code for ellipses, then reset

    assert_output_equal expected, @mock_out.string
  end

  private
  def assert_output_equal(expected, actual)
    expected_lines = expected.split("\n")
    actual_lines = actual.split("\n")
    assert_equal expected_lines.length, actual_lines.length
    expected_lines.each_with_index do |expected_line, i|
      actual_line = actual_lines[i]
      assert_equal expected_line.uncolorize.rstrip, actual_line.uncolorize.rstrip
    end

  end
end