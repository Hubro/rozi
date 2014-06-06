
module Rozi

  module_function

  ##
  # Opens a file handle with the correct settings for writing an Ozi Explorer
  # file format.
  #
  # @overload open_file_for_writing(path)
  #
  #   @param [String] path
  #   @return [File]
  #
  # @overload open_file_for_writing(path)
  #
  #   Can be called with a block, just file {File.open File.open}.
  #
  #   @yieldparam [File] file
  #   @return [void]
  #
  def open_file_for_writing(path)
    file = File.open(path, "w")
    file.set_encoding("ISO-8859-1", "UTF-8", crlf_newline: true)

    if block_given?
      yield file
      file.close

      return nil
    else
      return file
    end
  end

  ##
  # Writes an array of waypoints to a file.
  #
  # @see Rozi::WaypointWriter#write
  #
  def write_waypoints(waypoints, file)
    @@wpt_writer ||= WaypointWriter.new

    if file.is_a? String
      open_file_for_writing(file) { |f|
        @@wpt_writer.write(waypoints, f)
      }
    else
      @@wpt_writer.write(waypoints, file)
    end

    return nil
  end

  ##
  # Writes a track to a file.
  #
  # @see Rozi::TrackWriter#write
  #
  def write_track(track, file)
    @@track_writer ||= TrackWriter.new

    if file.is_a? String
      open_file_for_writing(file) { |f|
        @@track_writer.write(track, f)
      }
    else
      @@track_writer.write(track, file)
    end

    return nil
  end
end