require 'tmpdir'

# wire in a fake appdir per-test
module FakeAppdirHooks
  def before_setup
    super
    @canned_appdir = Pathname(Dir.mktmpdir('homebrew-cask-tests'))
    Cask.appdir = @canned_appdir
  end

  def after_teardown
    super
    @canned_appdir.rmtree
  end
end

class MiniTest::Spec
  include FakeAppdirHooks
end
