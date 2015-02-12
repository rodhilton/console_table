require 'minitest/autorun'
require 'console_table'

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
      table.print({
                      :col1 => "Row 1, Column 1",
                      :col2 => "Row 1, Column 2"
                  })

      table.print({
                      :col1 => "Row 2, Column 1",
                      :col2 => "Row 2, Column 1"
                  })
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
      table.print({
                      :col1 => "Row 1, Column 1",
                      :col2 => "Row 1, Column 2"
                  })

      table.print({
                      :col1 => "Row 2, Column 1",
                      :col2 => "Row 2, Column 1"
                  })
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
      table.print({
                      :col1 => "Row 1, Column 1",
                      :col2 => "Row 1, Column 2"
                  })

      table.print({
                      :col1 => "Row 2, Column 1",
                      :col2 => "Row 2, Column 1"
                  })
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
      table.print({
                      :col1 => "Row 1, Column 1",
                      :col2 => "Row 1, Column 2",
                      :col3 => "Row 1, Column 3"
                  })

      table.print({
                      :col1 => "Row 2, Column 1",
                      :col2 => "Row 2, Column 1",
                      :col3 => "Row 2, Column 3"
                  })
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
      table.print({
                      :col1 => "Row 1, Column 1",
                      :col2 => "Row 1, Column 2",
                  })

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
      table.print({
                      :col1 => "Row 1, Column 1",
                      :col2 => "Row 1, Column 2",
                  })

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
      table.print({
                      :col1 => "Row 1, Column 1",
                      :col2 => "Row 1, Column 2",
                      :col3 => "Row 1, Column 3",
                      :col4 => "Row 1, Column 4",
                      :col5 => "Row 1, Column 5",
                      :col6 => "Row 1, Column 6",
                      :col7 => "Row 1, Column 7",
                  })

      table.print({
                      :col1 => "Row 2, Column 1",
                      :col2 => "Row 2, Column 2",
                      :col3 => "Row 2, Column 3",
                      :col4 => "Row 2, Column 4",
                      :col5 => "Row 2, Column 5",
                      :col6 => "Row 2, Column 6",
                      :col7 => "Row 2, Column 7",
                  })
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
      table.print({
                      :col1 => "This is short"
                  })

      table.print({
                      :col1 => "This is way too long and it needs to get cut off"
                  })

      table.print({
                      :col1 => {:text=>"This is way too long and it needs to get cut off", :ellipsize=>true}
                  })
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
      table.print({
                      :col1 => "Short1",
                      :col2 => "Short2",
                      :col3 => "Short3"
                  })

      table.print({
                      :col1 => {text: "Short1"},
                      :col2 => {text: "Short2"},
                      :col3 => {text: "Short3"}
                  })

      table.print({
                      :col1 => {text: "Short1", :justify=>:center},
                      :col2 => {text: "Short2", :justify=>:right},
                      :col3 => {text: "Short3", :justify=>:left}
                  })
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
      table.print({
                      :title=>{:text=>"Friday the 13th"},
                      :name=>{:text=>"Jason's Mom", :justify=>:left},
                      :release_date=>{text: "05-09-80"},
                      :tagline=>{:text=>"They were warned...They are doomed...And on Friday the 13th, nothing will save them.", :ellipsize=>true}
                  })

      table.print({
                      :title=>{:text=>"Halloween"},
                      :name=>{:text=>"Michael Meyers", :justify=>:left},
                      :release_date=>{text: "10-25-80"},
                      :tagline=>{:text=>"Everyone is entitled to one good scare", :ellipsize=>true}
                  })

      table << {
          :title=>{:text=>"Nightmare on Elm St."},
          :name=>{:text=>"Freddy Krueger", :justify=>:left},
          :release_date=>{text: "11-16-84"},
          :tagline=>{:text=>"A scream that wakes you up, might be your own", :ellipsize=>true}
      }

      table << ["Hellraiser", "Pinhead", "9-18-87", "Demon to some. Angel to others."]

      table.add_footer("This is just a line of footer text")
      table.add_footer("This is a second footer with \nlots of \nlinebreaks in it.")
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

  private
  def assert_output_equal(expected, actual)
    expected_lines = expected.split("\n")
    actual_lines = actual.split("\n")
    assert_equal expected_lines.length, actual_lines.length
    expected_lines.each_with_index do |expected_line, i|
      actual_line = actual_lines[i]
      assert_equal expected_line.rstrip, actual_line.rstrip
    end

  end
end