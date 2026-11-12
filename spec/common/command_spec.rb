require 'spec_helper'
require 'common/command'

# A command that says what it does, and what its options mean.
#
# It stands for the commands of the program, which are all of this shape.
class ExampleCommand
  extend Command

  def self.help(msg = nil)
    help = <<~END_HELP
      Example_command does something.

      Syntax: example_command OPTIONS FILE

      Options are:
        -v Show the version of this program.
        -z ZONE The time zone to use.
        -h Display this help message.
    END_HELP

    msg.nil? ? help : "Error: #{msg}\n\n#{help}"
  end

  def self.parser
    OptionParser.new do |parser|
      parser.program_name = 'example_command'

      parser.on('-v', '--version', 'Show the version of this program')
      parser.on('-z', '--time_zone ZONE', String, 'The time zone to use')

      parser.on_tail('-h', '--help', 'Show this message') do
        abort help
      end
    end
  end
end

# The parsing of the options of a command.
#
# Every command of the program extends the Command module, and the module holds the parts
# that are the same everywhere: the parsing of the options, the check of the log level, and
# the handling of the errors of the parser.
RSpec.describe Command do
  it 'parses the options of the command' do
    options, remaining = ExampleCommand.parse_options(['-v', 'set.als'])

    expect(options[:version]).to be true
    expect(remaining).to eq ['set.als']
  end

  it 'finds the options that come after the arguments' do
    options, remaining = ExampleCommand.parse_options(['set.als', '-v'])

    expect(options[:version]).to be true
    expect(remaining).to eq ['set.als']
  end

  it 'says so when it is given an option it does not understand' do
    expect { ExampleCommand.parse_options(['--bogus', 'set.als']) }
      .to raise_error(SystemExit)
      .and output(/invalid option: --bogus/).to_stderr
  end

  it 'says so when an option is missing its argument' do
    expect { ExampleCommand.parse_options(['-z']) }
      .to raise_error(SystemExit)
      .and output(/missing argument: -z/).to_stderr
  end

  it 'prints the help of the command with the error' do
    expect { ExampleCommand.parse_options(['--bogus']) }
      .to raise_error(SystemExit)
      .and output(/Syntax: example_command OPTIONS FILE/).to_stderr
  end

  describe '.check_extra_parameters' do
    it 'says nothing when the command is given the parameters it takes' do
      expect { ExampleCommand.check_extra_parameters(['set.als'], 1) }.not_to raise_error
    end

    it 'says nothing when the command is given fewer parameters than it takes' do
      expect { ExampleCommand.check_extra_parameters([], 1) }.not_to raise_error
    end

    it 'says so when the command is given more parameters than it takes' do
      expect { ExampleCommand.check_extra_parameters(['set.als', 'extra'], 1) }
        .to raise_error(SystemExit)
        .and output(/Extra positional parameter\(s\): only 1 expected/).to_stderr
    end

    it 'prints the help of the command with the error' do
      expect { ExampleCommand.check_extra_parameters(['set.als', 'extra'], 1) }
        .to raise_error(SystemExit)
        .and output(/Syntax: example_command OPTIONS FILE/).to_stderr
    end
  end
end
