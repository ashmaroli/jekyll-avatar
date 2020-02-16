# frozen_string_literal: true

require "zlib"

module Jekyll
  class Avatar < Liquid::Tag
    include Jekyll::LiquidExtensions

    SERVERS      = 4
    DEFAULT_SIZE = "40"
    API_VERSION  = "3"

    def initialize(_tag_name, text, _tokens)
      super
      @text = text.strip
      @markup = Liquid::Template.parse(@text)

      @custom_host = ENV["PAGES_AVATARS_URL"]
      @custom_host = "" unless @custom_host.is_a?(String)

      @size = compute_size
      @user_variable = extract_user_variable
    end

    def render(context)
      @context = context
      @text    = @markup.render(@context)
      attrs    = attributes.map { |k, v| "#{k}=\"#{v}\"" }.join(" ")
      "<img #{attrs} />"
    end

    private

    def attributes
      result = {
        "class"               => classes,
        "alt"                 => username,
        "width"               => size,
        "height"              => size,
        "data-proofer-ignore" => "true"
      }

      if lazy_load?
        result["src"] = ""
        result["data-src"] = url
        result["data-srcset"] = srcset
      else
        result["src"] = url
        result["srcset"] = srcset
      end

      result
    end

    def lazy_load?
      @text.include?("lazy=true")
    end

    def extract_user_variable
      matches = @text.match(%r!\buser=([\w\.]+)\b!)
      matches[1] if matches
    end

    def username
      return lookup_variable(@context, @user_variable) if @user_variable

      result = @text.include?(" ") ? @text.split(" ")[0] : @text
      result.start_with?("@") ? result.sub("@", "") : result
    end

    def compute_size
      matches = @text.match(%r!\bsize=(\d+)\b!i)
      matches ? matches[1] : DEFAULT_SIZE
    end
    attr_reader :size

    def path(scale = 1)
      "#{username}?v=#{API_VERSION}&s=#{scale == 1 ? size : (size.to_i * scale)}"
    end

    def server_number
      Zlib.crc32(path) % SERVERS
    end

    def host
      if @custom_host.empty?
        "https://avatars#{server_number}.githubusercontent.com"
      else
        @custom_host
      end
    end

    def parsed_host
      @parsed_host ||= {}
      @parsed_host[host] ||= Addressable::URI.parse(host)
    end

    def url_with_custom_host(scale = 1)
      uri = parsed_host
      uri.path << "/" unless uri.path.end_with?("/")
      uri = uri.join path(scale)
      uri.to_s
    end

    def url(scale = 1)
      return url_with_custom_host(scale) unless @custom_host.empty?

      "#{host}/#{path(scale)}"
    end

    SCALES = %w(1 2 3 4).freeze
    private_constant :SCALES

    def srcset
      SCALES.map { |scale| "#{url(scale.to_i)} #{scale}x" }.join(", ")
    end

    # See http://primercss.io/avatars/#small-avatars
    def classes
      size.to_i < 48 ? "avatar avatar-small" : "avatar"
    end
  end
end

Liquid::Template.register_tag("avatar", Jekyll::Avatar)
