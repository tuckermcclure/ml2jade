![ml2jade](ml2jade-logo.png)

This tool does three things:
* Publish a MATLAB script to a Jade file;
* Evaluate code snippets in an existing Jade file and add the results to the original Jade;
* Render the Jade file from either of the above to static HTML (requires Node, Jade, and Stylus)

It works like MATLAB's built-in <code>publish</code> function, but produces very clean Jade syntax, which can be easily combined with templates or stylesheets.

Jade files aren't meant to be viewed themselves; a tool renders them to HTML (either statically or as part of a webserver). <code>ml2jade</code> is useful, for instance, if you maintain a series of MATLAB examples for a website. You can write MATLAB scripts and publish them directly to Jade using your custom template, or you can write your .jade files yourself, automatically evaluate the code blocks inside of it, and put the output on the web server.

# Examples

To publish a MATLAB script to Jade, call <code>enjaden</code> from within MATLAB.
```
enjaden('my_script.m');
```
By default, the output directory will be the same directory the file is in. To specify the output directory:
```
enjaden('my_script.m', 'path/to/outputs');
```
To use a custom template for the page frame (see the included <code>_template.jade</code> for more):
```
enjaden('my_script.m', 'path/to/outputs', '_my_jade_template.jade');
```
When the template isn't provided or is empty (<code>[]</code>), it will use <code>_template.jade</code>.
  
To publish to Jade _without_ evaluating the code (just translating the code itself):
```
enjaden('my_script.m', 'path/to/outputs', [], false);
```
Finally, the render the Jade to static HTML (requires Node, Jade, and Stylus):
```
enjaden('my_script.m', 'path/to/outputs', [], [], true);
```

# Installation of <code>ml2jade</code>

If you're a GitHub user, you can clone <code>ml2jade</code> to whatever location you like. Just add this location to the MATLAB path.

If you're not a GitHub user, you can just download a copy (link at the right hand side of the page) or create a GitHub account so you can keep syncronized with updates and things. Assuming you download the file, unzip it somewhere and add that location to your MATLAB path.

# Using Jade

If you already have a way to work with Jade files, there's nothing new you'll need to do here. Otherwise, you should know that Jade is a great language for making web pages. You can actually run a server that serves up Jade files or you can render .jade files down to static HTML.

Let's look at rendering to static HTML first. <code>ml2jade</code> can do this for you; it's the final argument to <code>ml2jade</code> and <code>enjaden</code>. You'll just need to have Node, Jade, and Stylus installed.

1. Head on over to [Node.js](http://www.nodejs.org) and download the appropriate installer for your system. Run the installer.
2. If that worked, open a terminal window (command line) and run <code>npm install jade -g</code> (or <code>sudo npm install jade -g</code> if you get a message about permissions on OS X or Linux).
3. Now install Stylus the same way: <code>npm install stylus -g</code> (or <code>sudo npm install stylus -g</code>).

Done! Now the <code>render</code> option to <code>ml2jade</code> and <code>enjaden</code> will work and will produce a static HTML page from the generated Jade files.

For an example of using <code>ml2jade</code> with your new Jade + Stylus installation:

1. Open MATLAB, navigate to wherever you put <code>ml2jade</code> and run <code>enjaden('enjaden_example.m', 'jade')</code> to publish <code>enjaden_example.m</code> to <code>jade/enjaden_example.jade</code>. This will publish the MATLAB script to a Jade file in <code>ml2jade/jade/enjaden_example.jade</code>.
2. To convert the Jade all the way to HTML, run <code>enjaden('enjaden_example.m', 'jade', [], [], true)</code> (that's file name, output directory, template [default], evaluate [default], and _render_). This will create <code>ml2jade/jade/enjaden_example.html</code>.

Using a server is a great choice too, and [Harp](http://harpjs.com) is particularly easy. It also runs on [Node.js](http://www.nodejs.org) and is light and easy to use. Here's how to get set up with using Harp for the first time:

1. Head on over to [Node.js](http://www.nodejs.org) and download the appropriate installer for your system. Run the installer.
2. If that worked, open a terminal window (command line) and run <code>npm install harp -g</code> (or <code>sudo npm install harp -g</code> if you get a message about permissions on OS X or Linux).

That's it for installation! You can now navigate to any directory with Jade files and run <code>harp server</code>.

For an example of using <code>ml2jade</code> with your new Harp installation:

1. Open MATLAB, navigate to wherever you put <code>ml2jade</code> and run <code>enjaden('enjaden_example.m', 'jade')</code> to publish <code>enjaden_example.m</code> to <code>ml2jade/jade/enjaden_example.jade</code>.
2. Back in the terminal window, navigate to the <code>ml2jade/jade</code> directory (which was just created). Type <code>harp server</code>.
3. Open up a broswer and navigate to <code>http://localhost:9000/enjaden_example.html</code>, and the published page should pop up.
4. You can leave the Harp server up as long as you like. When you're done viewing Jade files, go back to the terminal window and use ctrl+c to stop the server.
