#!/usr/bin/env ruby
# Copyright (C) 2012-2013 Simon Sigurdhsson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject
# to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
require 'optparse'
require 'socket'

class DotfileDSL
	def initialize(options = {})
		# Defaults
		defaults = {
			:source  => "#{Dir.home}/.dotfiles",
			:dest    => Dir.home,
			:verbose => false,
			:quiet   => false,
			:rules   => "#{Dir.home}/.dotfiles/Rules"
		}
		# Options
		options.merge!(defaults){ |k,o,n| o.nil? ? n : o }
		@sourcepath = options[:source]
		@destpath = options[:dest]
		@verbose = options[:verbose]
		@quiet = options[:quiet]
		@rules = options[:rules]
		@dry = options[:dry]
		@debug = options[:debug]
		# Variables
		@prefix = ''
		@oldpwd = Dir.pwd
		Dir.chdir(@sourcepath)
		@unhandled_files = Dir.glob(["*/**/*"])
		@used_targets = Array.new
		@safe_targets = File.exists?(File.absolute_path("#{@sourcepath}/.safe-targets")) ? File.readlines(File.absolute_path("#{@sourcepath}/.safe-targets")).map{|i| i.strip} : []
		puts "#{@unhandled_files.length} sources to process, #{@safe_targets.length} known safe targets." if @verbose
		# For use in the Rules file
		@machine = Socket.gethostname.gsub('.local','')
	end

	def directories(dirs, &block)
		dirs.each do |dir|
			directory(dir, &block)
		end
	end

	def directory(dir, &block)
		@prefix = "#{dir}/"
		block.call
		@prefix = ''
	end

	def compile()
		self.instance_eval(File.read(@rules))
	end

	def finalize()
		File.open(File.absolute_path("#{@sourcepath}/.safe-targets"), 'w'){ |f| f.puts @used_targets } unless @dry
		(@safe_targets - @used_targets).each do |file|
			file = file.sub("#{@destpath}/", '')
			puts "\e[33mREMOVE: \e[0m ~/#{file} wasn't regenerated" if @verbose
			File.unlink(File.absolute_path("#{@destpath}/#{file}")) unless @dry
		end
		puts "#{@unhandled_files.length} unprocessed sources." if @verbose
		Dir.chdir(@oldpwd)
		if @debug
			puts "\e[31mUnprocessed sources:\e[0m"
			@unhandled_files.each{ |file| puts file }
		end
	end

	def ignore(regex)
		r = Regexp.new(regex)
		@unhandled_files.reject! do |file|
			next nil unless r.match(file)
			puts "\e[33mIGNORE: \e[0m #{file} \e[1m\e[30m(matched #{regex})\e[0m" if @verbose
			next true
		end
	end

	def symlink(regex, target)
		r = Regexp.new("#{@prefix}#{regex}")
		@unhandled_files.reject! do |file|
			next nil unless r.match(file)
			thistarget = "#{target}" # Force a copy of the string
			r.match(file).to_a.each_with_index do |value,key|
				thistarget.sub!("$#{key}", value)
			end
			puts "\e[32mSYMLINK:\e[0m #{file} \e[1m\e[34m=>\e[0m ~/#{thistarget} \e[1m\e[30m(matched #{regex})\e[0m" if @verbose
			abs_source = File.absolute_path("#{@sourcepath}/#{file}")
			abs_target = File.absolute_path("#{@destpath}/#{thistarget}")
			if File.exists?(abs_target) 
				if not @safe_targets.include?(abs_target)
					next true if @quiet
					puts "\e[31mWARNING:\e[0m Will not replace existing target ~/#{thistarget}"
					puts "         Please remove the file or modify your \e[35msymlink '#{regex}'\e[0m rule."
					next true
				elsif @used_targets.include?(abs_target)
					next true if @quiet
					puts "\e[31mWARNING:\e[0m Will not replace already used target ~/#{thistarget}"
					puts "         Please check your rules file for inconsistencies."
					next true
				else
					File.unlink(abs_target) unless @dry
				end
			end
			File.symlink(abs_source, abs_target) unless @dry
			@used_targets << abs_target
			next true
		end
	end

	def merge(regex, target, group = 1)
		r = Regexp.new("#{@prefix}#{regex}")
		merge = Hash.new
		@unhandled_files.reject! do |file|
			next nil unless r.match(file)
			abs_file = File.absolute_path("#{@sourcepath}/#{file}")
			thistarget = r.match(file)[group] or 'generic'
			thistarget = 'generic' if group == 0
			merge[thistarget] = [] unless merge[thistarget]
			merge[thistarget] << abs_file unless File.directory?(abs_file)
			puts "\e[31mWARNING:\e[0m Will not merge folder #{file}" if File.directory?(abs_file)
			next true
		end
		merge.each do |key, merge|
			return if merge.empty?
			thistarget = "#{target}" # Force copy string
			r.match(merge[0]).to_a.each_with_index do |value,key|
				thistarget = target.sub("$#{key}", value)
			end
			puts "\e[32mMERGE:  \e[0m #{merge.length} file(s) \e[1m\e[34m=>\e[0m ~/#{thistarget} \e[1m\e[30m(matched #{regex})\e[0m" if @verbose
			abs_target = File.absolute_path("#{@destpath}/#{thistarget}")
			if File.exists?(abs_target) and not @safe_targets.include?(abs_target)
				return true if @quiet
				puts "\e[31mWARNING:\e[0m Will not replace existing target ~/#{thistarget}" 
				puts "         Please remove the file or modify your \e[35mmerge '#{regex}'\e[0m rule." 
				return true
			elsif File.exists?(abs_target) and @used_targets.include?(abs_target)
				puts "\e[33mNOTICE: \e[0m Appending to already used target ~/#{thistarget}" if @verbose
			end
			File.unlink(abs_target) if File.symlink?(abs_target) and not @dry
			flag = @used_targets.include?(abs_target) ? 'a' : 'w'
			File.open(abs_target, flag) do |out|
				merge.each do |source|
					out.write(File.read(source))
					out.write("\n\n")
				end
			end unless @dry
			@used_targets << abs_target
		end
	end
end

class DotfileCLI
	def initialize()
		@options = Hash.new
	end

	def parse(args)
		opts = OptionParser.new do |opts|
			opts.banner = "Usage: ./dotfiles.rb [options]"
			opts.separator ""
			opts.separator "Common options:"
			# Verbosity
			opts.on('-v', '--verbose', "Be more verbose") do
				@options[:verbose] = true unless @options[:quiet]
			end
			opts.on('-q', '--quiet', "Be completely silent") do
				@options[:quiet] = true
				@options[:verbose] = false
			end
			# Dry run
			opts.on('-n', '--dry-run', "Perform a dry run") do
				@options[:dry] = true
			end
			# Debug
			opts.on('-d', '--debug', "Print debug information") do
				@options[:debug] = true
			end
			# Help
			opts.on('-h', '--help', "Display this screen") do
				puts opts
				exit
			end
			# Paths
			opts.separator ""
			opts.separator "Path settings:"
			opts.on_tail('-r', '--rules FILE', "Rules file to read") do |file|
				@options[:rules] = file
			end
			opts.on_tail('--source PATH', "Source file location") do |path|
				@options[:source] = path
			end
			opts.on_tail('--destination PATH', "Destination path") do |path|
				@options[:dest] = path
			end
		end
		opts.parse!(args)
		@rules = '#{options[:source]}/Rules' unless @rules
	end

	def run()
		dotfiles = DotfileDSL.new(@options)
		dotfiles.compile
		dotfiles.finalize
	end

	def self.run!()
		cli = DotfileCLI.new
		cli.parse(ARGV)
		cli.run
	end
end

DotfileCLI.run! if __FILE__==$0
