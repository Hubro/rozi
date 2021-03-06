
require "stringio"

module RoziTestSuite
  class WriteWaypointsTest < TestCase
    def setup
      @subject = Rozi.method(:write_waypoints)
    end

    def test_basic_usage
      waypoints = [
        Rozi::Waypoint.new(
          latitude: 59.91273, longitude: 10.74609, name: "OSLO"
        ),
        Rozi::Waypoint.new(
          latitude: 60.39358, longitude: 5.32476, name: "BERGEN"
        ),
        Rozi::Waypoint.new(
          latitude: 62.56749, longitude: 7.68709, name: "ÅNDALSNES"
        )
      ]

      file = StringIO.new
      Rozi.expects(:open_file).returns(file)

      @subject.call(waypoints, "/x/y.wpt", datum: "WGS 84", version: "1.1")

      assert_equal(
        RoziTestSuite.read_test_data("expected_output_1.wpt"),
        file.string
      )
    end
  end

  class WaypointTest < TestCase
    def setup
      @subject = Rozi::Waypoint.new
    end

    def test_initialize
      wp = Rozi::Waypoint.new(number: 5, name: "Test point")

      assert_equal "Test point", wp.name
      assert_equal 5, wp.number

      assert_raises(ArgumentError) {
        # Invalid attribute "foo".
        wp = Rozi::Waypoint.new(foo: 123)
      }
    end

    def test_display_format_setter
      @subject.display_format = 3
      assert_equal 3, @subject.display_format(raw: true)

      @subject.display_format = :name_with_dot
      assert_equal 3, @subject.display_format(raw: true)
    end

    def test_display_format_getter
      @subject.display_format = 3

      assert_equal :name_with_dot, @subject.display_format
      assert_equal 3, @subject.display_format(raw: true)
    end

    def test_colors
      wp = Rozi::Waypoint.new()
      wp.expects(:interpret_color).twice.with(:foo).returns(:bar)

      wp.fg_color = :foo
      assert_equal :bar, wp.fg_color

      wp.bg_color = :foo
      assert_equal :bar, wp.bg_color
    end
  end

  class WaypointFileTest < TestCase
    def setup
      @sio = StringIO.new
      @subject = Rozi::WaypointFile.new(@sio)
    end

    def test_write
      @subject.expects(:write_waypoint).with(:foo)
      @subject.expects(:write_waypoint).with(:bar)
      @subject.expects(:write_waypoint).with(:baz)

      @subject.write([:foo, :bar, :baz])
    end

    def test_write_waypoint
      wpt = Rozi::Waypoint.new

      @subject.expects(:write_properties).once

      @subject.write_waypoint(wpt)
      @subject.write_waypoint(wpt)
    end

    def test_each_waypoint
      @subject.expects(:read_waypoint).times(4)
        .returns(:foo)
        .then.returns(:bar)
        .then.returns(:baz)
        .then.raises(EOFError)

      assert_equal [:foo, :bar, :baz], @subject.each_waypoint.to_a
    end

    def test_read_properties
      @sio.write("OziExplorer Waypoint File Version 1.0\n")
      @sio.write("Norsk\n")
      @sio.write("Reserved 2\n")
      @sio.write("garmin\n")
      @sio.rewind

      properties = @subject.read_properties
      assert_equal "1.0", properties.version
      assert_equal "Norsk", properties.datum
    end

    def test_read_properties_with_bad_file_pos
      @sio.write("foo")

      assert_raises(RuntimeError) {
        @subject.read_properties
      }
    end

    def test_read_waypoint
      @sio.write("foo\n")
      @sio.write("bar\n")
      @sio.rewind

      @subject.expects(:read_properties).once

      def @subject.parse_waypoint(x)
        return "parsed: #{x.strip}"
      end

      assert_equal "parsed: foo", @subject.read_waypoint
      assert_equal "parsed: bar", @subject.read_waypoint
    end

    def test_parse_waypoint_file_properties
      expected_output = {
        version: "1.0",
        datum: "Norsk"
      }

      text = (
        "OziExplorer Waypoint File Version 1.0\n" +
        "Norsk\n" +
        "Reserved 2\n" +
        "garmin\n"
      )

      properties = @subject.send(:parse_waypoint_file_properties, text)

      assert_equal expected_output, properties.to_h
    end

    def test_parse_waypoint
      expected_output = {
        number: 1,
        name: "Grorud",
        latitude: 59.960742,
        longitude: 10.881999,
        date: 41977.3865272,
        symbol: 0,
        display_format: 1,
        fg_color: 0,
        bg_color: 15441496,
        description: "Description, with comma",
        pointer_direction: 0,
        altitude: 404,
        font_size: 6,
        font_style: 0,
        symbol_size: 15
      }

      text = (
        "1,Grorud,  59.960742,  10.881999,41977.3865272,  0, 0, 1,         0," +
        "  15441496,DescriptionÑ with comma, 0, 0,    0,    404, 6, 0,15,0,10" +
        ".0,2,,,,60\n"
      )

      waypoint = @subject.send(:parse_waypoint, text)

      assert_equal expected_output, waypoint.to_h
    end

    def test_parse_waypoint_2
      expected_output = {
        number: 2,
        name: "Lillestrøm",
        latitude: 59.956788,
        longitude: 11.051257,
        date: 41977.3935379,
        symbol: 7,
        display_format: 4,
        fg_color: 16777215,
        bg_color: 5450740,
        description: "Description, with comma",
        pointer_direction: 0,
        altitude: -777,
        font_size: 6,
        font_style: 0,
        symbol_size: 20
      }

      text = (
        "2,Lillestrøm,  59.956788,  11.051257,41977.3935379,  7, 0, 4,  16777" +
        "215,   5450740,DescriptionÑ with comma, 0, 0,    0,   -777, 6, 0,20," +
        "0,10.0,2,,,,60"
      )

      waypoint = @subject.send(:parse_waypoint, text)

      assert_equal expected_output, waypoint.to_h
    end

    def test_serialize_waypoint_file_properties
      m = Rozi::WaypointFileProperties.new

      assert_equal(
        "OziExplorer Waypoint File Version 1.1\n" +
        "WGS 84\n" +
        "Reserved 2\n",
        @subject.send(:serialize_waypoint_file_properties, m)
      )

      m = Rozi::WaypointFileProperties.new("Norsk", "1.2")

      assert_equal(
        "OziExplorer Waypoint File Version 1.2\n" +
        "Norsk\n" +
        "Reserved 2\n",
        @subject.send(:serialize_waypoint_file_properties, m)
      )
    end

    def test_serialize_waypoint
      wpt = Rozi::Waypoint.new(name: "test")

      assert_equal(
        "-1,test,0.000000,0.000000,,0,1,3,0,65535,,0,,,-777,6,0,17",
        @subject.send(:serialize_waypoint, wpt)
      )

      wpt = Rozi::Waypoint.new(name: "test", symbol: 4)

      assert_equal(
        "-1,test,0.000000,0.000000,,4,1,3,0,65535,,0,,,-777,6,0,17",
        @subject.send(:serialize_waypoint, wpt)
      )

      wpt = Rozi::Waypoint.new(name: "test", description: "æøå, ÆØÅ")

      assert_equal(
        "-1,test,0.000000,0.000000,,0,1,3,0,65535,æøåÑ ÆØÅ,0,,,-777,6,0,17",
        @subject.send(:serialize_waypoint, wpt)
      )
    end
  end
end
