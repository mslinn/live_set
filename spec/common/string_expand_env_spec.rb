require 'spec_helper'
require 'common/util'

RSpec.describe String, '#expand_env' do
  around do |example|
    original = ENV.to_hash
    example.run
    ENV.replace(original)
  end

  before do
    ENV['V'] = 'VAL'
    ENV['WITH_SPACE'] = 'has space'
  end

  describe 'the $NAME form' do
    it 'expands the variable' do
      expect('$V'.expand_env).to eq('VAL')
    end

    it 'expands a variable in the middle of a path' do
      expect('/music/$V/song.mp3'.expand_env).to eq('/music/VAL/song.mp3')
    end

    it 'expands adjacent variables' do
      expect('$V$V'.expand_env).to eq('VALVAL')
    end
  end

  describe 'the ${NAME} form' do
    it 'expands the variable' do
      expect('${V}'.expand_env).to eq('VAL')
    end

    it 'expands a variable followed by more text' do
      expect('${V}tail'.expand_env).to eq('VALtail')
    end

    it 'expands a variable whose name contains an underscore' do
      ENV['MY_VAR'] = 'value'
      expect('${MY_VAR}'.expand_env).to eq('value')
    end
  end

  describe 'the %NAME% form' do
    it 'expands the variable' do
      expect('%V%'.expand_env).to eq('VAL')
    end
  end

  describe 'a variable that is not set' do
    it 'expands to an empty string' do
      expect('$NOPE'.expand_env).to eq('')
    end

    it 'expands to an empty string in the braced form' do
      expect('${NOPE}'.expand_env).to eq('')
    end

    it 'expands to an empty string in the percent form' do
      expect('%NOPE%'.expand_env).to eq('')
    end
  end

  describe 'a string with no variables' do
    it 'is unchanged' do
      expect('/plain/path.als'.expand_env).to eq('/plain/path.als')
    end
  end
end
