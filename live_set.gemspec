require_relative 'lib/live_set/version'

Gem::Specification.new do |spec|
  host = 'https://github.com/mslinn/live_set'

  spec.authors               = ['Mike Slinn']
  spec.bindir                = 'exe'
  spec.executables           = %w[live_set]
  spec.description           = <<~END_DESC
    Reports the version of an Ableton Live set, and optionally changes it to v11 format.
  END_DESC
  spec.email                 = ['mslinn@mslinn.com']
  spec.files                 = Dir['.rubocop.yml', 'LICENSE.*', 'Rakefile', '{lib,spec}/**/*', '*.gemspec', '*.md']
  spec.homepage              = 'https://github.com/mslinn/live_set'
  spec.license               = 'MIT'
  spec.metadata = {
    'allowed_push_host' => 'https://rubygems.org',
    'bug_tracker_uri'   => "#{host}/issues",
    'changelog_uri'     => "#{host}/CHANGELOG.md",
    'homepage_uri'      => spec.homepage,
    'source_code_uri'   => host,
  }
  spec.name                 = 'live_set'
  spec.post_install_message = <<~END_MESSAGE

    Thanks for installing #{spec.name}!

  END_MESSAGE
  spec.require_paths         = ['lib']
  spec.required_ruby_version = '>= 2.7'
  spec.summary               = 'Reports the version of an Ableton Live set, and optionally changes it to v11 format.'
  spec.version               = LiveSetVersion::VERSION

  spec.add_dependency 'colorator'
  spec.add_dependency 'nokogiri'
end
