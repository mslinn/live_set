require 'spec_helper'
require 'live_set/als_file'
require 'live_set/tx/live_11_and_12'
require 'demo_sets'
require 'support/schemas'

# The elements Live 12 adds that the rules add, and not the table of the additions.
#
# The tuning of a MIDI track depends on the device chain of the track — the notes of a drum
# rack are not pitches — so it cannot be written in the table.
ADDED_BY_RULES = { 'MidiTrack' => %w[IsTuned] }.freeze

# The ground truth of the up direction: what Live does when it opens a Live 11 set in Live 12
# and saves it.
#
# Ableton ships the Live 11 Suite demo set. Saving that set in Live 12 produces a second file,
# and that second file is what the up direction has to reproduce. It is the reference the rules
# of the conversion are checked against.
#
# The rules are in the tables of Live11And12. This spec says those tables are right, so what
# Live does is written down in the repository rather than in a terminal scrollback. When Live
# changes what it writes, this spec fails and the tables are brought up to date.
#
# The rules of the conversion itself are in spec/live_set/tx/live_11_and_12_up_spec.rb.
RSpec.describe Live11And12, 'the Live 12 conversion of a Live 11 set' do
  let(:live11_path) { DemoSets.require_edition!('11', 'Suite') }
  let(:live12_path) { DemoSets.require_converted!('11', 'Suite') }

  let(:live_11_set) { AlsFile.read(live11_path) }
  let(:live_12_set) { AlsFile.read(live12_path) }

  # The names of the children of every element of a path.
  #
  # The children of every element of that path are gathered, because a set has many elements of
  # a name and they do not all have the same children.
  #
  # @param document [Nokogiri::XML::Document] the set
  # @param path [String] the path of the parent element
  # @return [Array<String>] the names of the children
  def child_names(document, path)
    document.xpath("//#{path}").flat_map { |element| element.element_children.map(&:name) }.uniq
  end

  # The element of a path that has the most children.
  #
  # @param document [Nokogiri::XML::Document] the set
  # @param path [String] the path of the parent element
  # @return [Nokogiri::XML::Node, nil] the element
  def fullest(document, path)
    document.xpath("//#{path}").max_by { |element| element.element_children.length }
  end

  # The name Live 12 gives an element that Live 11 gives a different name.
  #
  # @param name [String] the name Live 11 gives the element
  # @return [String] the name Live 12 gives it
  def live12_name(name)
    renamed = Live11And12::RENAME.invert[name]
    return renamed if renamed

    Live11And12::RENAME_UNDER[:up].each do |path, new_name|
      return new_name if path.split('/').last == name
    end

    name
  end

  # The path of the element in the Live 11 set.
  #
  # Live 11 calls the master track <MasterTrack> and Live 12 calls it <MainTrack>.
  #
  # @param path [String] the path of the element in Live 12
  # @return [String] the path of the element in Live 11
  def live11_path_of(path)
    path == 'MainTrack' ? 'MasterTrack' : path
  end

  # The elements Live 12 has under a parent that Live 11 does not.
  #
  # @param path [String] the path of the parent element
  # @return [Array<String>] the names of the elements
  def added_by_live12(path)
    old = child_names(live_11_set, live11_path_of(path)).map { |name| live12_name(name) }
    child_names(live_12_set, path) - old
  end

  # The structure of an element: its name, its attributes, and the structure of its children.
  #
  # @param element [Nokogiri::XML::Node] the element
  # @return [Hash] the structure of the element
  def structure(element)
    {
      name:       element.name,
      attributes: element.attribute_nodes.to_h { |attribute| [attribute.name, attribute.value] },
      children:   element.element_children.map { |child| structure(child) },
    }
  end

  # The structure an entry of the table of the elements Live 12 adds describes.
  #
  # @param addition [Hash] the entry
  # @return [Hash] the structure the entry describes
  def expected_structure(addition)
    {
      name:       addition[:name],
      attributes: addition[:attributes],
      children:   addition.fetch(:children, []).map { |child| expected_structure(child) },
    }
  end

  it 'is the conversion of the set it was made from' do
    expect(live_11_set.at_xpath('/Ableton')['Creator']).to eq 'Ableton Live 11.3d1'
    expect(live_12_set.at_xpath('/Ableton')['Creator']).to eq 'Ableton Live 12.4.6'
  end

  it 'keeps the material of the set' do
    expect(live_12_set.xpath('//MidiTrack | //AudioTrack | //GroupTrack | //ReturnTrack').length)
      .to eq live_11_set.xpath('//MidiTrack | //AudioTrack | //GroupTrack | //ReturnTrack').length
    expect(live_12_set.xpath('//MidiClip').length).to eq live_11_set.xpath('//MidiClip').length
    expect(live_12_set.xpath('//MidiNoteEvent').length).to eq live_11_set.xpath('//MidiNoteEvent').length
  end

  # The tuning of the set and of its tracks.
  #
  # Live 11 writes the name of a scale and says that the set is not in key; Live 12 writes the
  # index of the scale and says that the set is in key. Live 12 says that a MIDI track is
  # tuned, unless the track holds a drum rack: the notes of a drum rack are not pitches.
  it 'says that the set is in key, and writes the scale as an index' do
    expect(live_11_set.at_xpath('//LiveSet/InKey')['Value']).to eq 'false'
    expect(live_12_set.at_xpath('//LiveSet/InKey')['Value']).to eq 'true'

    expect(live_11_set.at_xpath('//LiveSet/ScaleInformation/Name')['Value']).to eq 'Major'
    expect(live_12_set.at_xpath('//LiveSet/ScaleInformation/Name')['Value']).to eq '0'
  end

  it 'tunes every MIDI track but the one with a drum rack' do
    tuned = live_12_set.xpath('//MidiTrack[IsTuned/@Value="true"]')
    untuned = live_12_set.xpath('//MidiTrack[IsTuned/@Value="false"]')

    expect(tuned.length).to eq 13
    expect(untuned.length).to eq 1
    expect(untuned.first.at_xpath('.//DrumGroupDevice')).not_to be_nil
    expect(tuned.first.at_xpath('.//DrumGroupDevice')).to be_nil
  end

  # The names of the tracks.
  #
  # Live 12 calls the track Live 11 calls the master track the main track, and names it "Main".
  # The pre-hear track follows the main track, and is named after it.
  it 'names the main track and the pre-hear track' do
    expect(live_12_set.at_xpath('//MainTrack/Name/EffectiveName')['Value']).to eq 'Main'
    expect(live_12_set.at_xpath('//PreHearTrack/Name/EffectiveName')['Value']).to eq '0-Main'
    expect(live_11_set.at_xpath('//MasterTrack/Name/EffectiveName')['Value']).to eq 'Master'
    expect(live_11_set.at_xpath('//PreHearTrack/Name/EffectiveName')['Value']).to eq 'Master'
  end

  # The linking of the follow actions of the scenes.
  #
  # Live 12 says that a follow action that is enabled is not linked.
  it 'unlinks the follow actions that are enabled' do
    actions = live_12_set.xpath('//LiveSet/Scenes/Scene/FollowAction')

    expect(actions.map { |action| action.at_xpath('./IsLinked')['Value'] })
      .to eq(actions.map { |action| action.at_xpath('./FollowActionEnabled')['Value'] == 'true' ? 'false' : 'true' })
  end

  # The lanes of the MIDI editor.
  #
  # Live 12 writes the lanes of its own session view: it has five lanes of the expressions and
  # three of the content, where Live 11 has four and two.
  it 'writes the lanes of the MIDI editor of Live 12' do
    expect(live_11_set.xpath('//LiveSet/ExpressionLanes/*').length).to eq 4
    expect(live_12_set.xpath('//LiveSet/ExpressionLanes/*').length).to eq 5
    expect(live_11_set.xpath('//LiveSet/ContentLanes/*').length).to eq 2
    expect(live_12_set.xpath('//LiveSet/ContentLanes/*').length).to eq 3
  end

  # The order Live 12 writes the children of an element in.
  #
  # The order is what tells the conversion where to put the elements Live 12 adds, and where
  # the elements that moved between the versions go.
  #
  # An element the set does not have is checked against the schema of Live 12 instead, which is
  # generated from the demo sets of Live 12 and says what Live writes.
  Live11And12::CHILD_ORDER[:up].each do |path, order|
    it "writes the children of #{path} in this order" do
      children = child_names(live_12_set, path)
      children = SchemaOrder.of_file(Schemas.path('12'), path.split('/').last) if children.empty?

      expect(children).to eq order
    end
  end

  # The elements Live 12 has that Live 11 does not.
  #
  # Each one is added by the conversion, with the attributes Live gives it.
  Live11And12::ADD[:up].group_by { |addition| addition[:parent] }.each do |parent, additions|
    it "adds these elements to #{parent}" do
      element = fullest(live_12_set, parent)

      # The set has no element of this kind, so the schema of Live 12 says what Live writes.
      if element.nil?
        order = SchemaOrder.of_file(Schemas.path('12'), parent.split('/').last)
        additions.each { |addition| expect(order).to include(addition[:name]) }
        next
      end

      additions.each do |addition|
        added = element.at_xpath("./#{addition[:name]}")
        expect(added).not_to be_nil, "#{parent} has no #{addition[:name]}"

        expect(structure(added)).to eq(expected_structure(addition))
      end
      # Every mismatch is reported, so that one run says everything that is wrong.
      aggregate_failures do
        additions.each do |addition|
          added = element.at_xpath("./#{addition[:name]}")
          next if added.nil?

          expect(structure(added)).to eq(expected_structure(addition))
        end
      end
    end

    it "adds nothing else to #{parent}" do
      named = additions.map { |addition| addition[:name] } + ADDED_BY_RULES.fetch(parent, [])
      expect(added_by_live12(parent) - named - ['SessionScrollPos']).to be_empty
    end
  end

  # The elements Live 11 has that Live 12 does not.
  #
  # Going up, these are removed. The ones the special rules remove are the chooser bar and the
  # song master values of the set, and the freeze elements of a track.
  it 'removes the elements Live 12 does not have' do
    removed = child_names(live_11_set, 'LiveSet').map { |name| live12_name(name) } - child_names(live_12_set, 'LiveSet')
    named = Live11And12::REMOVE_UNDER[:up].grep(%r{^LiveSet/}).map { |path| path.split('/').last }

    expect(removed - named - %w[ChooserBar SongMasterValues]).to be_empty
    expect(named - removed).to be_empty
  end

  it 'removes the elements of the view states Live 12 does not have' do
    removed = child_names(live_11_set, 'LiveSet/ViewStates') - child_names(live_12_set, 'LiveSet/ViewStates')
    named = Live11And12::REMOVE_UNDER[:up].grep(%r{^ViewStates/}).map { |path| path.split('/').last }

    expect(removed - named).to be_empty
    expect(named - removed).to be_empty
  end
end
