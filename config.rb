# -*- mode: ruby; coding: utf-8 -*-


POD_VERSION = 2

GITHUB_URL  = "https://github.com/xord/cruby"

RUBY_URL    = 'https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.3.tar.gz'
RUBY_SHA256 = '577fd3795f22b8d91c1d4e6733637b0394d4082db659fccf224c774a2b1c82fb'

OSSL_URL    = 'https://www.openssl.org/source/openssl-1.1.1c.tar.gz'
OSSL_SHA256 = 'f6fb3079ad15076154eda9413fed42877d668e7069d9b87396d0804fdb3f4c90'


module CRuby
  def self.version ()
    *heads, patch = ruby_version
    [*heads, patch * 100 + POD_VERSION].join '.'
  end

  def self.ruby_version ()
    m = RUBY_URL.match /ruby\-(\d)\.(\d)\.(\d)(?:\-\w*)?\.tar\.gz/
    raise "invalid ruby version" unless m && m.captures.size == 3
    m.captures.map &:to_i
  end
end
