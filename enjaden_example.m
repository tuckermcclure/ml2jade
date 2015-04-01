%% Example MATLAB File for |enjaden|
% 
% This is an example of a MATLAB file which publishes nicely to Jade via
% the |enjaden| tool. It shows what types of paragraph styles and inline
% markup are possible, like *bold* and _italic_ markup.
%
% New paragraphs will each get their own &lt;p&gt; tag.
%
% It shows <https://github.com/tuckermcclure/m2jade links>. Links are only
% captured when they look like the above. Note that < this > will note show
% up as a link, and neither will <strong>this</strong>.
%
% There are numerous paragraph styles, such as code blocks:
%
%   code
%   line 2: code
%   line 3: code
%
% and preformatted text:
%
%  PRE
%     TEXT
%
% There are also the expected ordered and unordered lists. Note that these
% must be offset with a spacer line so that they can be differentiated from
% *bold* inline text that happens to start a new line.
%
% * This is the first part of the list.
% * This is the second part. It's longer than the first. In fact, it's so
%   long that it extends to a new line, without breaking the list.
% * This is the third and final thing.
%
% Numbered lists work the same way:
%
% # Thing 1
% # Thing 2
% # Thing 3

%% Some Actual Code
% 
% Here in this section (marked with %%), we'll include some actual code.
% When |enjaden| comes across this, it will evaluate it and show the
% resulting command window output and figures, just below the code.

% Make a series of random walks.
t = 1:1000;
y = cumsum(randn(5, length(t)), 2);
y(:, end)

% Plot some things.
figure(1);
clf();
plot(t, y);
xlabel('Time');
ylabel('Position');
title('Random Walks');

%% Second Section
% In this section, we'll highlight that you don't *always* have to skip a
% line between the header and paragraph. But we might want to before
% inserting an image so that it will get its own line and not be part of
% the paragraph:
% 
% <<https://github.com/tuckermcclure/m2jade/blob/master/ml2jade_logo.png>>

%%
% Note that the location of the image can be absolute or relative to the 
% file.

%% Section the Third
%
% Note that any time you change a figure, it gets included in the output.
% Let's add some units to the x axis.

xlabel('Time (s)');

%%
% By the way, we can keep adding paragraphs by making new %% sections and
% just not giving them headers.

%% A Demonstration of Equations
% 
% This part is pretty fun. _We're going to show how to use MathJax for 
% equations_! This looks way better than what |publish| does. (Also, note
% that the inline markup in this paragraph spans multiple lines; it's still
% detected correctly.)
%
% Inline equations use single dollar signs, like $x$. Let's discuss in more
% detail in a _display equation_:
%
% $$x = f(x)$$
%
% Looks nice, right? The only downside to using MathJax is that one must be
% connected to the internet. So if you're publishing a MATLAB file to Jade
% from a desert island (or, more likely, on some ancient plane that doesn't
% give you free wifi), you won't be able to see your equations.

%%
% This concludes the example. See |ml2jade_example.jade| for an example of
% a Jade file ready to have its MATLAB sections evaluated and inserted into
% a new Jade file.