#
# Author: Brian Leonard
#
#   User reveal.js to make slide stuff in markdown
#
#   {% slide %}
#      * one
#      * two
#
#   ...will output...
require 'delegate'
require 'json'

module Jekyll
  SLIDE_BEGIN_TAG = "<section.+><div class='content'>"
  SLIDE_CONTENT_END_TAG = "<\/div>"
  SLIDE_END_TAG = "<\/section>"
  
  SLIDE_NOTES_BEGIN_TAG = "<aside class='notes'>"
  SLIDE_NOTES_END_TAG = "</aside>"
  
  SLIDE_VERTICAL_BEGIN_TAG = "<section>"
  SLIDE_VERTICAL_END_TAG = "<\/section>"
  
  SLIDE_FIXUPS = [SLIDE_BEGIN_TAG, SLIDE_CONTENT_END_TAG, SLIDE_END_TAG,
                  SLIDE_VERTICAL_BEGIN_TAG, SLIDE_VERTICAL_END_TAG,
                  SLIDE_NOTES_BEGIN_TAG, SLIDE_NOTES_END_TAG]
  
  class SlideBase < Liquid::Tag
    
    def initialize(tag_name, text, token)
      @tag_name = tag_name
      @text = text
      super
    end
    
    def options
      return @options if @options
      text = @text.to_s.gsub(/\s*:\s*/, ":")
      text.gsub!("\"", "")
      val = text.gsub(/(\S+):(\S+)/, '"\1": "\2"')
      @options = JSON.parse("{#{val}}")
    rescue
      @options = {}
    end
    
    def section_end(context)
      out = ""
      
      if context["in_slide_notes"]
        out << "\n\n#{SLIDE_NOTES_END_TAG}\n\n" if context["in_slide_notes"]
      else
        out << "\n\n#{SLIDE_CONTENT_END_TAG}\n\n" if context["in_slide"]
      end
      
      out << "\n\n#{SLIDE_END_TAG}\n\n" if context["in_slide"]
      
      if context["last_vertical_slide"]
        context["last_vertical_slide"] = false
        out << "\n\n#{SLIDE_VERTICAL_END_TAG}\n\n"
      end
      
      context["in_slide_notes"] = false
      context["in_slide"] = false
      out
    end
    
    def section_begin(context)
      context["in_slide"] = true
      
      out = ""
      out << "\n\n#{build_begin_tag}\n\n"
      out
    end
    
    def build_begin_tag
      tag = SLIDE_BEGIN_TAG
      values = "class='slide'"
      
      self.options.each do |k, v|
        values << " data-#{k}='#{v}'"
      end

      replaced = tag.gsub(".+", " #{values}")
      return replaced
    end
    
    def render(context)
      if !context.environments.first["page"] || !context.environments.first["page"]["slides"]
        # only if slides
        return "{% #{(@tag_name.to_s + ' ' + @text.to_s).strip} %}"
      end
      render_tag(context)
    end
  end  
  class SlideStart < SlideBase
    def render_tag(context)
      out = ""
      if !context["done_slide_links"]
        context["done_slide_links"] = true
        if context.environments.first["page"] && context.environments.first["page"]["url"]
          out << "\n\n[<h2>View the Presentation</h2>](#{context.environments.first["page"]["url"]}slides)\n<h5>Or view the slide sheet below</h5><hr />\n\n"
        end
      end
      
      out << section_end(context)
      out << before_slide(context)
      out << section_begin(context)
      out
    end
    
    def before_slide(context)
      ""
    end
  end
  
  class SlideEnd < SlideStart
    def render_tag(context)
      section_end(context)
    end
  end
  
  class SlideVerticalFirst < SlideStart
    def before_slide(context)
      out = ""
      if context["in_vertical_slide"]
        out << "\n\n#{SLIDE_VERTICAL_END_TAG}\n\n"
      end
      
      out << "\n\n#{SLIDE_VERTICAL_BEGIN_TAG}\n\n"
      context["in_vertical_slide"] = true
      out
    end
  end
  
  class SlideVerticalLast < SlideStart
    def before_slide(context)
      out = ""
      context["last_vertical_slide"] = true
      out
    end
  end
  
  class SlideNotes < SlideBase
    def render_tag(context)
      out = ""
      if context["in_slide"]
        context["in_slide_notes"] = true
        out << "\n\n#{SLIDE_CONTENT_END_TAG}\n\n"
        out << "\n\n#{SLIDE_NOTES_BEGIN_TAG}\n\n"
      else
        context["in_slide_notes"] = false
      end
      out
    end
  end
  
  class Site
    # Render the site to the destination.
    #
    # Returns nothing.
    def render_slides
      payload = site_payload
      self.posts.each do |post|
        post.render_slides(self.layouts, payload)
      end

      #self.pages.each do |page|
      #  page.render_slides(self.layouts, payload)
      #end
    rescue Errno::ENOENT => e
      # ignore missing layout dir
    end
  end
  
  class Page
    def transform
      super
      if self.data["slides"]
        SLIDE_FIXUPS.each { |val| self.content.gsub!(/<p>(\s*#{val}\s*)<\/p>/, '\1') }
      end
    end
  end
  
  class Post
    def transform
      super
      if self.data["slides"]
        SLIDE_FIXUPS.each { |val| self.content.gsub!(/<p>(\s*#{val}\s*)<\/p>/, '\1') }
      end
    end
  end
    
  class SlidePost < DelegateClass(Post)
    def initialize(page)
      super(page)
      self.data = page.data.clone
      self.data["layout"] = "slides"
      @source_dir = page.site.source
      @slides_html = "#{page.site.config['slides_folder'] || 'slides'}/index.html"
    end
 
    def slide_destination(page)
      page_path = destination(page)
      page_path.sub('index.html', @slides_html)
    end
  
    def write(dest)
      path = slide_destination(dest)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') do |f|
        f.write(self.output)
      end
      
      # speaker notes
      path = path.sub('index.html', 'notes.html')
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') do |f|
        file = File.join(@source_dir, 'assets', 'slides', 'notes.html')
        f.write(File.read(file))
      end
      
    end
  end
 
  class Site
    alias _slide_orig_write write
    def write
      _slide_orig_write
 
      self.posts.each do |page|
        if page.data["slides"]
          slides = SlidePost.new(page)
          slides.render(self.layouts, site_payload)
          slides.write(self.dest)
        end
      end
    end
  end
end

Liquid::Template.register_tag("slide_top", Jekyll::SlideVerticalFirst)
Liquid::Template.register_tag("slide_bottom", Jekyll::SlideVerticalLast)
Liquid::Template.register_tag("slide", Jekyll::SlideStart)
Liquid::Template.register_tag("endslide", Jekyll::SlideEnd)
Liquid::Template.register_tag("notes", Jekyll::SlideNotes)