module Vacuum
  class Parser
    class BrowseNodeResponse
      attr_accessor :Document

      def initialize(document)
        raise ParserError.new('Not a XML::Document') unless document.is_a?(Nokogiri::XML::Document)
        @Document = document
        raise ParserError.new('Not a BrowseNodeLookupResponse') if document.root.name != 'BrowseNodeLookupResponse'
      end

      def operationRequest
        OperationRequest.new(@Document.at('/xmlns:BrowseNodeLookupResponse/xmlns:OperationRequest'))
      end

      def isValid?
        @Document.at('/xmlns:BrowseNodeLookupResponse/xmlns:BrowseNodes').present?
      end

      def request
        @Document.at('/xmlns:BrowseNodeLookupRequest/xmlns:Items/xmlns:Request/xmlns:BrowseNodeLookupRequest')
      end

      def error
        error = @Document.at('/xmlns:BrowseNodeLookupResponse/xmlns:Items/xmlns:Request/xmlns:Errors/xmlns:Error')
        error.content if error
      end

      def browse_nodes
        return nil unless isValid?
        @BrowseNodes ||= BrowseNodes.new(@Document.at('/xmlns:BrowseNodeLookupResponse/xmlns:BrowseNodes'))
      end

      class OperationRequest
        def initialize(operation_request)
          raise ParserError.new('Not a Node') unless operation_request.is_a?(Nokogiri::XML::Node)
          # TODO
        end
      end

      class BrowseNodes
        attr_accessor :BrowseNodes
        def initialize(browse_nodes)
          raise ParserError.new('Not a Node') unless browse_nodes.is_a?(Nokogiri::XML::Node)
          @BrowseNodes = browse_nodes
        end

        def to_a
          @List ||= (@BrowseNodes / './xmlns:BrowseNode').inject([]) { |lst, itm| lst << BrowseNode.new(itm) }
          @List
        end
      end

      class BrowseNode
        attr_accessor :BrowseNode
        attr_accessor :browse_node_id
        attr_accessor :name
        attr_accessor :ancestors
        attr_accessor :children
        def initialize(browse_node)
          raise ParserError.new('Not a Node') unless browse_node.is_a?(Nokogiri::XML::Node)
          @BrowseNode = browse_node
          @browse_node_id = (n = @BrowseNode.at('./xmlns:BrowseNodeId')) && n.content.to_i
          @name = (n = @BrowseNode.at('./xmlns:Name')) && n.content.to_s
          @ancestors ||= (@BrowseNode / './xmlns:Ancestors').inject([]) { |lst, itm| lst << Ancestors.new(itm) }
          @children ||= (@BrowseNode / './xmlns:Children').inject([]) { |lst, itm| lst << Children.new(itm) }
        end
      end

      class Ancestors
        attr_accessor :Ancestors
        attr_accessor :browse_node
        attr_accessor :children
        def initialize(ancestor)
          raise ParserError.new('Not a Node') unless ancestor.is_a?(Nokogiri::XML::Node)
          @Ancestors = ancestor
          @browse_node = (n = @Ancestors.at('./xmlns:BrowseNode')) && BrowseNode.new(n)
          @children ||= (@Ancestors / './xmlns:Children').inject([]) { |lst, itm| lst << Children.new(itm) }
        end
      end

      class Children
        attr_accessor :Children
        attr_accessor :browse_node
        attr_accessor :ancestors
        def initialize(ancestor)
          raise ParserError.new('Not a Node') unless ancestor.is_a?(Nokogiri::XML::Node)
          @Children = ancestor
          @browse_node = (n = @Children.at('./xmlns:BrowseNode')) && BrowseNode.new(n)
          @ancestors ||= (@Children / './xmlns:Ancestors').inject([]) { |lst, itm| lst << Ancestors.new(itm) }
        end
      end

    end
  end
end