require 'nokogiri'
require_relative 'parser/version'
require_relative 'parser/itemsearch_response'
require_relative 'parser/itemlookup_response'
require_relative 'parser/browsenode_response'

module Vacuum
  class Parser
    class ParserError < RuntimeError
    end

    def self.parse(body)
      document = Nokogiri::XML(body)
      name = document.root.name
      case name
      when 'ItemSearchResponse'
        ItemSearchResponse.new(document)
      when 'ItemLookupResponse'
        ItemLookupResponse.new(document)
      when 'BrowseNodeLookupResponse'
        BrowseNodeResponse.new(document)
      else
        ParserError.new(name + ' is not implemented!')
      end
    end
  end
end
