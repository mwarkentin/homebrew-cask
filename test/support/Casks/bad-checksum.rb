class BadChecksum < TestCask
  url TestHelper.local_binary('caffeine.zip')
  homepage 'http://example.com/local-caffeine'
  version '1.2.3'
  sha1 'badbadbadbadbadbadbadbadbadbad'
  link 'Caffeine.app'
end
