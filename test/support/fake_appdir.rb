# wire in a fake appdir per-test
module FakeAppdirHooks
  def before_setup
    super
    @canned_appdir = HOMEBREW_REPOSITORY/"Applications"
    @canned_appdir.mkpath
    Cask.appdir = @canned_appdir
  end

  def after_teardown
    super
    return if @canned_appdir.entries.grep(/.app$/).empty?

    Cask::AppLinker.osascript(%Q(
tell application "Finder"
  set appfiles to files in folder (POSIX file "#{@canned_appdir}" as text)

  repeat with appfile in appfiles
    delete appfile
  end repeat
end tell
    ), true)
end
end

class MiniTest::Spec
  include FakeAppdirHooks
end
