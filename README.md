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


## Getting Started
These are the basics of how to get started. When you want to get into
more detail see the [full usage](#full-usage) documentation.

### Installation

```
$ gem install docker-spoon
```
(NOTE: if installing on Ubuntu this requires the installation of ruby-dev)

### Configuration

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

The spoon configuration is described in more detail in the [spoon config
page](README_config.md)

### Building a compatible image

The spoon repository contains a functional spoon image. To build that just follow these steps:

```
git clone git@github.com:adnichols/docker-spoon.git
cd docker-spoon/docker
spoon -b
```

This creates an image that matches the default image name for spoon. If
you specify a different image name in the configuration then that will
be used when spoon builds an image.

## Full Usage

Spoon has a number of operations it can perform:

- [Create and Connect](#create-and-connect) to containers
- [List](#list) existing containers
- [List Images](#list-images) on the Docker host
- [Network](#network) to show a containers network configuration
- [Destroy](#destroy) a container
- [Kill](#kill) containers
- [Restart](#restart) containers
- [Build](#build) an image from a Dockerfile for use with spoon

In addition to these operations there are configuration values which are
supported on the command line or in the configuration file. See [Command
Line Options](#command-line-options) for a list of tunables

### Create and Connect

By default when you call spoon with no options it will try to connect to
the spoon container that you specify. If that container doesn't exist,
spoon will create it for you. Once spoon either creates a container or
determines that one already exists it will start an ssh connection to
the host. This will shell out to ssh and should honor your ssh
configuration locally.

Example (container doesn't exist):
```
$ spoon fortesting
The `spoon-fortesting` container doesn't exist, creating...
Connecting to `spoon-fortesting`
pairing@dockerhost's password:
```

Example (container exists):
```
$ spoon fortesting
Connecting to `spoon-fortesting`
pairing@dockerhost's password:
```

NOTE: If a container has been stopped or killed, spoon will issue a
start to the container & then attempt to ssh in.

### List

The `--list` argument will list any containers on the destination Docker
host which have the same prefix as specified by `--prefix` (default
'spoon-'). Images are listed without the prefix specified so that you
can see only the containers you are interested in.

```shell
$ spoon -l
List of available spoon containers:
                      booger [ Stopped ]
                        jake [ Running ]
                        test [ Stopped ]
```

You can connect to Stopped containers in the same way as Running
containers, spoon will re-start them as necessary.

### List Images

The `--list-images` argument is conventient for listing the images available
on the server. The image names should be exactly what you would use in the 
`options[:image]` configuration value.

```
$ spoon --list-images
Image: ["spoon_test:latest"]
```

To use this image you would set `options[:image] = 'spoon_test'`

### Network

The `--network NAME` option will show the forwarded ports for a spoon
instance. Any ports listed via `EXPOSE` in your Dockerfile should be
exposed when a spoon container is started. If you are working with
applications in a spoon container you can use this to forward ports &
view what public ports are forwarded for your spoon container.

```
$ spoon -n jake
22 -> 49213
```

### Destroy

The `--destroy NAME` option will destroy the specified spoon container.

```shell
$ spoon -d fortesting
Are you sure you want to destroy spoon-fortesting? (y/n) y
Destroying spoon-fortesting
Done!
```

The `--force` option may be used to avoid the confirmation prompt

To skip any confirmations:

  * add `-f` or `--force` to the command-line
  * add `options[:force] = true` to your `.spoonrc`.

### Kill

The `--kill NAME` option will kill a spoon container without destroying
it. This is useful if you want to leave a container around but not in
use for a period of time. Containers may be started again simply by
connecting to them.

### Restart

The `--restart NAME` option will kill and then start a container. This
is useful if you have a container which has gotten into a bad state or
where you've started processes you simply want to easily kill off. 

### Build

The `--build` option will build a docker image from the build directory
specified by `--builddir` (default '.'). This has the same expectations
as the [docker
build](https://docs.docker.com/reference/commandline/cli/#build)
command.

## Command Line Options

The following options may be specified either on the command line or in
the spoon [configuration file](README_config.md). Note that command line
options take precedence over options in the configuration file. 

- `--builddir`, This is the directory where the build process will look
  for a Dockerfile and any content added to the container using `ADD`.
- `--config`, configuration file to read, defaults to `~/.spoonrc`
- `--image`, The image name to use when starting a spoon container.
- `--portforwards`, This is a comma separated list of ports to forward
  over ssh. The format is either `sourceport:destport` or  just
  `sourceport` in which case the same port will be used for source &
  destination.  This may be used after container creation to add ports
  ad-hoc
- `--ports`, Comma separated list of ports to expose upon container
  creation by Docker. Unlike `--portforwards` this is only available at
	container creation
- `--prefix`, The prefix to use for creating, listing & destroying
  containers.
- `--privileged`, Starts a new container in with Privileged mode true,
  only applicable on container creation.
- `--url`, The url of the Docker API endpoint. This is in the format
  supported by the docker -H option. This will also read from the
environment variable `DOCKER_HOST` if this argument is not specified and
that env var exists.
- `--nologin`, This option is used for testing. It performs all actions
  up to the point of executing an ssh connection and then returns.
- `--debug`, Enables some debugging
- `--debugssh`, Enables SSH debugging
- `--version`, Shows the version

These options and others are described in greater detail in the [configuration
file](README_config.md) documentation.

#### Container expectations

When building an image for use with docker-spoon you must build an
image which runs an ssh daemon. An example of a Dockerfile which
creates an image which runs ssh is included in the `docker/`
directory inside this repository

## Contributing

1. Fork it ( https://github.com/adnichols/docker-spoon/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Make your changes, add tests and make sure all tests pass (`rake`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

