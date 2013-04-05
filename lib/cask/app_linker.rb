class Cask
  class AppLinker
    def initialize(cask)
      @cask = cask
    end

    def link
      if @cask.specifies_linkables?(:app)
        @cask.linkables[:app].each do |app|
          link_specified(app)
        end
      else
        link_everything
      end
    end

    def link_specified(app)
      link_app(Pathname.glob("#{@cask.destination_path}/**/#{app}").first)
    end

    def link_everything
      Pathname.glob("#{@cask.destination_path}/**/*.app").each do |app|
        link_app(app)
      end
    end

    def link_app(app)
      app_path = Cask.appdir.join(app.basename)
      if app_path.directory?
        ohai "It seems there is already an app at #{app_path}; not linking."
        return
      end
      make_alias(app, Cask.appdir)
    end

    def make_alias(from_file, to_dir)
      to_path = to_dir.join(from_file.basename)
      # deleting the file beforehand prevents "Foo.app alias" files
      # getting littered in the destination when linkapps is run more
      # than once; cause idempotency
      self.class.osascript(%Q(
        tell application "Finder"
          if exists POSIX file "#{to_path}" then
            delete POSIX file "#{to_path}"
          end if
        end tell
        tell application "Finder" to make alias file to POSIX file "#{from_file}" at POSIX file "#{to_dir}"
      ))
    end

    def self.osascript(applescript, stderr=false)
      command = "osascript -e '#{applescript}'"
      unless stderr
        command << " 2> /dev/null"
      end
      `#{command}`.chomp
    end
  end
end
