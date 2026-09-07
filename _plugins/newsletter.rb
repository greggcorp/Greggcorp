require "nokogiri"
require "uri"

module GreggIo
  # Injects email-client-safe inline styles onto arbitrary post HTML
  # (nested tables aren't needed here since we're styling inline content,
  # not building layout structure -- that's handled separately in the
  # email layout's own table shell).
  module EmailStyler
    HEADING_STYLE = "font-family:Georgia,'Times New Roman',serif;font-weight:bold;color:#9A3324;margin:28px 0 12px 0;"
    P_STYLE = "margin:0 0 20px 0;font-family:Georgia,'Times New Roman',serif;font-size:19px;line-height:1.65;color:#2A241D;"
    UL_STYLE = "margin:0 0 20px 0;padding-left:24px;font-family:Georgia,'Times New Roman',serif;font-size:19px;line-height:1.65;color:#2A241D;"
    LI_STYLE = "margin-bottom:12px;"
    A_STYLE = "color:#9A3324;"
    BLOCKQUOTE_STYLE = "margin:0 0 20px 0;padding-left:16px;border-left:3px solid #EAE3D8;font-style:italic;color:#5A5248;"
    IMG_STYLE = "max-width:100%;height:auto;display:block;margin:0 0 20px 0;"

    HEADING_SIZES = { "h1" => "27px", "h2" => "25px", "h3" => "22px", "h4" => "19px", "h5" => "19px", "h6" => "19px" }.freeze

    # Returns [styled_html_string, block_count] for the first `limit` top-level
    # block elements when limit is given, or the full document when nil.
    def self.render(html, site_url, limit: nil)
      fragment = Nokogiri::HTML::DocumentFragment.parse(html.to_s)
      blocks = fragment.children.select { |node| node.element? }

      blocks = blocks.first(limit) if limit

      blocks.each { |node| style_node!(node, site_url) }
      blocks.map(&:to_html).join("\n")
    end

    def self.style_node!(node, site_url)
      case node.name
      when "h1", "h2", "h3", "h4", "h5", "h6"
        node["style"] = HEADING_STYLE + "font-size:#{HEADING_SIZES[node.name]};"
      when "p"
        node["style"] = P_STYLE
      when "ul", "ol"
        node["style"] = UL_STYLE
      when "li"
        node["style"] = LI_STYLE
      when "blockquote"
        node["style"] = BLOCKQUOTE_STYLE
      when "img"
        node["style"] = IMG_STYLE
        absolutize_attr!(node, "src", site_url)
      end

      node.css("a").each do |a|
        a["style"] = A_STYLE
        absolutize_attr!(a, "href", site_url)
      end

      node.css("img").each do |img|
        img["style"] ||= IMG_STYLE
        absolutize_attr!(img, "src", site_url)
      end

      node.remove_attribute("class")
      node.remove_attribute("id")
    end

    def self.absolutize_attr!(node, attr, site_url)
      value = node[attr]
      return if value.nil? || value.empty?
      return if value.start_with?("http://", "https://", "mailto:", "#")

      node[attr] = URI.join("#{site_url}/", value).to_s
    rescue URI::InvalidURIError
      nil
    end
  end

  module EmailFilters
    def email_body(html)
      GreggIo::EmailStyler.render(html, @context.registers[:site].config["url"])
    end

    def email_excerpt(html, limit = 3)
      GreggIo::EmailStyler.render(html, @context.registers[:site].config["url"], limit: limit)
    end

    def byte_size(str)
      str.to_s.bytesize
    end
  end

  # Generates /emails/<slug>.html for every post, skipping any with
  # `newsletter: false` in front matter. Rendered through _layouts/email.html.
  #
  # Converts each post's raw markdown to HTML itself at generate time
  # (via Jekyll's own configured converter) rather than reading post.content
  # inside the email layout -- generators run before Jekyll's render phase,
  # so relying on another document's post-render state here isn't safe to
  # assume ordering for.
  class EmailPagesGenerator < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      converter = site.find_converter_instance(Jekyll::Converters::Markdown)

      site.posts.docs.each do |post|
        next if post.data["newsletter"] == false

        slug = File.basename(post.url)
        html = converter.convert(post.content)

        page = EmailPage.new(site, site.source, slug, post, html)
        site.pages << page
      end
    end
  end

  class EmailPage < Jekyll::Page
    def initialize(site, base, slug, post, html)
      @site = site
      @base = base
      @dir = "emails"
      @name = "#{slug}.html"

      self.process(@name)
      self.data = {
        "layout" => "email",
        "sitemap" => false,
        "post_title" => post.data["title"],
        "post_date" => post.date,
        "post_url" => post.url,
        "post_html" => html
      }
      self.content = ""
    end
  end
end

Liquid::Template.register_filter(GreggIo::EmailFilters)
