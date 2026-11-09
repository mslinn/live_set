# Control Ableton Live With OSC

Automating Ableton Live from Ruby is best done using Open Sound Control (OSC)
combined with Ableton Live's remote scripting interface or a Ruby OSC library.
[1] (https://github.com/ideoforms/AbletonOSC), [2]
(https://opensoundcontrol.stanford.edu/implementations/ruby-osc.html)


## Installation

To control Ableton Live from Ruby, you need a bridge inside Live that listens
for network commands.

1. Install AbletonOSC:

   * This is a free, open-source MIDI Remote Script for Ableton Live that
     exposes Live's entire Live Object Model (LOM) API via OSC.

   * Place the AbletonOSC folder into your Ableton User Library/Remote Scripts
     directory.

   * Enable AbletonOSC under Ableton's Preferences > Link / Tempo / MIDI as a
     Control Surface.

   * It listens for incoming OSC messages on port 11000 and replies on port
     11001. [1](https://nime.org/proc/nime2023_60/),
            [2](https://github.com/ideoforms/AbletonOSC)

2. Use a Ruby OSC Client Library:

In Ruby, use the ruby-osc gem (gem install ruby-osc) to dispatch UDP packets
directly to Ableton Live's local port. [1]
(https://opensoundcontrol.stanford.edu/implementations/ruby-osc.html)


## Example Ruby Script

Here is a basic script using ruby-osc to send OSC commands to Ableton Live via
AbletonOSC:

```ruby
require 'osc-ruby'

# Set up the client pointing to Ableton's listening port (11000)
client = OSC::Client.new('127.0.0.1', 11000)

# Example 1: Start Live transport playback
client.send(OSC::Message.new('/live/song/start_playing'))

# Example 2: Set track 0 volume to 0.8 (scaled 0.0 to 1.0)
client.send(OSC::Message.new('/live/track/set/volume', 0, 0.8))

# Example 3: Fire clip 0 on track 0 (Session View)
client.send(OSC::Message.new('/live/clip/fire', 0, 0))

# Example 4: Query the current tempo from Ableton (listens on port 11001)
server = OSC::Server.new(11001)
server.add_pattern('/live/song/get/tempo') do |message|
  puts "Current Ableton Tempo: #{message.to_a.first}"
end
```


## Run server briefly to catch feedback

Using `sleep` is bad form! polling is better, but callbacks are best.

```Ruby
Thread.new { server.run }
client.send(OSC::Message.new('/live/song/get/tempo'))
sleep(1)
server.stop
```


## Alternative File-Level Automation (Offline)

If you do not need real-time performance control and instead want to inspect,
generate, or modify Ableton Live project files (.als are gzipped XML files), you
can use the community Ruby gem: [1]
(https://news.ycombinator.com/item?id=30485195)
