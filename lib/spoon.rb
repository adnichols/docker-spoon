require "spoon/version"
require 'docker'
require 'json'
require 'uri'
require 'rainbow'
require 'optparse'

module Spoon
  class Client

    attr_accessor :options
    @options = {}

    # This combines our default configs with our command line and config file
    # configurations in the desired precedence
    def self.combine_config
      config = self.parse(ARGV)

      # init config only options
      @options["pre-build-commands"] = []
      @options[:copy_on_create] = []
      @options[:run_on_create] = []
      @options[:add_authorized_keys] = false
      @options[:command] = ''

      # init command line options
      @options[:builddir] = '.'
      @options[:url] = ::Docker.url
      @options[:image] = 'spoon-pairing'
      @options[:prefix] = 'spoon-'
      @options[:privileged] ||= false

      # Eval config file
      D "Config file is: #{config[:config]}"
      options = {}
      if File.exists?(config[:config])
        eval(File.read(config[:config]))
      else
        puts "File #{config[:config]} does not exist"
        exit(1)
      end

      # Read in config file values
      options.each do |k, v|
        @options[k] = v
      end

      # Read in command line values
      config.each do |k, v|
        @options[k] = v
      end

      @options
    end

    def self.main

      instance = false
      @options = combine_config
      instance = ARGV[0]
      D @options.inspect
      if @options[:list]
        instance_list
      elsif @options["list-images"]
        image_list
      elsif @options[:build]
        image_build
      elsif @options[:destroy]
        instance_destroy(apply_prefix(@options[:destroy]))
      elsif @options[:kill]
        instance_kill(apply_prefix(@options[:kill]))
      elsif @options[:restart]
        instance_restart(apply_prefix(@options[:restart]))
      elsif @options[:network]
        instance_network(apply_prefix(@options[:network]))
      elsif instance
        instance_connect(apply_prefix(instance), @options[:command])
      else
        puts("You either need to provide an action or an instance to connect to")
        exit
      end
    end

    def self.parse(args)
      config = {}
      optparser = OptionParser.new do |opts|

        opts.banner = "Usage: spoon [@options] [instance name]\n\n"
        opts.banner += "Create & Connect to pairing environments in Docker\n\n"

        opts.program_name = "spoon"

        opts.on("-l", "--list", "List available spoon instances") do
          config[:list] = true
        end
        opts.on("-d", "--destroy NAME", "Destroy spoon instance with NAME") do |destroy|
          config[:destroy] = destroy
        end
        opts.on("-b", "--build", "Build image from Dockerfile using name passed to --image") do
          config[:build] = true
        end
        opts.on("-n", "--network NAME", "Display exposed ports using name passed to NAME") do |name|
          config[:network] = name
        end
        opts.on("--restart NAME", "Restart the specified spoon instance") do |name|
          config[:restart] = name
        end
        opts.on("--kill NAME", "Kill the specified spoon instance") do |name|
          config[:kill] = name
        end

        config[:config] = "#{ENV['HOME']}/.spoonrc"
        opts.on("-c", "--config FILE", "Config file to use for spoon @options") do |c|
          config[:config] = c
        end

        opts.on("--builddir DIR", "Directory containing Dockerfile") do |b|
          config[:builddir] = b
        end

        opts.on("--url URL", "Docker url to connect to") do |url|
          config[:url] = url
        end

        opts.on("--list-images", "List available spoon images") do
          config["list-images"] = true
        end

        opts.on("--image NAME", "Use image for spoon instance") do |image|
          config[:image] = image
        end

        opts.on("--prefix PREFIX", "Prefix for container names") do |prefix|
          config[:prefix] = prefix
        end

        opts.on("--privileged", "Enable privileged mode for new containers") do |privileged|
          config[:privileged] = true
        end

        opts.on("--force", "Skip any confirmations") do
          config[:force] = true
        end

        opts.on("--nologin", "Do not ssh to contianer, just create") do
          config[:nologin] = true
        end

        opts.on("--debug", "Enable debug") do
          config[:debug] = true
        end

        opts.on("--debugssh", "Enable SSH debugging") do
          config[:debugssh] = true
        end

        opts.on("-p PORT", "--ports", Array, "Expose additional docker ports") do |ports|
          config[:ports] = ports
        end

        opts.on("-P PORT", "--portforwards", "Forward PORT over ssh (must be > 1023)") do |portforwards|
          config[:portforwards] = portforwards
        end

        opts.on("--version", "Show version") do
          puts Spoon::VERSION
          exit
        end

        opts.on("-h", "--help", "Show help") do
          puts opts
          exit
        end
      end

      begin
        optparser.parse!(ARGV)
      rescue OptionParser::MissingArgument, OptionParser::InvalidOption
        puts $!.to_s
        puts optparser
        exit(1)
      end
      config
    end

    def self.confirm_delete?(name)
      if @options[:force]
        return true
      else
        print "Are you sure you want to delete #{name}? (y/n) "
        answer = $stdin.gets.chomp.downcase
        return answer == "y"
      end
    end

    def self.apply_prefix(name)
      "#{@options[:prefix]}#{name}"
    end

    def self.remove_prefix(name)
      name.sub(/\/?#{@options[:prefix]}/, '')
    end

    def self.image_build
      # Run pre-build commands
      @options["pre-build-commands"].each do |command|
        sh command
      end unless @options["pre-build-commands"].nil?
      D "pre-build commands complete, building Docker image"

      docker_url
      build_opts = { 't' => @options[:image], 'rm' => true }
      docker_connection = ::Docker::Connection.new(@options[:url], :read_timeout => 3000)

      ::Docker::Image.build_from_dir(@options[:builddir], build_opts, docker_connection) do |chunk|
        print_docker_response(chunk)
      end
    end

    def self.image_list
      docker_url
      ::Docker::Image.all.each do |image|
        next if image.info["RepoTags"] == ["<none>:<none>"]
        puts "Image: #{image.info["RepoTags"]}"
      end
    end

    def self.print_parsed_response(response)
      case response
      when Hash
        response.each do |key, value|
          case key
          when 'stream'
            puts value
          else
            puts "#{key}: #{value}"
          end
        end
      when Array
        response.each do |hash|
          print_parsed_response(hash)
        end
      end
    end

    def self.print_docker_response(json)
      print_parsed_response(JSON.parse(json))
    end

    def self.instance_connect(name, command='')
      docker_url
      if not instance_exists? name
        puts "The '#{name}' container doesn't exist, creating..."
        instance_create(name)
        return if @options[:nologin]
        instance_copy_authorized_keys(name, @options[:add_authorized_keys])
        instance_copy_files(name)
        instance_run_actions(name)
      end

      container = get_container(name)
      unless is_running?(container)
        instance_start(container)
      end

      unless @options[:nologin]
        puts "Connecting to `#{name}`"
        instance_ssh(name, command)
      else
        puts "Instance exists but nologin specified"
      end
    end

    def self.instance_list
      docker_url
      puts "List of available spoon containers:"
      container_list = get_spoon_containers
      if container_list.empty?
        puts "No spoon containers running at #{@options[:url]}"
        exit
      end
      max_width_container_name = remove_prefix(container_list.max_by {|c| c.info["Names"].first.to_s.length }.info["Names"].first.to_s)
      max_name_width = max_width_container_name.length
      container_list.each do |container|
        name = container.info["Names"].first.to_s
        running = is_running?(container) ? Rainbow("Running").green : Rainbow("Stopped").red
        puts "#{remove_prefix(name)} [ #{running} ]".rjust(max_name_width + 22) + " " + Rainbow(image_name(container)).yellow
      end
    end

    def self.image_name(container)
      env = Hash[container.json['Config']['Env'].collect { |v| v.split('=') }]
      return env['IMAGE_NAME'] || container.json['Config']['Image']
    end

    def self.strip_slash(name)
      if name.start_with? "/"
        name[1..-1]
      else
        name
      end
    end

    def self.is_running?(container)
      if /^Up.+/ =~ container.info["Status"]
        return $~
      else
        return false
      end
    end

    def self.instance_network(name)
      docker_url

      container = get_container(name)

      if is_running?(container)
        host = URI.parse(@options[:url]).host
        puts "Host: #{host}"
        ports = container.json['NetworkSettings']['Ports']
        ports.each do |p_name, p_port|
          tcp_name = p_name.split('/')[0]
          puts "#{tcp_name} -> #{p_port.first['HostPort']}"
        end
      else
        puts "Container is not running, cannot show ports"
      end
    end

    def self.instance_destroy(name)
      docker_url
      container = get_container(name)

      if container
        if confirm_delete?(name)
          puts "Destroying #{name}"
          begin
            container.kill
          rescue
            puts "Failed to kill container #{container.id}"
          end

          container.wait(10)

          begin
            container.delete(:force => true)
          rescue
            puts "Failed to remove container #{container.id}"
          end
          puts "Done!"
        else
          puts "Delete aborted.. #{name} lives to pair another day."
        end
      else
        puts "No container named: #{name}"
      end
    end

    def self.instance_exists?(name)
      get_container(name)
    end

    def self.get_port_forwards(forwards = "")
      if @options[:portforwards]
        @options[:portforwards].split.each do |port|
          (lport,rport) = port.split(':')
          forwards << "-L #{lport}:127.0.0.1:#{rport || lport} "
        end
      end
      return forwards
    end

    def self.instance_ssh(name, command='', exec=true)
      container = get_container(name)
      forwards = get_port_forwards
      D "Got forwards: #{forwards}"
      host = URI.parse(@options[:url]).host
      if container
        ssh_command = "\"#{command}\"" if not command.empty?
        ssh_port = get_port('22', container)
        puts "Waiting for #{name}:#{ssh_port}..." until host_available?(host, ssh_port)
        ssh_options = "-t -o StrictHostKeyChecking=no -p #{ssh_port} #{forwards} "
        ssh_options << "-v " if @options[:debugssh]
        ssh_cmd = "ssh #{ssh_options} pairing@#{host} #{ssh_command}"
        D "SSH CMD: #{ssh_cmd}"
        if exec
          exec(ssh_cmd)
        else
          system(ssh_cmd)
        end
      else
        puts "No container named: #{container.inspect}"
      end
    end

    def self.instance_copy_authorized_keys(name, keyfile)
      D "Setting up authorized_keys file"
      # We sleep this once to cope w/ slow starting ssh daemon on create
      sleep 1
      if keyfile
        full_keyfile = "#{ENV['HOME']}/.ssh/#{keyfile}"
        key = File.read(full_keyfile).chop
        D "Read keyfile `#{full_keyfile}` with contents:\n#{key}"
        cmd = "mkdir -p .ssh ; chmod 700 .ssh ; echo '#{key}' >> .ssh/authorized_keys"
        instance_ssh(name, cmd, false)
      end
    end

    def self.instance_copy_files(name)
      @options[:copy_on_create].each do |file|
        D "Copying file #{file}"
        container = get_container(name)
        host = URI.parse(@options[:url]).host
        if container
          ssh_port = get_port('22', container)
          puts "Waiting for #{name}:#{ssh_port}..." until host_available?(host, ssh_port)
          system("scp -o StrictHostKeyChecking=no -P #{ssh_port} #{ENV['HOME']}/#{file} pairing@#{host}:#{file}")
        else
          puts "No container named: #{container.inspect}"
        end
      end
    end

    def self.instance_run_actions(name)
      @options[:run_on_create].each do |action|
        puts "Running command: #{action}"
        instance_ssh(name, action, false)
      end
    end

    def self.get_all_containers
      ::Docker::Container.all(:all => true)
    end

    def self.get_spoon_containers
      container_list = get_all_containers.select { |c| c.info["Names"].first.to_s.start_with? "/#{@options[:prefix]}" }
      unless container_list.empty?
        return container_list.sort { |c1, c2| c1.info["Names"].first.to_s <=> c2.info["Names"].first.to_s }
      else
        return container_list
      end
    end

    def self.get_running_containers
      ::Docker::Container.all
    end

    def self.instance_start(container)
      container.start!
    end

    def self.instance_restart(name)
      container = get_container(name)
      container.kill
      container.start!
      puts "Container #{name} restarted"
    end

    def self.instance_kill(name)
      container = get_container(name)
      container.kill
      puts "Container #{name} killed"
    end

    def self.get_container(name)
      docker_url
      container_list = get_all_containers

      l_name = strip_slash(name)
      container_list.each do |container|
        if container.info["Names"].first.to_s == "/#{l_name}"
          return container
        end
      end
      return nil
    end

    def self.container_config(name)
      data = {
        :Cmd => 'runit',
        :Image => @options[:image],
        :AttachStdout => true,
        :AttachStderr => true,
        :Privileged => @options[:privileged],
        :PublishAllPorts => true,
        :Tty => true
      }
      # Yes, this key must be a string
      data['name'] = name
      data[:CpuShares] = @options[:cpu] if @options[:cpu]
      data[:Dns] = @options[:dns] if @options[:dns]
      data[:Hostname] = remove_prefix(name)
      data[:Memory] = @options[:memory] if @options[:memory]
      ports = ['22'] + Array(@options[:ports]).map { |mapping| mapping.to_s }
      ports.compact!
      data[:PortSpecs] = ports
      data[:PortBindings] = ports.inject({}) do |bindings, mapping|
        guest_port, host_port = mapping.split(':').reverse
        bindings["#{guest_port}/tcp"] = [{
          :HostIp => '',
          :HostPort => host_port || ''
        }]
        bindings
      end
      data[:Volumes] = Hash[Array(@options[:volume]).map { |volume| [volume, {}] }]
      data
    end

    def self.instance_create(name)
      docker_url
      container = ::Docker::Container.create(container_config(name))
      container = container.start(container_config(name))
    end

    def self.host_available?(hostname, port)
      socket = TCPSocket.new(hostname, port)
      IO.select([socket], nil, nil, 5)
    rescue SocketError, Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
      sleep(0.25)
      false
    rescue Errno::EPERM, Errno::ETIMEDOUT
      false
    ensure
      socket && socket.close
    end

    def self.docker_url
      ::Docker.url = @options[:url]
    end

    def self.get_port(port, container)
      container.json['NetworkSettings']['Ports']["#{port}/tcp"].first['HostPort']
    end

    def self.D(message)
      if @options[:debug]
        puts "D: #{message}"
      end
    end

    main
  end
end
