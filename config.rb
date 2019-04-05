# -*- mode: ruby; coding: utf-8 -*-


POD_VERSION = 0

GITHUB_URL  = "https://github.com/xord/cruby"

{
  '2.6' => {
    url:    'https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.1.tar.gz',
    sha256: '17024fb7bb203d9cf7a5a42c78ff6ce77140f9d083676044a7db67f1e5191cb8'
  },
  '2.5' => {
    url:    'https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.5.tar.gz',
    sha256: '28a945fdf340e6ba04fc890b98648342e3cccfd6d223a48f3810572f11b2514c'
  },
  '2.4' => {
    url:    'https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.6.tar.gz',
    sha256: 'de0dc8097023716099f7c8a6ffc751511b90de7f5694f401b59f2d071db910be'
  },
}['2.5'].tap {|ruby|
  RUBY_URL    = ruby[:url]
  RUBY_SHA256 = ruby[:sha256]
}


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
