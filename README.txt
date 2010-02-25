= Castanaut: Automate your screencasts.

    Author: Joseph Pearson
    http://gadgets.inventivelabs.com.au/castanaut

== DESCRIPTION:

Castanaut lets you write executable scripts for your screencasts. With a
simple dictionary of stage directions, you can create complex interactions
with a variety of applications. Currently, and for the foreseeable future,
Castanaut supports Mac OS X 10.5 only.

== SYNOPSIS:

=== Writing screenplays

You write your screenplays as Ruby files. Castanaut has been designed to
read fairly naturally to the non-technical, within Ruby's constraints.

Here's a simple screenplay:

  launch "Safari", at(10, 10, 800, 600)
  type "http://www.inventivelabs.com.au"
  hit Enter
  pause 2
  move to(100, 100)
  move to(200, 100)
  move to(200, 200)
  move to(100, 200)
  move to(100, 100)
  say "I drew a square!"

With any luck we don't need to explain to you what this screenplay
does. The only thing that might need some explanation is "say" -- this has a
robotic voice speak the given string. (Also: all numbers are pixel
co-ordinates).

About the robot: no, we don't recommend you use this in real screencasts for
a large audience. Most people find it a little offputting.
You are free to contravene our recommendation though. You
can tweak the robot in the Mac OS X Speech Preferences pane.

=== Running your screenplay

Simply give the screenplay to the castanaut command, like this:

  castanaut test.screenplay

This assumes you have a screenplay file called "test.screenplay" in the
directory where you are running the command.

Of course, it isn't always convenient to drop to the terminal to run your
screenplay. So there's also a method of executing your screenplays directly.
You need to add this line (the "shebang" line) at the top of your screenplay:

#!/usr/bin/env castanaut

Then you need to set the screenplay to be executable by running this command
on it:

  chmod a+x test.screenplay

Again, substitute "test.screenplay" for your screenplay's filename.

At this point, you should be able to double-click the screenplay, or invoke
it with Quicksilver, or run it any other way that floats your boat.

=== Stopping the screenplay

If you want to abruptly terminate execution before the end of the screenplay,
you just need to run the 'castanaut' command again -- with or without any
arguments.

Of course, that might be easier said than done, if you haven't got full
control of the mouse or keyboard at the time. One recommendation is to assign
a system hot-key to invoke castanaut. I use a Quicksilver trigger for this,
assigned to Shift-F1, that calls castanaut. You'll need the full path to
the command for this, which is usually /usr/bin/castanaut, but you can check
it with the following command:

  which "castanaut"

== Running interactively with IRB

You can now run Castanaut interactively from IRB — to test commands, try stuff
out, etc:

    $ irb -r 'castanaut'
    >> irb Castanaut::Movie.new
    >> move to(100, 100)
    => "Moving mouse.\n"

Note that this technique creates an IRB subsession, so you'll have to exit out
of that before exiting out of IRB. There's heaps you can do with subsessions -
read up about them online.

=== What stage directions can I make?

Out of the box, Castanaut performs mouse actions, keyboard actions,
robot speech and application launches.

For a complete overview of the built-in stage directions, see the
Castanaut::Movie class.

=== Using plugins

Of course, just using the built-in stage directions is a little bit awkward
and verbose. Plugins allow you to extend the available dictionary with
some additional convenience actions. Typically a plugin is specific to an
application.

Castanaut comes with several plugins, including 

* Castanaut::Plugin::Safari for interacting with the contents of web-pages
* Castanaut::Plugin::Ishowu for recording screencasts using the iShowU 
  application from Shiny White Box. 
* Castanaut::Plugin::Textmate for opening files to specific line numbers.

To use a plugin, simply declare it:

  plugin "safari"

  launch "Safari", at(32, 32, 800, 600)
  url "http://www.google.com"
  pause 4
  move to_element('input[name="q"]')
  click
  type "Castanaut"
  move to_element('input[type="submit"]')
  click
  pause 4
  say "Oh. I was hoping for more results."


In the example above, we use the two methods provided by the Safari module:
url, which causes Safari to navigate to the given url, and to_element, which
returns the co-ordinates of a page element (using CSS selectors) relative to
the screen.

=== Creating your own plugins

Advanced users can create their own plugins. Put them in a directory
called "plugins" below the directory containing the screenplays that use
the plugin.

Take a look at the plugins that Castanaut comes with for examples on creating
your own.

== REQUIREMENTS:

* Mac OS X 10.5

or

* Mac OS X 10.4
* The Extras Suite application <http://www.kanzu.com/main.html#extrasuites>

== INSTALL:

Run the following command to install Castanaut

  sudo gem install castanaut

If you're using Mac OS X 10.4 (Tiger) you will also need to download and install the XTool scripting additions.

Once installed, you should run the following command for two reasons:

  castanaut

Reason 1 is to confirm that it is installed correctly. Reason 2 is to set up
the permissions on the utility that controls your mouse and keyboard during
Castanaut movies. You may be asked for a password here.

If you just see a "ScreenplayNotFound" exception here, everything's good.

== LICENSE:

Copyright (C) 2008 Inventive Labs.

Released under the WTFPL: http://sam.zoy.org/wtfpl.

Portions released under the MIT License.

See Copyright.txt for full licensing details.
