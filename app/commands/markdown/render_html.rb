class Markdown::RenderHTML
  include Mandate

  initialize_with :doc, :nofollow_links

  def call
    renderer = Renderer.new(options: [:UNSAFE], nofollow_links: nofollow_links)
    renderer.render(doc)
  end

  class Renderer < CommonMarker::HtmlRenderer
    def initialize(options:, nofollow_links: false)
      super(options: options)
      @nofollow_links = nofollow_links
    end

    private
    attr_reader :nofollow_links

    def link(node)
      # TODO: re-enable once we figure out how to do custom scrubbing
      # return vimeo_link(node) if vimeo_link?(node)

      out('<a href="', node.url.nil? ? '' : escape_href(node.url), '"')
      out(' title="', escape_html(node.title), '"') if node.title.present?
      if external_url?(node.url)
        out(' target="_blank"')
        out(' rel="noopener', nofollow_links ? ' nofollow' : '', '"')
      elsif nofollow_links
        out(' rel="nofollow"')
      end
      out(link_tooltip_attributes(node))
      out('>', :children, '</a>')
    end

    def external_url?(url)
      uri = Addressable::URI.parse(url)
      return false if uri.scheme.nil?
      return true unless %w[https http].include?(uri.scheme)
      return false if %w[exercism.io exercism.lol local.exercism.io exercism.org local.exercism.org].include?(uri.host)

      true
    rescue StandardError
      true
    end

    def link_tooltip_attributes(node)
      link_match = %r{^(?<url>https?://(?<local>local\.)?exercism\.(?<domain>io|lol|org))?/tracks/(?<track>[^/]+)/(?<type>concept|exercise)s/(?<slug>[^/#?]+)}.match(node.url) # rubocop:disable Layout/LineLength
      return unless link_match

      endpoint = Exercism::Routes.send("tooltip_track_#{link_match[:type]}_path", link_match[:track], link_match[:slug])
      %( data-tooltip-type="#{link_match[:type]}" data-endpoint="#{endpoint}")
    end

    def code_block(node)
      return note_block(node) if NOTE_BLOCK_FENCES.include?(node.fence_info)

      block do
        out("<pre#{sourcepos(node)}><code")
        if node.fence_info.present?
          out(' class="language-', node.fence_info.split(/\s+/)[0], '">')
        else
          out(' class="language-plain">')
        end
        out(escape_html(node.string_content))
        out('</code></pre>')
      end
    end

    def note_block(node)
      type = node.fence_info.split('/')[1]
      block do
        out(%(<div class="c-textblock-#{type}">))
        out(%(<div class="c-textblock-header">#{type.titleize}</div>))
        out('<div class="c-textblock-content">')
        out(escape_html(node.string_content))
        out('</div>')
        out('</div>')
      end
    end

    def vimeo_link(node)
      block do
        out('<div style="padding:56.25% 0 0 0; position:relative">')
        out(%(<iframe src="#{node.url}?badge=0&amp;autopause=0&amp;player_id=0&amp;app_id=58479" frameborder="0" allow="autoplay; fullscreen; picture-in-picture" allowfullscreen style="position:absolute;top:0;left:0;width:100%;height:100%;" title="X Exercism_ Tutorial Your first mentoring session 1.m4v">)) # rubocop:disable Layout/LineLength
        out('</iframe>')
        out('</div>')
        out('<script src="https://player.vimeo.com/api/player.js">')
        out('</script>')
      end
    end

    def vimeo_link?(node)
      return false if node.nil?

      node.url.start_with?('https://player.vimeo.com')
    end

    NOTE_BLOCK_FENCES = %w[exercism/note exercism/caution exercism/advanced].freeze
  end
end
