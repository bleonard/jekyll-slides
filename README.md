I really like [Jekyll](http://jekyllrb.com/)/[Octopress](http://octopress.org/) and have aspirations to make my presentations in HTML instead of Powerpoint. For my last [presentation to the Redis Meetup](http://www.meetup.com/San-Francisco-Redis-Meetup/events/164972192/), I combined the two. I found it really easy to "blog" the talk and created a [plugin](https://github.com/bleonard/jekyll-slides) to convert [that](http://www.bleonard.com/blog/2014/02/16/resque-bus-presentation/) to a [reveal.js](http://lab.hakim.se/reveal-js) [presentation](http://www.bleonard.com/blog/2014/02/16/resque-bus-presentation/slides) from the same source. It's my first Jekyll plugin, but it got the job done. Check it out [here](https://github.com/bleonard/jekyll-slides).

## Usage

Make a new blog post and add `slides: simple` to the metadata at the top. The value `simple` refers to the [reveal.js theme](http://lab.hakim.se/reveal-js/?theme=solarized#/themes) to use. The options are: `beige`, `blood`, `moon`, `night`, `serif`, `simple`, `sky`, and `solarized`.

Here is the header from the [last presentation](http://www.bleonard.com/blog/2014/02/16/resque-bus-presentation/slides):

    ---
    layout: post
    published: true
    title: "Resque Bus Presentation"
    date: 2014-02-16 08:48
    comments: true
    author: BL
    slides: simple
    categories: architecture resque redis bus
    ---

You then write your normal blog post with a few extra elements mixed in. 

For example, you start a slide with the `{% slide %}` notation. You can also say `{% notes %}` at the "bottom" of a slide. This will not appear in the slideshow, but will appear in the blog post.

You say `{% endslide %}` at the end of the presentation. You could do this each time, but it's inferred by the beginning of a new slide using `{% slide %}`, so the end notation is only needed at the end.

That's about it. Here 's the whole presentation if it was only a few of the slides:

    {% slide %}

    ## Resque Bus

    ### Brian Leonard

    ##### TaskRabbit
    ##### 02/17/2014

    {% notes %}

    Hi, my name is Brian Leonard and I'm the Chief Architect and Technical Cofounder of TaskRabbit. TaskRabbit is a marketplace where neighbors help neighbors get things done.

    At TaskRabbit we are using Redis and Resque to do all of our background processing. We've also gone one step further to use these tools to create an asynchronous message bus system that we call Resque Bus.

    {% slide %}

    ### Redis

    * Key/Value Store
    * Atomic Operations

    ![Redis Logo](/images/posts/resque-bus-presentation/redis-logo.jpeg)

    {% notes %}

    I don't have to tell you guys about Redis, but for our purposes the main point is that we can store stuff in it and the operations are atomic.
    
    {% slide %}

    ## Thanks!

    Questions?

    {% endslide %}

Compilation produces the [blog post here](http://www.bleonard.com/blog/2014/02/16/resque-bus-presentation/) as well as the [presentation here](http://www.bleonard.com/blog/2014/02/16/resque-bus-presentation/slides).

<!-- more -->

## Installation

The jekyll-slides repo is [here](https://github.com/bleonard/jekyll-slides). Clone the project.

    cd jekyll-slides
    ./install ~/your/blog/path
    
This will run a bash script that copies over the necessary files.

* plugins/slides.rb
* assets/slides/(js|css)
* layouts/slides.html

It also will add a link to `/assets/slides/css/for_blog.css` in the custom head.html file that [octopress](http://octopress.org/) uses within _includes. If you have another setup, you'll have to add something like this to your normal blog layout:

```html
<link rel="stylesheet" href="/assets/slides/css/for_blog.css">
```

That should be it. I couldn't find a best practice for installing these plugins so I made this script. I've tested it on a fresh octopress install and it works as expected. If you have another setup or other issues, please let me know.

## Extra Options

There are a few other things I threw in that I wanted to have in my presentation.

The reveal.js framework supports [vertical slides](http://lab.hakim.se/reveal-js/#/2). This is handled in jekyll through the `{% slide_top %}` and `{% slide_bottom %}` tags used instead of the normal `{% slide %}` one. The first one in a vertical stack is noted as `slide_top`, the last one is `slide_bottom` and the ones in the middle are just `slide`.

It also supports other metadata on the slide. For example, if you add `data-transition="none"` to the `<section class="slide">` it will affect the transition. You can add metadata by adding it to the `{% slide %}` (or `{% slide_top %}` or `{% slide_bottom %}`) tag. The `data-background` options should also work with this approach. 

Here is the example from the presentation

    % slide_top transition: none %}

    ![Bus 2](/images/posts/resque-bus-presentation/rating_bus_2.png)

    {% notes %}

    As you can see, the difference is this new layer of `resquebus_incoming` that we've added, so now it looks like this.

    {% slide transition: none %}

    ![Bus 3](/images/posts/resque-bus-presentation/rating_bus_3.png)

    {% notes %}
    
    Several more slides in the stack
    
    {% slide_bottom transition: none %}

    ![Bus 9](/images/posts/resque-bus-presentation/rating_bus_9.png)

## Supported Reveal Features

A few of the presentation-mode features are supported as well. Hitting the `f` key in the presentation will put it in full screen mode.

Speaker notes are also supported. Hitting `s` in the presentation will launch a new window that shows the current and next slides along with the current notes.

## Technical Details

All the ruby code is in [slides.rb](https://github.com/bleonard/jekyll-slides/blob/master/slides.rb). It implements the tags used, all of which extend from `Liquid::Tag`. Each available tag is mapped to a ruby class the outputs HTML. 

I tried to be as minimal as possible about tag use. That is, there are no blocks or unnecessary end tags. To do this, context is kept in memory about where we are in the hierarchy. For example, if it hits a new `{% slide %}` call, it knows it hasn't closed out the last one and takes care of that before proceeding.

It was important that all of these tags only take effect if the page/post was marked as `slide` in the metadata. Similarly, I extended the `Site` compile process to produce the extra files (one for slides and one for notes) if it has the same metadata field.

Something interesting was that I was trying to output HTML, but I think Jekyll/Liquid was expecting that it was outputting Markdown. This probably usually works out fine as HTML can be rendered in Markdown and the HTML is usually something inline and not huge blocks. The issue was that it put `<p>` tags around everything which threw off the reveal.js situation. To fix this, I go back over the text in the compilation process and remove those `<p>` tags with a fairly targeted `gsub` call.

## Summary

It's likely a limitation added by the translation layer, but I didn't have the control I wanted to over the slides. In Powerpoint, I would have made them just right. I'm not sure if I could achieve that even in straight HTML without massive effort and this added abstraction might be insurmountable.

So we'll see how it goes. I achieved what I was trying to do with this and I hope you get some use of out of it. I'll probably iterate on it a bit to see if I can make the slides better. Pull requests quite welcome.
