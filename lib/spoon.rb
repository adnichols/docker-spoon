require "spoon/version"
require 'docker'
require 'json'
require 'uri'
require 'rainbow'

module Spoon
  include Methadone::Main
  include Methadone::CLILogging
  include Methadone::SH
  version(Spoon::VERSION)

  main do |instance|

    D options.inspect
    if options[:list]
      instance_list
    elsif options["list-images"]
      image_list
    elsif options[:build]
      image_build
    elsif options[:destroy]
      instance_destroy(apply_prefix(options[:destroy]))
    elsif options[:network]
      instance_network(apply_prefix(options[:network]))
    elsif instance
      instance_connect(apply_prefix(instance), options[:command])
    else
      help_now!("You either need to provide an action or an instance to connect to")
    end

  end

  description "Create & Connect to pairing environments in Docker"

  # Actions
  on("-l", "--list", "List available spoon instances")
  on("-d", "--destroy NAME", "Destroy spoon instance with NAME")
  on("-b", "--build", "Build image from Dockerfile using name passed to --image")
  on("-n", "--network NAME", "Display exposed ports using name passed to NAME")

  # Configurables
  options[:config] ||= "#{ENV['HOME']}/.spoonrc"
  on("-c FILE", "--config", "Config file to use for spoon options")

  # Read config file & set options
  if File.exists?(options[:config])
    eval(File.open(options[:config]).read)
  end

  options[:builddir] ||= '.'
  on("--builddir DIR", "Directory containing Dockerfile")
  on("--pre-build-commands", "List of commands to run locally before building image")
  # These are config only options
  options[:copy_on_create] ||= []
  options[:add_authorized_keys] ||= false
  options[:url] ||= Docker.url
  on("-u", "--url URL", "Docker url to connect to")
  on("-L", "--list-images", "List available spoon images")
  options[:image] ||= "spoon-pairing"
  on("-i", "--image NAME", "Use image for spoon instance")
  options[:prefix] ||= 'spoon-'
  on("-p", "--prefix PREFIX", "Prefix for container names")
  options[:command] ||= ''
  on("-f", "--force", "Skip any confirmations")
  on("--debug", "Enable debug")


  arg(:instance, :optional, "Spoon instance to connect to")

  use_log_level_option

  def self.confirm_delete?(name)
    if options[:force]
      return true
    else
      print "Are you sure you want to delete #{name}? (y/n) " 
      answer = $stdin.gets.chomp.downcase
      return answer == "y"
    end
  end

  def self.apply_prefix(name)
    "#{options[:prefix]}#{name}"
  end

  def self.remove_prefix(name)
    name.gsub(/\/?#{options[:prefix]}/, '')
  end

  def self.image_build
    # Run pre-build commands
    options["pre-build-commands"].each do |command|
      sh command
    end unless options["pre-build-commands"].nil?
    D "pre-build commands complete, building Docker image"

    docker_url
    build_opts = { 't' => options[:image], 'rm' => true }
    docker_connection = ::Docker::Connection.new(options[:url], :read_timeout => 3000)

    Docker::Image.build_from_dir(options[:builddir], build_opts, docker_connection) do |chunk|
      print_docker_response(chunk)
    end
  end

  def self.image_list
    docker_url
    Docker::Image.all.each do |image|
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
      puts "The `#{name}` container doesn't exist, creating..."
      instance_create(name)
      instance_copy_authorized_keys(name, options[:add_authorized_keys])
      instance_copy_files(name)
      instance_run_actions(name)
    end

    container = get_container(name)
    unless is_running?(container)
      instance_start(container)
    end

    puts "Connecting to `#{name}`"
    instance_ssh(name, command)
  end

  def self.instance_list
    docker_url
    puts "List of available spoon containers:"
    container_list = get_all_containers.select { |c| c.info["Names"].first.to_s.start_with? "/#{options[:prefix]}" }
      .sort { |c1, c2| c1.info["Names"].first.to_s <=> c2.info["Names"].first.to_s }
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
    return env['IMAGE_NAME'] || container.json['Config']['Image'].split(':').first
  end

  def self.strip_slash(name)
    if name.start_with? "/"
      name[1..-1]
    else
      name
    end
  end

  def self.is_running?(container)
    container = Docker::Container.get(container.info["id"])
    status = container.info["State"]["Running"] || nil
    unless status.nil?
      return status
    else
      return false
    end
  end

  def self.instance_network(name)
    docker_url

    container = get_container(name)

    if is_running?(container)
      host = URI.parse(options[:url]).host
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

  def self.instance_ssh(name, command='')
    container = get_container(name)
    host = URI.parse(options[:url]).host
    if container
      ssh_command = "\"#{command}\"" if not command.empty?
      ssh_port = get_port('22', container)
      puts "Waiting for #{name}:#{ssh_port}..." until host_available?(host, ssh_port)
      exec("ssh -t -o StrictHostKeyChecking=no -p #{ssh_port} pairing@#{host} #{ssh_command}")
    else
      puts "No container named: #{container.inspect}"
    end
  end

  def self.instance_copy_authorized_keys(name, keyfile)
    if keyfile
      container = get_container(name)
      host = URI.parse(options[:url]).host
      key = File.read("#{ENV['HOME']}/.ssh/#{keyfile}")
      if container
        ssh_port = get_port('22', container)
        puts "Waiting for #{name}:#{ssh_port}..." until host_available?(host, ssh_port)
        system("ssh -t -o StrictHostKeyChecking=no -p #{ssh_port} pairing@#{host} \"mkdir -p .ssh && chmod 700 .ssh && echo '#{key}' >> ~/.ssh/authorized_keys\"")
      else
        puts "No container named: #{container.inspect}"
      end
    end
  end

  def self.instance_copy_files(name)
    options[:copy_on_create].each do |file|
      puts "Copying file #{file}"
      container = get_container(name)
      host = URI.parse(options[:url]).host
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
    options[:run_on_create].each do |action|
      puts "Running command: #{action}"
      container = get_container(name)
      host = URI.parse(options[:url]).host
      if container
        ssh_port = get_port('22', container)
        puts "Waiting for #{name}:#{ssh_port}..." until host_available?(host, ssh_port)
        system("ssh -o StrictHostKeyChecking=no -p #{ssh_port} pairing@#{host} #{action}")
      else
        puts "No container named: #{container.inspect}"
      end
    end
  end

  def self.get_all_containers
    Docker::Container.all(:all => true)
  end

  def self.get_running_containers
    Docker::Container.all
  end

  def self.instance_start(container)
    container.start!
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

  def self.instance_create(name)
    docker_url
    container = Docker::Container.create({
      'Image' => options[:image],
      'name' => name,
      'Entrypoint' => 'runit',
      'Hostname' => remove_prefix(name)
    })
    container = container.start({ 'PublishAllPorts' => true })
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
    Docker.url = options[:url]
  end

  def self.get_port(port, container)
    container.json['NetworkSettings']['Ports']["#{port}/tcp"].first['HostPort']
  end

  def self.D(message)
    if options[:debug]
      puts "D: #{message}"
    end
  end

  go!
end
