I'm getting a load error when requiring my `lib/somefile`.
I'm not sure if I'm missing something or doing something wrong.

**System specs:**
  OS:
    Ubuntu 14.04 x64
    3.13.0-27-generic

  Java:
    java version "1.7.0_76"
    Java(TM) SE Runtime Environment (build 1.7.0_76-b13)
    Java HotSpot(TM) 64-Bit Server VM (build 24.76-b04, mixed mode)

  rbenv:
    rbenv 0.4.0-129-g7e0e85b

  jruby:
    jruby 1.7.18 (1.9.3p551) 2014-12-22 625381c on Java HotSpot(TM) 64-Bit Server VM 1.7.0_76-b13 +jit [linux-amd64]

**Background:**
  I'm creating a jruby app on ubuntu and running it on Windows 7.
  When I run the app, the lib require (in `bin/mytestapp`) fails with

    LoadError: no such file to load -- mytestapp

This happens on both Java 7 and 8 runtimes.


I'm using the following require statement in `bin/mytestapp`

```ruby
    begin
      require 'mytestapp'
    rescue LoadError
      $LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
      puts 'LOAD_PATH:'
      $LOAD_PATH.each do |p|
        puts "  #{p}"
      end
      require 'mytestapp'
    end
```

I run the app on the build machine (linux) with

    java -jar build/mytestapp.jar mytestapp

I see the following output:

    LOAD_PATH:
      classpath:/META-INF/app.home/lib
      file:/home/jeff/projects/ruby/mytestapp/build/mytestapp.jar!/META-INF/jruby.home/lib/ruby/1.9/site_ruby
      file:/home/jeff/projects/ruby/mytestapp/build/mytestapp.jar!/META-INF/jruby.home/lib/ruby/shared
      file:/home/jeff/projects/ruby/mytestapp/build/mytestapp.jar!/META-INF/jruby.home/lib/ruby/1.9
      classpath:META-INF/gem.home/rake-10.1.0/lib
      classpath:META-INF/gem.home/builder-3.2.2/lib
      classpath:META-INF/gem.home/dbd-jdbc-0.1.6-java/lib
      classpath:META-INF/gem.home/deprecated-2.0.1/lib
      ...
      classpath:META-INF/gem.home/xml-simple-1.1.2/lib
      classpath:META-INF/gem.home/user-choices-1.1.6.1/lib

The app runs as expected (no errors) but note the first listing:

    classpath:/META-INF/app.home/lib

compared to the first `gem.home` listing:

    classpath:META-INF/gem.home/rake-10.1.0/lib

the `gem.home` listing doesn't contain a leading slash.


When I run the app on windows, I see the following:

    C:\Apps\MyTestApp>java -jar mytestapp.jar mytestapp
    LOAD_PATH:
      classpath:C:/META-INF/app.home/lib
      file:/C:/Apps/MyTestApp/mytestapp.jar!/META-INF/jruby.home/lib/ruby/1.9/site_ruby
      file:/C:/Apps/MyTestApp/mytestapp.jar!/META-INF/jruby.home/lib/ruby/shared
      file:/C:/Apps/MyTestApp/mytestapp.jar!/META-INF/jruby.home/lib/ruby/1.9
      classpath:META-INF/gem.home/rake-10.1.0/lib
      classpath:META-INF/gem.home/builder-3.2.2/lib
      classpath:META-INF/gem.home/dbd-jdbc-0.1.6-java/lib
      classpath:META-INF/gem.home/deprecated-2.0.1/lib
      ...
      classpath:META-INF/gem.home/xml-simple-1.1.2/lib
      classpath:META-INF/gem.home/user-choices-1.1.6.1/lib
    LoadError: no such file to load -- mytestapp
      require at org/jruby/RubyKernel.java:1071
      require at /C:/Apps/MyTestApp/mytestapp.jar!/META-INF/jruby.home/lib/ruby/shared/rubygems/core_ext/kernel_require.rb:55
      (root) at classpath:/META-INF/app.home/bin/mytestapp:20
        load at org/jruby/RubyKernel.java:1087
      (root) at classpath:jar-bootstrap.rb:50
        each at org/jruby/RubyArray.java:1613
      (root) at classpath:jar-bootstrap.rb:46

Now the `app.home` path is prefixed with `C:/`:

    classpath:C:/META-INF/app.home/lib

and it fails, as you can see.

**Question:** Why is the classpath prefixed with a file path? Shouldn't it just
be `META-INF/whatever`?


During my testing, I modified `puck/lib/puck/jar.rb#create_jar_bootstrap!` to
add the `lib` dir to the `LOAD_PATH` (line 148):

```ruby
    def create_jar_bootstrap!(tmp_dir, gem_dependencies)
      File.open(File.join(tmp_dir, 'jar-bootstrap.rb'), 'w') do |io|
        io.puts(%(PUCK_BIN_PATH = ['/#{JAR_APP_HOME}/bin', '/#{JAR_JRUBY_HOME}/bin']))
        gem_dependencies.each do |spec|
          io.puts("PUCK_BIN_PATH << '/#{JAR_GEM_HOME}/#{spec[:versioned_name]}/#{spec[:bin_path]}'")
        end
        io.puts

        #
        # Add JAR_APP_HOME/lib to LOAD_PATH
        #
        io.puts(%($LOAD_PATH << 'classpath:#{JAR_APP_HOME}/lib'))

        gem_dependencies.each do |spec|
          spec[:load_paths].each do |load_path|
            io.puts(%($LOAD_PATH << 'classpath:#{JAR_GEM_HOME}/#{spec[:versioned_name]}/#{load_path}'))
          end
        end
        io.puts
        io.puts(File.read(File.expand_path('../bootstrap.rb', __FILE__)))
      end
    end
```

My app now works in both systems, and I don't have to add the `lib` dir to the
`LOAD_PATH` in `bin/mytestapp`. I can just do:

    require 'mytestapp'

**Question:** Is there a reason to NOT add the `lib` dir to the `LOAD_PATH` within `create_jar_bootstrap`?
Will bad things happen?

**Question:** Maybe it would be better to make this a configuration option?

If I'm just losing it, please point me in the right direction.

Other than this issue, puck is working out great!

