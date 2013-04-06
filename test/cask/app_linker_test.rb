require 'test_helper'

describe Cask::AppLinker do
  describe 'linkapps' do
    describe 'with caffeine' do
      before do
        @caffeine = Cask.load('local-caffeine')
        shutup { Cask::Installer.install(@caffeine) }
        @app = @caffeine.destination_path/'Caffeine.app'
      end

      after do
        Cask::Installer.uninstall(@caffeine)
      end

      it "works with an application in the root directory" do
        Cask::AppLinker.new(@caffeine).link
        TestHelper.valid_alias?(Cask.appdir/'Caffeine.app').must_equal true
      end

      it "works with an application in a subdir" do
        appsubdir = @caffeine.destination_path/'subdir'
        appsubdir.mkpath
        FileUtils.mv @app, appsubdir
        appinsubdir = appsubdir/'Caffeine.app'

        Cask::AppLinker.new(@caffeine).link

        TestHelper.valid_alias?(Cask.appdir/'Caffeine.app').must_equal true
      end

      it "only uses linkables when they are specified" do
        FileUtils.cp_r @app, @app.sub('Caffeine.app', 'CaffeineAgain.app')

        Cask::AppLinker.new(@caffeine).link

        TestHelper.valid_alias?(Cask.appdir/'Caffeine.app').must_equal true
        TestHelper.valid_alias?(Cask.appdir/'CaffeineAgain.app').must_equal false
      end
    end

    describe 'with transmission' do
      before do
        @transmission = Cask.load('local-caffeine')
        shutup { Cask::Installer.install(@transmission) }
        @app = @transmission.destination_path/'Transmission.app'
      end

      after do
        Cask::Installer.uninstall(@transmission)
      end

      it "avoids clobbering an existing app by linking over it" do
        (Cask.appdir/'Transmission.app').mkdir

        shutup do
          Cask::AppLinker.new(@transmission).link
        end

        (Cask.appdir/'Transmission.app').directory?.must_equal true
      end

      it "does not litter extra aliases around when linking twice" do
        Cask::AppLinker.new(@transmission).link
        Cask::AppLinker.new(@transmission).link

        (Cask.appdir/'Transmission.app alias').wont_be :file?
      end
    end
  end
end
