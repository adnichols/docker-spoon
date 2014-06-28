# docker-spoon

## Overview
Spoon creates on demand pairing environments using Docker. 

We pair a lot using tmux & emacs / vim and wanted a way to create
pairing environments which met a few criteria:

- Would contain all the updates folks have contributed to the dev setup
- Can be created on-demand as needed instead of having dedicated pairing
  environments and asking who's using what
- Are console based to enable low latency remote pairing

Spoon is intended to make this process as easy as possible. 

#### Why Spoon?
[Learn more about spooning](https://www.youtube.com/watch?v=dYBjVTMUQY0)

## Installation

```
$ gem install docker-spoon
```

## Configuration

Spoon has a number of options which you probably do not want to have to
specify on the command line every time. The easiest way to set these for
your environment is to add them to `~/.spoonrc`. This file is just
parsed as ruby, so you can put all kinds of stuff in here, but the
basics should look something like this:

```ruby
options[:url] = "tcp://192.168.1.3:4243"
options[:image] = 'spoon-pairing'
options["pre-build-commands"] = [
  "cp -rp #{ENV['HOME']}/.chef #{options[:builddir]}/chef"
]
```

All of the `options[]` parameters should map directly to the long form
of options on the command line. They may be defined as either the
`:symbol` form or as a string. The limitation is that ruby doesn't
permit a dash in symbols, so when an option has a dash in it, it must be
specified as a string. 

You may also specify a different config file with the `--config`
argument. 

## Usage

Spoon has 4 major operations it can perform:

- Connect/Create, Connect to an existing spoon container or create a new
  container
- List, List existing containers
- Build, Build an image for use as a spoon container
- Destroy, Destroy an existing spoon container

### Connect/Create

By default when you call spoon with no options it will try to connect to
the spoon container that you specify. If that container doesn't exist,
spoon will create it for you. Once spoon either creates a container or
determines that one already exists it will start an ssh connection to
the host. This will shell out to ssh and should honor your ssh
configuration locally. 

Example (container doesn't exist):
```shell
$ spoon fortesting
The `spoon-fortesting` container doesn't exist, creating...
Connecting to `spoon-fortesting`
pairing@dockerhost's password:
```

Example (container exists):
```shell
$ spoon fortesting
Connecting to `spoon-fortesting`
pairing@dockerhost's password:
```

#### Options

- `--url`, The url of the Docker API endpoint. This is in the format
  supported by the docker -H option. This will also read from the
  environment variable `DOCKER_HOST` if this argument is not specified
  and that env var exists. 
- `--image`, The image name to use when starting a spoon container.
- `--prefix`, The prefix to use for creating, listing & destroying
  containers.

### List

The `--list` argument will list any containers on the destination Docker
host which have the same prefix as specified by `--prefix` (default
'spoon-'). Images are listed without the prefix specified so that you
can see only the containers you are interested in. 

```shell
$ spoon -l
List of available spoon containers:
fortesting
```

### Destroy

The `--destroy NAME` option will destroy the specified spoon container. 

```shell
$ spoon -d fortesting
Destroying spoon-fortesting
Done!
```

### Build

The `--build` option will build a docker image from the build directory
specified by `--builddir` (default '.'). This has the same expectations
as the [docker
build](https://docs.docker.com/reference/commandline/cli/#build)
command. 

#### Options

- `--builddir`, This is the directory where the build process will look
  for a Dockerfile and any content added to the container using `ADD`. 

- `--pre-build-commands`, This is a list of commands to run before
  actually kicking off the build process (see below).

pre-build-commands:

Because docker-spoon is special, we also support running some
commands in advance of the build process. This allows for things like
copying stuff into the container which you don't want to have committed
to the repository. An example of this is that in our environment we need
chef credentials inside of our container & we use this mechanism to copy
those credentials into the builddir at build time without adding them to
our repository containing the Dockerfile. 

Here's an example of how we copy our chef configuration into place:
```ruby
options["pre-build-commands"] = [
  "cp -rp #{ENV['HOME']}/.chef #{options[:builddir]}/chef"
]
```

#### Container expectations

When building a container for use with docker-spoon you must build a
container which runs an ssh daemon. An example of a Dockerfile which
creates a container which runs ssh is included in the `docker/`
directory inside this repository

## Contributing

1. Fork it ( https://github.com/adnichols/spoon/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

