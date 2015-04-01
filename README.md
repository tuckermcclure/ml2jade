# ml2jade

This tool does two things:
* Publish a MATLAB script to a Jade file;
* Evaluate code snippets in an existing Jade file and add the results to the original Jade.

It works like MATLAB's built-in <code>publish</code> function, but produces very clean Jade syntax, which can be easily combined with templates or stylesheets.

Jade files aren't meant to be viewed themselves; a tool renders them to HTML (either statically or as part of a webserver). <code>ml2jade</code> is useful, for instance, if you maintain a series of MATLAB examples for a website. You can write MATLAB scripts and publish them directly to Jade using your custom template, or you can write your .jade files yourself, automatically evaluate the code blocks inside of it, and put the output on the web server.

# Examples

To publish a MATLAB script to Jade, call <code>enjaden</code> from within MATLAB.
```
enjaden('my_script.m');
```
To use a custom template for the page frame (see the included _template.jade for more):
```
enjaden('my_script.m', '_my_jade_template.jade');
```
When the template isn't provided or is empty ([]), it will use _template.jade.
  
To publish to Jade _without_ evaluating the code (just rendering the code itself):
```
enjaden('my_script.m', [], false);
```
# Installation of <code>ml2jade</code>

If you're a GitHub user, you can clone <code>ml2jade</code> to whatever location you like. Just add this location to the MATLAB path.

If you're not a GitHub user, you can just download a copy (link at the right hand side of the page) or create a GitHub account so you can keep syncronized with updates and things. Assuming you download the file, unzip it somewhere and add that location to your MATLAB path.

# Using Jade

If you already have a way to work with Jade files, there's nothing new you'll need to do here. Otherwise, you should know that Jade is a great language for making web pages. You can actually run a server that serves up Jade files or you can render .jade files down to static HTML. Either way, you'll need a tool to do so. [Harp](www.harpjs.com) is a great choice. It runs on [Node.js](www.nodejs.org) and is light and easy to use. Here's how to get set up with using Jade + Harp for the first time:

1. Head on over to [Node.js](www.nodejs.org) and download the appropriate installer for your system. Run the installer.
2. If that worked, open a terminal window (command line) and run <code>npm install -g harp</code> (or <code>sudo npm install -g harp</code> if you get a message about permissions on OS X or Linux).
That's it for installation!

For an example of using <code>ml2jade</code> with your new Harp installation:

1. Open MATLAB, navigate to wherever you put <code>ml2jade</code> and run <code>enjaden('enjaden_example.m', [], [], 'jade')</code> to publish <code>enjaden_example.m</code> to <code>jade/enjaden_example.jade</code>.
2. Back in the terminal window, navigate to the <code>ml2jade/jade</code> directory (which was just created). Type <code>harp server</code>.
3. Open up a broswer and navigate to <code>http://localhost:9000/enjaden_example.html</code>, and the published page should pop up.
4. You can leave the Harp server up as long as you like. When you're done viewing Jade files, go back to the terminal window and use ctrl+c to stop the server.
5. To produce static HTML from the Jade files, use <code>harp compile</code>.
