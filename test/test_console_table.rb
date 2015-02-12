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
    ENV["COLUMNS"] = "100"

    commit_table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>20, :title=>"Column 2"},
    ]

    ConsoleTable.define(commit_table_config, :output=>@mock_out) do |table|
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

  def test_percents
    ENV["COLUMNS"] = "100"

    commit_table_config = [
        {:key=>:col1, :size=>0.3, :title=>"Column 1"},
        {:key=>:col2, :size=>0.7, :title=>"Column 2"},
    ]

    ConsoleTable.define(commit_table_config, :output=>@mock_out) do |table|
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
    ENV["COLUMNS"] = "100"

    commit_table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>"*", :title=>"Column 2"},
    ]

    ConsoleTable.define(commit_table_config, :output=>@mock_out) do |table|
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
    ENV["COLUMNS"] = "100"

    commit_table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>"*", :title=>"Column 2"},
        {:key=>:col3, :size=>"*", :title=>"Column 3"},
    ]

    ConsoleTable.define(commit_table_config, :output=>@mock_out) do |table|
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

  def test_can_combine_percentages_fixed_and_stars
    ENV["COLUMNS"] = "160"

    commit_table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col2, :size=>0.3, :title=>"Column 2"},
        {:key=>:col3, :size=>4, :title=>"Column 3"},
        {:key=>:col4, :size=>"*", :title=>"Column 4"},
        {:key=>:col5, :size=>0.2, :title=>"Column 5"},
        {:key=>:col6, :size=>"*", :title=>"Column 6"},
        {:key=>:col7, :size=>10, :title=>"Column 7"}
    ]

    ConsoleTable.define(commit_table_config, :output=>@mock_out) do |table|
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
    ENV["COLUMNS"] = "30"

    commit_table_config = [
        {:key=>:col1, :size=>20, :title=>"Column 1"},
        {:key=>:col1, :size=>20, :title=>"Column 2"},
    ]

    assert_raises(RuntimeError) { ConsoleTable.define(commit_table_config) }
  end

  def test_wont_create_layout_with_more_than_100_percent
    ENV["COLUMNS"] = "30"

    commit_table_config = [
        {:key=>:col1, :size=>0.8, :title=>"Column 1"},
        {:key=>:col1, :size=>0.3, :title=>"Column 2"},
    ]

    assert_raises(RuntimeError) { ConsoleTable.define(commit_table_config) }
  end

  def test_wont_create_layout_with_invalid_size
    ENV["COLUMNS"] = "30"

    commit_table_config = [
        {:key=>:col1, :size=>0.8, :title=>"Column 1"},
        {:key=>:col1, :size=>"hello!", :title=>"Column 2"},
    ]

    assert_raises(RuntimeError) { ConsoleTable.define(commit_table_config) }
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