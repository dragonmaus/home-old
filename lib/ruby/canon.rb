require "addressable/uri"
require "hpricot"
require "net/http"

module Addressable
  class URI
    def canonical
      uri = self.fixup

      response = uri.fetch
      response.uri = uri if response.uri.nil?
      response.uri.normalize!

      unless response.is_a?(Net::HTTPOK)
        warn "#{response.uri} returned status code #{response.code}"
        return response.uri
      end

      unless response.content_type == "text/html"
        return response.uri
      end

      document = Hpricot.parse(response.body)
      # <link rel="canonical"> takes priority over <meta property="og:url">
      uri = if element = document.at("link[@rel='canonical']")
              Addressable::URI.parse(element["href"])
            elsif element = document.search("meta[@property$='url']").select { |element| element["property"] == "og:url" }[0]
              Addressable::URI.parse(element["content"])
            else
              response.uri
            end

      # The spec allows relative URIs in the "canonical" link
      uri = Addressable::URI.join(response.uri.to_s, uri) unless uri.absolute?

      # Because you can't always trust sites to do things properly
      uri.normalize
    end

    def fetch(limit = 50)
      Net::HTTP.start(self.hostname, self.port, :use_ssl => self.scheme == "https") do |http|
        user_agent = "Mozilla/5.0"

        uri = self.dup
        response = nil
        limit.times do
          request = Net::HTTP::Head.new(uri)
          request["user-agent"] = user_agent

          response = http.request(request)

          break unless response.is_a?(Net::HTTPRedirection)

          previous_uri = uri
          uri = Addressable::URI.parse(response["location"]).fixup

          # Detect redirect loops early
          break if uri == previous_uri
        end

        # Some (rude) sites don't allow HEAD requests, so check for redirects
        (limit / 10).to_i.times do
          request = Net::HTTP::Get.new(uri)
          request["user-agent"] = user_agent

          response = http.request(request)

          break unless response.is_a?(Net::HTTPRedirection)

          previous_uri = uri
          uri = Addressable::URI.parse(response["location"]).fixup

          # Detect redirect loops early
          break if uri == previous_uri
        end

        response.uri = uri if response.uri.nil?
        response
      end
    end

    def fixup
      self.normalize
    end
  end
end