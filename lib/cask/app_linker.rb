class Cask
  class AppLinker
    def initialize(cask)
      @cask = cask
    end

    def link
      @cask.linkable_apps.each do |app|
        link_app(app)
      end
    end

    def unlink
      @cask.linkable_apps.each do |app|
        unlink_app(app)
      end
    end

    def unlink_app(app)
      app_path = self.class.remove_extension_if_necessary(Cask.appdir.join(app.basename))
      if finder_alias?(app_path)
        path.delete
      end
    end

    def remove_app_extension(path)
      Pathname(path.to_s.sub(/\.app$/, ''))
    end

    def link_app(app)
      app_path = self.class.remove_extension_if_necessary(Cask.appdir.join(app.basename))
      if app_path.directory?
        ohai "It seems there is already an app at #{app_path}; not linking."
        return
      end
      make_alias(app, Cask.appdir)
    end

    class FinderAliasFailed < RuntimeError; end

    def make_alias(from_file, to_dir)
      to_path = self.class.remove_extension_if_necessary(to_dir.join(from_file.basename))
      tries = 3
      begin
        # deleting the file beforehand prevents "Foo.app alias" files
        # getting littered in the destination when linkapps is run more
        # than once; cuz idempotency
        #
        # the delete needs to be done from applescript otherwise the alias
        # command doesn't "see" the removal and will continue to spit out a
        # suffix
        self.class.osascript(%Q(
          tell application "Finder"
            if exists POSIX file "#{to_path}"
              delete POSIX file "#{to_path}"
            end if
            make alias file to POSIX file "#{from_file}" at POSIX file "#{to_dir}"
          end tell
        ))
        raise FinderAliasFailed.new(to_path) unless to_path.exist?
      rescue FinderAliasFailed => e
        # Sigh, it seems that *sometimes* when you install an app and
        # immediately attempt to link it, the file system has not "caught up"
        # or something so applescript is unable to make the alias.
        #
        # So here's a dirty hack around it.
        raise unless tries > 0
        tries -= 1
        opoo "alias creation failed for #{e.message} retrying" unless ENV['QUIET_TESTS']
        sleep 1 
        retry
      end
    end

    def self.osascript(applescript, stderr=false)
      command = "osascript -e '#{applescript}'"
      unless stderr
        command << " 2> /dev/null"
      end
      `#{command}`.chomp
    end

    FINDER_ALIAS_MAGIC_PREFIX = "book\x00\x00\x00\x00mark\x00\x00\x00\x00"

    def finder_alias?(filename)
      return false if not File.file? filename
      File.open(filename) do |f|
        return f.read(FINDER_ALIAS_MAGIC_PREFIX.length) == FINDER_ALIAS_MAGIC_PREFIX
      end
    end

    def self.remove_extension_if_necessary(path)
      all_extensions_shown? ? path : Pathname(path.to_s.sub(/\.app$/, ''))
    end

    def self.all_extensions_shown?
      @all_extensions_shown ||= (`defaults read -g AppleShowAllExtensions 2>/dev/null`.chomp == '1')
    end
  end
end
