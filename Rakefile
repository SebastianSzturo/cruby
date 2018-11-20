# -*- mode: ruby; coding: utf-8 -*-


require 'open-uri'
require_relative 'config'


def read_file (path)
  open(path) {|f| f.read}
end

def write_file (path, data)
  open(path, 'w') {|f| f.write data}
end

def download (url, path)
  puts "downloading '#{url}'..."
  write_file path, read_file(url)
end

def chdir (dir = RUBY_DIR, &block)
  Dir.chdir dir, &block
end

def xcrun (sdk, param)
  `xcrun --sdk #{sdk} #{param}`.chomp
end

def version_string (major, minor = 0, patch = 0)
  [major, minor, patch].map {|n| "%03d" % n}.join
end

def ruby25_or_higher? ()
  version_string(*CRuby.ruby_version) >= version_string(2, 5)
end


PLATFORM = (ENV['platform'] || :osx).intern
ARCHS    =
  ENV['archs'].tap {|archs| break archs.split(/[ ,]+/) if archs} ||
  ENV['arch'] .tap {|arch|  break [arch]               if arch}

NAME        = "CRuby"
LIB_NAME    = "#{NAME}_#{PLATFORM}"

ROOT_DIR     = __dir__
INC_DIR      = "#{ROOT_DIR}/include"
RUBY_DIR     = "#{ROOT_DIR}/ruby"
BUILD_DIR    = "#{ROOT_DIR}/.build"
OUTPUT_DIR   = "#{ROOT_DIR}/CRuby"

CONFIGURE               = "#{RUBY_DIR}/configure"
NATIVE_RUBY_DIR         = "#{BUILD_DIR}/native"
NATIVE_RUBY_INSTALL_DIR = "#{BUILD_DIR}/native-install"
NATIVE_RUBY_BIN         = "#{NATIVE_RUBY_INSTALL_DIR}/bin/ruby"

OUTPUT_LIB_NAME = "lib#{LIB_NAME}.a"
OUTPUT_LIB_FILE = "#{OUTPUT_DIR}/#{OUTPUT_LIB_NAME}"
OUTPUT_LIB_DIR  = "#{OUTPUT_DIR}/lib"
OUTPUT_INC_DIR  = "#{OUTPUT_DIR}/include"

RUBY_ARCHIVE     = "#{ROOT_DIR}/#{File.basename RUBY_URL}"
OUTPUT_ARCHIVE   = "#{NAME}_prebuilt-#{CRuby.version}.tar.gz"
PREBUILT_URL     = "#{GITHUB_URL}/releases/download/v#{CRuby.version}/#{OUTPUT_ARCHIVE}"
PREBUILT_ARCHIVE = "downloaded_#{OUTPUT_ARCHIVE}"

TARGETS = {
  osx: {
    macosx:          %w[x86_64],
  },
  ios: {
    iphonesimulator: %w[x86_64 i386],
    iphoneos:        %w[armv7 armv7s arm64]
  }
}[PLATFORM]

PATHS = ENV['PATH']
ENV['ac_cv_func_setpgrp_void'] = 'yes'


task :default => :build

desc "delete all temporary files"
task :clean do
  sh %( rm -rf #{OUTPUT_ARCHIVE} #{BUILD_DIR} #{OUTPUT_DIR} )
end

desc "delete all generated files"
task :clobber => :clean do
  sh %( rm -rf #{RUBY_ARCHIVE} #{RUBY_DIR} )
end

desc "build"
task :build => [OUTPUT_LIB_DIR, OUTPUT_INC_DIR, OUTPUT_LIB_FILE]

directory RUBY_DIR
directory BUILD_DIR
directory OUTPUT_DIR
directory NATIVE_RUBY_DIR

file RUBY_ARCHIVE do |t|
  download RUBY_URL, RUBY_ARCHIVE
end

file CONFIGURE => [RUBY_ARCHIVE, RUBY_DIR] do
  sh %( tar xzf #{RUBY_ARCHIVE} -C #{RUBY_DIR} --strip=1 )
  sh %( touch #{CONFIGURE} )
end

file NATIVE_RUBY_BIN => [CONFIGURE, NATIVE_RUBY_DIR] do
  chdir NATIVE_RUBY_DIR do
    sh %( #{CONFIGURE} --prefix=#{NATIVE_RUBY_INSTALL_DIR} --disable-install-doc )
    sh %( make && make install )
  end
end

file OUTPUT_LIB_DIR => [CONFIGURE, OUTPUT_DIR] do
  sh %( cp -rf #{RUBY_DIR}/lib #{OUTPUT_DIR} )
  Dir.glob "#{RUBY_DIR}/ext/*/lib" do |lib|
    sh %( cp -rf #{lib}/* #{OUTPUT_LIB_DIR} ) unless Dir.glob("#{lib}/*").empty?
  end
end

file OUTPUT_INC_DIR => [CONFIGURE, OUTPUT_DIR] do
  sh %( cp -rf #{RUBY_DIR}/include #{OUTPUT_DIR} )
  sh %( cp -rf #{INC_DIR} #{OUTPUT_DIR})
end

file OUTPUT_LIB_FILE do |t|
  sh %( lipo -create #{t.prerequisites.join ' '} -output #{OUTPUT_LIB_FILE} )
end


desc "build files for all platforms"
task :all => [:osx, :ios]

desc "build files for macOS"
task :osx do
  sh %( rake platform=osx )
end

desc "build files for iOS"
task :ios do
  sh %( rake platform=ios )
end


desc "archive built files for deploy"
task :archive => OUTPUT_ARCHIVE

file OUTPUT_ARCHIVE => :all do
  sh %( tar cvzf #{OUTPUT_ARCHIVE} #{OUTPUT_DIR.sub(ROOT_DIR + '/', '')} )
end

desc "download prebuilt binary or build all"
task :download_or_build_all => PREBUILT_ARCHIVE do
  if File.exist?(PREBUILT_ARCHIVE)
    sh %( tar xzf #{PREBUILT_ARCHIVE} )
  else
    sh %( rake all )
  end
end

file PREBUILT_ARCHIVE do
  download PREBUILT_URL, PREBUILT_ARCHIVE rescue OpenURI::HTTPError
end


TARGETS.each do |sdk, archs|
  sdkroot = xcrun sdk, '--show-sdk-path'
  path    = xcrun(sdk, '--find cc').sub %r|/cc$|i, ''
  archs   = archs.select {|arch| ARCHS.include? arch} if ARCHS

  archs.each do |arch|
    namespace arch do
      arch_dir     = "#{BUILD_DIR}/#{sdk}_#{arch}"
      makefile     = "#{arch_dir}/Makefile"
      libruby_ver  = ruby25_or_higher? ? ".#{CRuby.ruby_version.join '.'}" : ""
      libruby      = "#{arch_dir}/libruby#{libruby_ver}-static.a"
      lib_file     = "#{arch_dir}/#{OUTPUT_LIB_NAME}"
      config_h     = "#{OUTPUT_INC_DIR}/ruby/config-#{PLATFORM}_#{arch}.h"
      config_h_dir = File.dirname config_h
      host         = "#{arch =~ /^arm/ ? 'arm' : arch}-apple-darwin"
      flags        = "-pipe -Os -isysroot #{sdkroot}"
      flags << " -miphoneos-version-min=7.0" if PLATFORM == :ios
      # -gdwarf-2 -no-cpp-precomp -mthumb

      directory arch_dir
      directory config_h_dir

      missing_headers = []
      if PLATFORM == :ios
        arch_inc_dir = "#{arch_dir}/include"
        vnode_h      = "#{arch_inc_dir}/sys/vnode.h"
        vnode_h_dir = File.dirname vnode_h

        directory vnode_h_dir

        file vnode_h => vnode_h_dir do
          write_file vnode_h, <<-END
            #ifndef DUMMY_VNODE_H_INCLUDED
            #define DUMMY_VNODE_H_INCLUDED
            enum {VREG = 1, VDIR = 2, VLNK = 5, VT_HFS = 16, VT_CIFS = 23};
            #endif
          END
        end

        missing_headers += [vnode_h]
        flags           += " -I#{arch_inc_dir}"
      end

      file makefile => [CONFIGURE, NATIVE_RUBY_BIN, arch_dir, *missing_headers] do
        chdir arch_dir do
          envs = {
            'PATH'     => "#{path}:#{PATHS}",
            'CPP'      => "clang -arch #{arch} -E",
            'CC'       => "clang -arch #{arch}",
            'CXXCPP'   => "clang++ -arch #{arch} -E",
            'CXX'      => "clang++ -arch #{arch}",
            'CPPFLAGS' => "#{flags}",
            'CFLAGS'   => "#{flags} -fvisibility=hidden",
            'CXXFLAGS' => "-fvisibility-inline-hidden",
            'LDFLAGS'  => "#{flags} -L#{sdkroot}/usr/lib -lSystem"
          }.map {|k, v| "#{k}='#{v}'"}
          opts = %W[
            --host=#{host}
            --disable-shared
            --with-baseruby=#{NATIVE_RUBY_BIN}
            --with-static-linked-ext
            --without-tcl
            --without-tk
            --without-fiddle
            --without-bigdecimal
            --disable-install-doc
          ]
          opts << "--with-arch=#{arch}" unless arch =~ /^arm/
          sh %( #{envs.join ' '} #{CONFIGURE} #{opts.join ' '} )
        end
      end

      file config_h => [makefile, config_h_dir] do
        src = Dir.glob "#{arch_dir}/.ext/include/**/ruby/config.h"
        raise unless src.size == 1
        sh %( cp #{src.first} #{config_h} )
      end

      file libruby => makefile do
        chdir arch_dir do
          sh %( make )
        end
      end

      file lib_file => [config_h, libruby] do
        chdir arch_dir do
          Dir.glob("#{arch_dir}/**/*.a") do |path|
            extract_dir = '.' + OUTPUT_LIB_NAME
            libfile_dir = path[%r|#{arch_dir}/(.+)\.a$|, 1]
            objs_dir    = "#{extract_dir}/#{libfile_dir}"

            sh %( mkdir -p #{objs_dir} && cp #{path} #{objs_dir} )
            chdir objs_dir do
              sh %( ar x #{File.basename path} )
            end
          end

          objs = Dir.glob "**/*.o"
          sh %( ar -crs #{lib_file} #{objs.join ' '} )
        end
      end

      file OUTPUT_LIB_FILE => lib_file

    end# arch
  end
end
