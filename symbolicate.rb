#!/usr/bin/env ruby
# encoding: utf-8

require 'find'
require 'pathname'
require 'fileutils'

def process_dir(rpath)
  path = Pathname.new(rpath).realpath
  puts("Processing dir #{path}")

  Find.find(path) do |npath|
    if FileTest.file?(npath)
      next if npath =~ /.*-test$/i
      process_file(npath)
    end
  end
end

def is_elf(path)
  return File.open(path).read(4).unpack("I")[0] == 1179403647 # 0x7F,ELF
end

def process_file(file)
  return false if not is_elf(file)
  puts("Processing file: #{file}")

  basename = File.basename(file)
  cmdline = "./dump_syms #{file} > /tmp/#{basename}.sym 2> /dev/null"
  `#{cmdline}` # ignore output
  if not File.exists?("/tmp/#{basename}.sym")
    puts("Fatal: dump_syms failed")
    return false
  end

  if IO.readlines("/tmp/#{basename}.sym")[0] =~ /.* ([0-9a-fA-F]+) .*/
    buildid = $1
  else
    puts("Can't locate build id, dump_syms failed?")
    return false
  end

  FileUtils.mkdir_p("symbols/#{basename}/#{buildid}")
  FileUtils.mv("/tmp/#{basename}.sym", "symbols/#{basename}/#{buildid}", :force => true)
end

def main(args)
  if args.size == 0
    puts("Enter directory, or file, as first arg.")
    return 1
  end

  destpath = args[0]
  if FileTest.directory?(destpath)
    process_dir(destpath)
  else
    process_file(destpath)
  end
end

main $*
