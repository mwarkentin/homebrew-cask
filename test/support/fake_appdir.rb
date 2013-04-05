require 'pp'

# wire in a fake appdir per-test
module FakeAppdirHooks
  def before_setup
    super
    @canned_appdir = HOMEBREW_REPOSITORY/"Applications-#{Time.now.to_i}"
    @canned_appdir.mkpath
    puts `ls -ld #{@canned_appdir}`
    `touch #{@canned_appdir}/i_can_write_here`
    Cask.appdir = @canned_appdir
  end

  def after_teardown
    super
    pp @canned_appdir.entries
    @canned_appdir.rmtree
  end
end

class MiniTest::Spec
  include FakeAppdirHooks
end
