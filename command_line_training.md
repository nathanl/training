# Understanding The Command Line

You've been using the command line for a while, but maybe just at a basic level - `cd`, `ls`, etc.
It's taken me years to understand what I'm really doing when I type those commands (and I still have much to learn).
Let me fill in some of the gaps for you and show you some of the powerful things you can do when you fire up your terminal.
But before that...

## What's a Terminal?

I used to say "terminal" or "shell" interchangeably, but they're not the same thing.
We generally open a terminal program and run a shell in it, but a terminal can display any [text-based user interface](https://en.wikipedia.org/wiki/Text-based_user_interface).
If you think about it, that's what editors like [Vim](https://en.wikipedia.org/wiki/Vim_%28text_editor%29) and [Nano](https://en.wikipedia.org/wiki/GNU_nano) have: a visual interface drawn with characters instead of pixels.

Terminal programs, like [Terminal](https://en.wikipedia.org/wiki/Terminal_(OS_X)) or [iTerm2](https://en.wikipedia.org/wiki/ITerm2) or [GNOME Terminal](https://en.wikipedia.org/wiki/GNOME_Terminal), handle things like color and cursor position, letting you scroll back through command output history, etc.

But the key thing is that terminals are for text-only interfaces.
In a shell, we type text commands and get text output, so that's a perfect thing to do in a terminal.

## Processes and PIDS

Another thing I didn't initially understand is that when I'm typing in a shell, that shell is a **process** being run by the operating system.
In a Unix-like system, every running program is a process, and a shell is no exception.

Knowing a few things about processes will come in really handy.

Every process has a process ID (PID).
You can see the shell's PID using `echo $$`.

When you're at the shell, you can use `ps` to see a list of processes controlled by a shell process.

In one shell, run `echo $$`, then `ruby -e "(1..100).each {|i| puts i; sleep 1}"`.
In another shell, run `ps -f`.
This will list processes, each with its pid and its parent pid - the id of the process that started it.
You'll see your Ruby program running.
Notice that it has a PID, and that it's PPID is the same as the PID of the shell where you started it.

You can ask the ruby program to shut down by running `kill` followed by its PID - eg, `kill 1234`.
The command `kill` sounds super harsh, but the name is kind of a historic relic.
It really should be called `signal`.
By default, it sends a signal called `TERM`, which means "would you please kindly shut down?"
The process is expected to gracefully finish what it's doing.
`kill -KILL [pid]` is a special case in that the program itself doesn't get the signal; it's interpreted more like "operating system, DESTROY THIS PROCESS!". Every signal is actually an integer and the names are historic and arcane, but a particular program can mostly decide how to interpret them.
`kill -l` will list them all.
[Nginx has some interesting signal responses](http://nginx.org/en/docs/control.html) - eg, `kill -HUP` tells it to reload its configuration.  

## STDIN, STDOUT, STDERR, and redirecting

Every process gets three "file descriptors": standard in, standard out, and standard error.

### Standard Input

Standard in can be the keyboard: `wc -l` by itself will wait for you to type and press `control + d` to indicate the end of the "file", then it will count the lines you typed.
Standard in can also come from another process: in `cat somefile | wc -l`, `wc -l` gets its standard in from the standard out of `cat`.

### Standard Output

Standard out will go to the screen by the default: `cat somefile` will show the contents on the screen.
Standard out can also go to another process: in `cat somefile | wc -l`, standard out from `cat` is piped to `wc -l`.

### Standard Error

Standard error is exactly like standard out, but for "other" messages, ones you wouldn't want piped to another program.
Eg, if you do `curl -v somesite.com`, the site's HTML will go to standard out, and "metadata" like "connected to this IP on this port" and "got these headers" will go to standard error.
In this example, both of those print on the screen, so they're indistinguishable. To see the difference, you have to redirect one or both of them.

### Redirecting

You can capture a program's standard output to a file with `>` or `>>`.
Either `>` or `>>` will create the file if it doesn't exist. If it does exist, `>` will overwrite the contents, whereas `>>` will append to it. 
`2>` tells what to do with a command's standard error ("file descriptor 2"; where "1" is stdout).
Some examples:

    # HTML goes to the file, headers and messages print to screen
    curl -v nathanmlong.com > nathanmlong_index.html

    # append the html to this file
    curl -v nathanmlong.com >> web_pages.html

    # put HTML and metadata in separate files
    curl -v nathanmlong.com > web_page.html 2> metadata.txt

    # put stdout and stderr in the same file
    curl -v nathanmlong.com > somefile 2>&1

    # same thing; `1>` is the same as `>`
    curl -v nathanmlong.com 1> somefile 2>&1

You can also use `<` to mean "read from this source"; `sort < somefile.txt` takes `somefile.txt` as input for `sort`.

## Pipes!!

Pipes are awesome! They can be thought of as simply a way to string commands together to make bigger commands. We've seen a couple of small examples already, but I want you to see their true power.

    echo "hello\nthere\nfaithful\nfriend" # outputs several lines
    echo "hello\nthere\nfaithful\nfriend" | grep 'e'
    echo "hello\nthere\nfaithful\nfriend" | grep -v 'e'
    echo "hello\nthere\nfaithful\nfriend" | grep -v 'e' | cut -c 3-8

You could use a similar pipeline to find all the Rails log entries that contain the request parameters and snip out just those params.

Here's a more complex example to answer the question: what's the longest word in the dictionary that contains the word "purple"?
 
    # purple_finder.sh
    # Read in the system's dictionary.
    cat /usr/share/dict/words |

    # Find words containing 'purple'
    grep purple |                   

    # Count the letters in each word
    awk '{print length($1), $1}' |

    # Sort lines ("${length} ${word}")
    sort -n |                       

    # Take the last line of the input
    tail -n 1 |                     

    # Take the second part of the line
    cut -d " " -f 2 |               

    # Output the results
    # (this is just here so that any of the lines
    # above can be commented out)
    cat                             

Paste that into `example.sh` and do `zsh example.sh` and you'll find out!

This runs really fast!
There are 236k words in that dictionary (which I learned by running `wc -l /usr/share/dict/words`, and we get our answer in about a tenth of a second (which I learned by running `time zsh example.sh`.
Let's make it slower so we can see what's happening.

    # slow_purple_finder.sh
    # Read in the system's dictionary.
    cat /usr/share/dict/words |     

    # Add some slowness to this whole process
    ruby -e 'while l = STDIN.gets do; STDOUT.puts(l); sleep 0.00001; STDOUT.flush; end' |

    # Find words containing 'purple'
    grep purple |                   

    # Count the letters in each word
    awk '{print length($1), $1}' |

    # Sort lines ("${length} ${word}")
    sort -n |                       

    # Take the last line of the input
    tail -n 1 |                     

    # Take the second part of the line
    cut -d " " -f 2 |               

    # Output the results
    # (this is just here so that any of the lines
    # above can be commented out)
    cat                             

Now before you run that, in another terminal, run `watch -n 0.25 ps -f -o rss`.
That means "every quarter second, rerun this `ps` command that shows processes and their memory usage".
While that's running, do `ps -f` in another terminal.
See that `awk`, `cut`, etc are all their own processes?
Input is passed from one to another like an assembly line with all workers working at the same time.
That fact is what makes the whole thing really fast and efficient.
It's fast because each process may be running on a different CPU core, so if you have 4 cores, it can complete 4 times as fast as if it were done sequentially.
It's memory efficient, too, because (eg) while `cat` is pulling lines of the file off the disk, `grep` is deciding whether to send each one along; none of them every have to hold the entire dictionary in memory at one time.
It's like drinking water through a straw; whether you drink an ounce or a gallon, the straw probably never contains more than ??????? 
The shell keeps an "inbox" for each process, called its "standard input", and if it gets too full, it makes the process that's writing to it pause for a bit; this also limits memory usage.

Because these run in parallel, you can use them for ongoing output.
Eg, to see lines that appear in your log file in real time, but only if they contain "DEBUG", do `tail -f logfile | grep "DEBUG"`, and make sure all your debugging messages contain that string.
If these didn't run in parallel, you'd have to stop the `tail` process so that `grep` could get the output and filter out what you want, but since they're parallel, you can get results in real time.

For lots more about pipelines, see [this awesome blog post](http://blog.petersobot.com/pipes-and-filters)

## Essential commands

General-purpose:

- **less**:
  - `less some_huge_file` lets you scroll and search in it without loading the whole thing into memory

Especially good for pipeline construction:

- **head**:
  - `head somefile` shows the first few lines of it (imagine a massive logfile)
  - `head -4 somefile` shows the first 4 lines
- **tail**:
  - `tail somefile` shows the last few lines of it (imagine a massive logfile)
  - `tail -4 somefile` shows the last 4 lines
  - `tail -f somefile` continually outputs as the file is appended (eg a logfile)
- **grep**:
  - `cat somefile | grep somestring` outputs only matching lines
  - `tail -f development.log | grep somestring` outputs only matching lines
- **sort**:
  - `cat somefile | sort` sorts the lines and outputs them. Flags control what kind of sorting (alphabetic, numeric, etc)
- **uniq**:
  - `cat somefile | sort | uniq` throws away repeated lines (sorting is required)
- **cut**:
  - `cat somefile | head -2 | cut -c 1-20` gives first 20 chars of first 2 lines
- **sed**:
  - `cat somefile | sed 's/pickle/bear/'` # change all pickles to bears

`sed` can do a ton more stuff, and `awk` can also do a ton of stuff - they are actually their own programming languages! But if you know Ruby, you can use it instead:

    When running `ruby`::
      - `-e` means "execute this snippet of code instead of a file"
      - `n` means "run once for every line of STDIN"
      - `p` means "print every line of STDIN (possibly after mutating it)"

    # outputs even numbers from 1 to 10
    seq 1 10 | ruby -ne 'puts $_ if $_.to_i % 2 == 0'

    # outputs "HI" and "THERE" (must mutate $_ to see)
    echo "hi\nthere" | ruby -pe '$_.upcase!'

## Environment variables

Environment variables can be set like `GREET=hi` and read like `echo $GREET`.
Any child process gets a copy of any of its parent's environment variables that have been `export`ed - eg, `export GREET=hi`, then run `ruby -e 'puts ENV["GREET"]'`.
Note that a child process gets a **copy** of its parents environment variables; it can modify its copy, but not its parent's copy.

`$PWD` is the "present working directory".

`$PATH` is a very important environment variable.  
Every command runs a process - eg `ls` runs the program found at `which ls`, which is the first place in `$PATH` that it finds a file named `ls` whose file permissions include execution.

`$PATH` controls where the shell looks for programs. `PATH=""` will break your shell, but you can just exit that shell.
You can add your own script directories to `PATH`, like I did with `~/.dotfiles/scripts/md_preview`.

See [my blog post on environment variables](http://nathanmlong.com/2014/02/understanding-unix-environment-variables/ ) and [this one from honeybadger](http://blog.honeybadger.io/ruby-guide-environment-variables/) for more details.

## Expansions

Bash does several passes through your command before running it.

= `ls ~/foo` or `ls ./foo`- directory expansion
- `echo $(whomai)` - command substitution
- `echo $TERM` - environment variable substitution
- `ls *.txt` - glob expansion - turns into (eg) `ls foo.txt bar.txt ...` - `ls "*.txt"` makes that one argument
- `touch foo{1,2,3}.txt` - brace expansion
- `alias g="git"; g status` - alias expansion

All of these happen before running it, so you can stick `echo` in front to see what they do; after the expansion it just finds `echo` with some arguments and runs it.

     # expands to  `echo touch foo1.txt foo2.txt foo2.txt`
    echo touch foo{1,2,3}.txt

    # expands to  `echo rm foo.txt foo.rb` (if those exist)
    echo rm foo.*

If you do `set -x`, it will show you these expansions as it runs them. `set +x` turns it off.

One related trick: `<(some_command)` lets you treat the output of that command as a file (the OS makes a temporary file). So `diff <(grep '=' file1) <(grep '=' file2)` will compare these two files, but only the lines that contain `=`.

## Adding your own commands

You can add your own commands to your command line in one of several ways.

### Functions and Aliases

You can write your own shell functions:

    # Define a word
    function define() { curl dict://dict.org/d:$1 }
    define boat # prints a dictionary definition

And alias existing commands:

    alias g="git" # yay for less typing!
    alias ls="ls -G" # colorize output and mark executables with *

If you want aliases and functions to persist forever, put them in your shell's
config file (eg, `~/.bashrc` or `~/.zshconfig`).  The config file is run every time you start a shell, as if you typed its contents yourself.

### Executable programs somewhere in $PATH

If you save this as `timestamp` in a folder on your `$PATH`:
    
    #!/usr/bin/env ruby
    # This program is dumb because `date` is already a command...
    require "date"
    puts Date

...then you `chmod +x timestamp` to make that file executable, you'll be able to run `timestamp` from the command line.
(If `timestamp` was in your current working directory but not on your `$PATH`, you'd have to say `./timestamp` to help the shell find it.)

## Exit Statuses

Every program exits with either `0` (meaning success) or `1` (meaning failure). `&& foo` means "run foo if the last command was successful", and `|| bar` means "run bar if the last command failed."

So this:

    rspec spec && say "success" || say "failure"

...tells audibly you whether your tests passed (on a Mac, which has the `say` command). (This works because `rspec` correctly sets its exit status.)

You can also check the last exit status in a subsequent command; it's available as `$?`.

## Other programming constructs

Bash/zsh are full programming languages, so you can do looping, conditionals, etc, if you want.

- `for i in apple banana cake; do touch $i.txt; done`
- `for i in $(ls *.txt); do
    echo "This is a text file: $i"
   done`
- `for i in $(seq 10); do echo "I'm counting to 10 like: $i"; done`

You can look up more if you want. :)

## Using the command line from Vim

One of my favorite Vim tricks is to highlight some lines, then call out to the shell to transform them.
For example, to sort some lines in Vim, highlight and `!sort`.

See [my blog post](http://nathanmlong.com/2013/01/making-vim,-unix-and-ruby-sing-harmony/) for more details.

## Reading man pages

    "Unix will give you enough rope to shoot yourself in the foot. If you didn't think rope would do that, you should have read the man page."
     - https://twitter.com/mhoye/status/694646265657708544

`man` is a command to show the "manual page" for a program, if it has one.
These are great for reference if you know how to read them. Here's the start of `man ls` on OS X:

    LS(1)                     BSD General Commands Manual                    LS(1)

    NAME
         ls -- list directory contents

    SYNOPSIS
         ls [-ABCFGHLOPRSTUW@abcdefghiklmnopqrstuwx1] [file ...]


When they put `[ ]` around something, it means it's optional. `...` means you can put multiple things in that slot.
So `ls [-ABCFGHLOPRSTUW@abcdefghiklmnopqrstuwx1] [file ...]` should be read as: "you can type ls by itself.
You can also pass any of these flags to control what it outputs. You can also pass a file name, or more than one file name."

(By the way, there's nothing special about flags, they're just arguments that the program may decide to interpret a specific way.
So `ls -l .git` just has two arguments.)

As is typical, `man ls` explains in detail what every possible flag will do, but only gives a single usage example.

See `gem install tldrb` for an example-oriented help utility.

## Not covered

- Users, "superusers", sudo, su, and file permissions
- symlinks
- named pipes
- ...
