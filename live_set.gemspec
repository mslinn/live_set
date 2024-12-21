require_relative 'lib/live_set/version'

Gem::Specification.new do |spec|
  host = 'https://github.com/mslinn/live_set'

  spec.authors               = ['Mike Slinn']
  spec.bindir                = 'exe'
  spec.executables           = %w[als_delta live_set]
  spec.description           = <<~END_DESC
    Live_set program can:
      - Make a copy of an Ableton Live 12 set and save to Live 11 format.
      - Report the version compatibility of an Ableton Live set.
      - Detect environmental problems, for example unwanted directories called Ableton Project Info in parent directories.
      - Display the location and size of the samples in each track.
      - Clearly show if a Live set is ready to be transferred to a Push 3 Standalone, and what needs to be changed if not.
        - Detect sets that are too large to be frozen, which means they are too large to transfer to Push 3 Standalone.
        - Detect tracks that are not frozen, which means they are not ready to be transferred to Push 3 Standalone.
        - Shows clips that are have not been collected within the set’s project directory.

    Live_set has successfully converted the Ableton Live 12 demo project to Live 11.
  END_DESC
  spec.email                 = ['mslinn@mslinn.com']
  spec.files                 = Dir['.rubocop.yml', 'LICENSE.*', 'Rakefile', '{lib,spec}/**/*', '*.gemspec', '*.md']
  spec.homepage              = 'https://mslinn.com/av_studio/553-live_set.html'
  spec.license               = 'MIT'
  spec.metadata = {
    'allowed_push_host' => 'https://rubygems.org',
    'bug_tracker_uri'   => "#{host}/issues",
    'changelog_uri'     => "#{host}/CHANGELOG.md",
    'homepage_uri'      => spec.homepage,
    'source_code_uri'   => host,
  }
  spec.name                 = 'live_set'
  spec.platform             = Gem::Platform::RUBY
  spec.post_install_message = <<~END_MESSAGE

    Thanks for installing #{spec.name}!

  END_MESSAGE
  spec.require_paths         = ['lib']
  spec.required_ruby_version = '>= 2.7'
  spec.summary               = 'Reports the version of an Ableton Live set, and optionally changes it to v11 format.'
  spec.version               = LiveSetVersion::VERSION

  spec.add_dependency 'bytesize'
  spec.add_dependency 'colorator'
  spec.add_dependency 'highline'
  spec.add_dependency 'nokogiri'
end
