# docker-spoon

## Configuration

All spoon options available on the command line may be specified in the
configuration file as well. For action type options it doesn't make much
sense to place them in the config file, but for many other options it
does. Further, there are some configurations which are only available as
configuration file options to keep the cli options cleaner.

The spoon configuration file is evaled as ruby so you can do all the
things you could normally do in a ruby program. Abuse with caution.

The precedence of options, from most to least preferred are:
- Command line options
- Configuration file options
- Default options

The exception to this is the `--config` option, which is completely
ignored inside the configuration file.

Here is an example of a simple .spoonrc:
```ruby
options[:url] = "tcp://192.168.1.3:4243"
options[:image] = 'spoon-pairing'
```

All of the `options[]` parameters should map directly to the long form
of options on the command line. They are all expected to be presented as
symbols. The limitation is that ruby doesn't permit a dash in symbols,
so when an option has a dash in it, it must be specified as a string.

You may also specify a different config file with the `--config`
argument.

### Options

#### url
Forms: `--url`, `options[:url]`
Default: `ENV['DOCKER_HOST']`

The url of the Docker API endpoint. This is in the format supported by
the docker -H option. If this option is not specified in either the
config or the command line then spoon will rely upon the value of
`DOCKER_HOST`.

#### image
Forms:
- `--image IMAGE`
- `options[:image] = "image"`
Default: `spoon-pairing`

The image name to use when starting a new spoon container. Note that
despite both default `--prefix` and `--image` beginning with `spoon-`
the two options are unrelated.

#### prefix
Forms:
- `--prefix PREFIX`
- `options[:prefix] = "prefix"`
Default: `spoon-`

The prefix to use for naming containers. Container names are central to
the way spoon works so that developers may choose simple names that are
easy to remember for their containers. The prefix allows different
groups to use different prefixes to lower the risk of name collisions.

#### portforwards
Forms: 
- `--portforwards PORT[:PORT][,PORT]`
- `options[:portforwards] = [ "1234", "1234:4321" ]`
Default: none

Sometimes you are developing in a spoon container and need to expose a
new port without destroying the container & starting over. This option
enables this by using ssh port forwarding. 

This is a comma separated list of ports to forward over ssh. The format
is either `sourceport:destport` or  just `sourceport` in which case the
same port will be used for source & destination.  Multiple port forwards
may be separated by commas, for exampe `--portforwards '8080,8081:9090'`

#### ports
Forms:
- `--ports PORT[:PORT][,PORT]`
- `options[:ports] = [ "1234", "1234:4321" ] `
Default: none

#### builddir
Forms:
- `--builddir DIRECTORY`
- `options[:builddir] = "directory"`
Default: `.`

This is the directory where the build process will look for a Dockerfile
and any content added to the container using `ADD`. The directory name
is relative to the directory from which spoon is being called - not the
directory in which the spoon executable resides.

#### pre-build-commands
Forms:
- `options[:"pre-build-commands"] = [ 'cmd1', 'cmd2' ]`
Default: none

This is a list of commands to run before actually kicking off the build
process.

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

NOTE: This option is NOT in symbol form like all others - a legacy issue
I need to get around to fixing and deprecating this format.

#### copy_on_create
Forms:
- `options[:copy_on_create] = [ '/tmp/somefile', '/home/user/somefile' ]`
Default: none

This command will copy the list of specified files into the destionation
container upon container creation. These will be copied from the source
system relative to your home directory and placed in the destination
container at the same location (relative to your home directory). 

This is handy for adding any custom configurations you require which you
may not want to bake into your Docker image. 

Example:
```
options[:copy_on_create] = [
  ".gitconfig",
  ".ssh/config"
]
```
NOTE: this does not create any required parent directories on the
destination system unless they are copied into place, for example like
the .ssh directory in the example above.

#### add_authorized_keys
Forms:
- `options[:add_authorized_keys] = "id_rsa.pub"`
Default: none

This allows you to specify an ssh public key that should reside in your
own `~/.ssh` directory to be placed in authorized_keys on the
destination system upon container creation. It copies the filename
specified out of your local `~/.ssh` directory into
`~/.ssh/authorized_keys` on the spoon container so that public key auth
works.

NOTE: This option WILL create a `~/.ssh` directory on the spoon
container if it doesn't already exist.

#### run_on_create
Forms:
- `options[:run_on_create] = [ 'cmd1', 'cmd2' ]`

This is a list of commands to run on a spoon container once it has been
started. This allows you to quickly and automatically modify a spoon
environment upon creation to meet any needs you have which aren't baked
into the Docker image. Commands are run one at a time over ssh - enabling
:add_authorized_keys makes this option more tolerable.

Example:
```
options[:run_on_create] = [ "sudo apt-get -y install emacs" ]
```
