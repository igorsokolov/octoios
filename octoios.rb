#!/usr/bin/ruby
require 'optparse'
require 'ostruct'

class Processes

  def initialize(options = {})
    @processes = {}
    @options = options
    @ids = []
    @root_dir = File.expand_path(File.dirname(__FILE__))

    trap('TERM') { shutdown }
    trap('INT')  { shutdown }
    trap('QUIT') { shutdown }
    delete_zombie_processes

    @ids = `./fruitstrap -q -t 1 list-devices`.split("\n")
    abort 'No devices connected' if @ids.empty?
    puts "Connected devices (#{@ids.count}):"
    @ids.each{|_| puts _}

    puts "Build project"
    @options[:schema] = options[:schema]
    @options[:bundle_id] = options[:bundle_id]
    @options[:src_dir] = options[:src_dir]
    @options[:build_dir] = options[:build_dir] || File.join(@root_dir,"builds")
    system("cd #{@options[:src_dir]} && \
      xcodebuild -scheme #{@options[:schema]} -sdk iphoneos build \
      CONFIGURATION_BUILD_DIR='#{@options[:build_dir]}'") unless options[:no_build]
  end

  def start
    puts "Starting processes..."
    loop do
      clean_processes_list

      if id = get_next_id
        if @child = fork
          rand
          puts "Started #{id}: #{@child} "
          @processes[id] = @child
          Process.detach @child
        else
          @processes = {}
          $0 = "build-process:#{id}"

          # "Uninstall previous version"
          system("ruby transporter_chief.rb -v -d #{id} #{@options[:bundle_id]}")

          # "Install new build"
          system("ruby transporter_chief.rb -v -d #{id} #{@options[:build_dir]}/#{@options[:schema]}.app")

          # Run application
          tracetemplate = File.join(@root_dir,"Automation.tracetemplate")

          puts "Starting (#{@options[:schema]}) for device: #{id}"
          system("instruments -w #{id} -D #{File.join(@root_dir,"tmp/tmp.trace")} -t #{tracetemplate} #{@options[:schema]}")

          puts "Process for #{id} exits!"
          exit!
        end
        @child = nil
      else
        sleep 5
      end
    end
  end

  def get_next_id
    @ids.each do |id|
      return id unless @processes.keys.include? id
    end
    nil
  end

  def shutdown
    if @child.nil? and !@processes.empty?
      syscmd = "kill -s QUIT #{@processes.values.join(' ')}"
      puts "#{Process.pid}: Running syscmd: #{syscmd}"
      system(syscmd)
      sleep 1
      syscmd = "kill -s KILL #{@processes.values.join(' ')}"
      puts "#{Process.pid}: Running syscmd: #{syscmd}"
      system(syscmd)
    end
    exit!
  end

  def clean_processes_list
    @processes.delete_if { |id, pid| !process_pids.include?(pid.to_s) }
  end

  def delete_zombie_processes
    process_pids.each do |pid|
      Process.kill("KILL", pid.to_i) unless @processes.values.include? pid
    end
  end

  def process_pids
    `ps -A -o pid,command | grep 'build-proces[s]'`.split("\n").map do |line|
      line.split(' ')[0]
    end
  end
end

options = {:no_build => false}
option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} [options]"

  opts.separator ""
  opts.separator "Options:"

  opts.on('-s', '--schema SCHEMA', 'Build schema') do |schema|
    options[:schema] = schema
  end

  opts.on('-i', '--bundle_id BUNDLE_ID', 'Bundle identifier of project') do |bundle_id|
    options[:bundle_id] = bundle_id
  end

  opts.on('-b', '--build_dir BUILD_DIR', 'Builds directory') do |build_dir|
    options[:build_dir] = build_dir
  end

  opts.on('-r', '--src_dir SRC_DIR', 'Source directory') do |src_dir|
    options[:src_dir] = src_dir
  end

  opts.on('-n', '--no_build', 'Skip build project path') do
    options[:no_build] = true
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end

if ARGV.length < 3
  puts option_parser
  exit
else
  option_parser.parse!
end

Processes.new(options).start