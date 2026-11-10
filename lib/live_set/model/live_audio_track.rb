require_relative '../../common/xml'
require_relative 'live_audio_clip'
require_relative 'live_audio_clips'
require_relative 'live_midi_clip'
require_relative 'live_track_facts'

# An audio track of a set: the `<AudioTrack>` element of the XML.
#
# An audio track plays files, and it can hold MIDI clips as well. The MIDI track of the set
# is `LiveMidiTrack`, and it holds no file.
#
# The model holds no number: the XML has no notion of a track number, and the serializer
# generates the numbers of the report.
#
# not implemented: parsing of elements AutomationEnvelopes, AutomationLane and the
# arrangement of a track
class LiveAudioTrack
  include Xml
  include LiveTrackFacts

  # The places a MIDI clip of a track can be in.
  #
  # The clips of the take lanes are in the lanes, which are subordinate to the track.
  PLACES = {
    'session view' => 'DeviceChain/MainSequencer/ClipSlotList/ClipSlot/ClipSlot/Value/MidiClip',
    'arrangement'  => 'DeviceChain/MainSequencer/ClipTimeable/ArrangerAutomation/Events/MidiClip',
  }.freeze

  # The sequencers a track can have.
  #
  # A track that is frozen keeps both. The MainSequencer holds the editable material, and the
  # FreezeSequencer holds the rendered audio cache that replaces it during playback. A frozen
  # track's clips can be in either, and some are only in the FreezeSequencer, so both have to be
  # searched. See docs/als_notes.md, "The two sequencers of a track, and the frozen track that
  # keeps both".
  SEQUENCERS = %w[MainSequencer FreezeSequencer].freeze

  attr_reader :audio_clips, :clips

  # @param set_directory [String] the directory of the set
  # @param element [Nokogiri::XML::Element] the `<AudioTrack>` element
  def initialize(set_directory, element)
    @element = element
    read_track_facts 'AudioTrack'
    @clips = midi_clips_of_track
    @audio_clips = LiveAudioClips.new audio_clips_of_track(set_directory)
  end

  # The kind of the track.
  #
  # @return [String] the kind
  def kind
    'Audio'
  end

  # The MIDI clips of the track, and the place each of them is in.
  #
  # An audio track can hold MIDI clips as well as the audio clips it plays.
  #
  # @return [Array<LiveMidiClip>] the clips
  def midi_clips_of_track
    PLACES.flat_map do |place, path|
      @element.xpath(path).map { |node| LiveMidiClip.new node, place: place }
    end
  end

  # The audio clips of the track, and the place each of them is in.
  #
  # A track's audio can be in the session view, in the arrangement, and in the take lanes.
  # They are separate clips with separate ids, and the same file can be referenced from more
  # than one of them. See docs/als_notes.md, "Where a track's audio is".
  #
  # @param set_directory [String] the directory of the set
  # @return [Array<LiveAudioClip>] the clips
  def audio_clips_of_track(set_directory)
    session_view_clips(set_directory) + arrangement_clips(set_directory) + take_lane_clips(set_directory)
  end

  # The clips in the track's row of session-view slots.
  #
  # @param set_directory [String] the directory of the set
  # @return [Array<LiveAudioClip>] the clips
  def session_view_clips(set_directory)
    sequencer_clips('ClipSlotList/ClipSlot/ClipSlot/Value/AudioClip')
      .map { |node| LiveAudioClip.new set_directory, node, place: 'session view' }
  end

  # The clips on the arrangement timeline.
  #
  # @param set_directory [String] the directory of the set
  # @return [Array<LiveAudioClip>] the clips
  def arrangement_clips(set_directory)
    sequencer_clips('Sample/ArrangerAutomation/Events/AudioClip')
      .map { |node| LiveAudioClip.new set_directory, node, place: 'arrangement' }
  end

  # The clips recorded onto the take lanes.
  #
  # The lane a clip is in is part of the place the clip is in, so the clip says which lane of
  # the track it is in.
  #
  # @param set_directory [String] the directory of the set
  # @return [Array<LiveAudioClip>] the clips
  def take_lane_clips(set_directory)
    @element.xpath('./TakeLanes/TakeLanes/TakeLane/ClipAutomation/Events/AudioClip')
            .map do |node|
              lane = node.ancestors('TakeLane').first
              LiveAudioClip.new set_directory, node, place: "take lane #{lane_number_of lane}"
            end
  end

  # The number of the take lane, among the lanes of the track, from one.
  #
  # @param lane [Nokogiri::XML::Element, nil] the take lane
  # @return [Integer] the number of the lane
  def lane_number_of(lane)
    return 1 if lane.nil?

    @element.xpath('./TakeLanes/TakeLanes/TakeLane').index(lane).to_i + 1
  end

  # The clips at the given path within a sequencer.
  #
  # @param path [String] the path to the clips, relative to the sequencer
  # @return [Array<Nokogiri::XML::Element>] the clips
  def sequencer_clips(path)
    SEQUENCERS.flat_map { |sequencer| @element.xpath("./DeviceChain/#{sequencer}/#{path}").to_a }
  end

  # The track's audio clips, with each file counted once.
  #
  # The same file can be referenced from the session view, the arrangement and the take lanes
  # at the same time. It occupies space once, so it is counted once. See docs/als_notes.md,
  # "Where a track's audio is".
  #
  # @return [Array<LiveAudioClip>] the distinct clips
  def distinct_clips
    @audio_clips.distinct
  end

  # The number of distinct files the track's clips refer to.
  #
  # @return [Integer] the number of distinct files
  def distinct_file_count
    distinct_clips.length
  end

  # The size of the track's audio, counting each file once.
  #
  # @return [Integer] the size in bytes
  def track_size
    distinct_clips.sum(&:file_size)
  end

  # Whether every file the track plays is in the project.
  #
  # @return [Boolean] true when the clips are collected
  def clips_collected?
    distinct_clips.all?(&:collected?)
  end
end
