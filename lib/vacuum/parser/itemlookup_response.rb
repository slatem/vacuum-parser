module Vacuum
  class Parser
    class ItemLookupResponse
      attr_accessor :Document

      def initialize(document)
        raise ParserError.new('Not a XML::Document') unless document.is_a?(Nokogiri::XML::Document)
        @Document = document
        raise ParserError.new('Not a ItemLookupResponse') if document.root.name != 'ItemLookupResponse'
      end

      def operationRequest
        OperationRequest.new(@Document.at('/xmlns:ItemSearchResponse/xmlns:OperationRequest'))
      end

      def isValid?
        (n = @Document.at('/xmlns:ItemSearchResponse/xmlns:Items/xmlns:Request/xmlns:IsValid')) &&
            (n.content == 'True')
      end

      def request
        @Document.at('/xmlns:ItemSearchResponse/xmlns:Items/xmlns:Request/xmlns:ItemSearchRequest')
      end

      def error
        error = @Document.at('/xmlns:ItemSearchResponse/xmlns:Items/xmlns:Request/xmlns:Errors/xmlns:Error')
        error.content if error
      end

      def items
        return nil unless isValid?
        @Items ||= Items.new(@Document.at('/xmlns:ItemSearchResponse/xmlns:Items'))
      end

      class OperationRequest
        def initialize(operation_request)
          raise ParserError.new('Not a Node') unless operation_request.is_a?(Nokogiri::XML::Node)
          # TODO
        end
      end

      class Items
        attr_accessor :Items
        attr_accessor :TotalResults
        attr_accessor :TotalPages
        attr_accessor :MoreSearchResultsUrl

        def initialize(items)
          raise ParserError.new('Not a Node') unless items.is_a?(Nokogiri::XML::Node)
          @Items = items
          #@TotalResults = @Items.at('./xmlns:TotalResults').content.to_i
          #@TotalPages = @Items.at('./xmlns:TotalPages').content.to_i
          #@MoreSearchResultsUrl = @Items.at('./xmlns:MoreSearchResultsUrl').content
        end

        def to_a
          @List ||= (@Items / './xmlns:Item').inject([]) { |lst, itm| lst << Entry.new(itm) }
          @List
        end

        class Entry
          attr_accessor :Item
          attr_accessor :ASIN
          attr_accessor :ParentASIN
          attr_accessor :DetailPageURL
          attr_accessor :ItemLinks
          attr_accessor :ItemAttributes
          attr_accessor :OfferSummary
          attr_accessor :Offers
          def initialize(item)
            raise ParserError.new('Not a Node') unless item.is_a?(Nokogiri::XML::Node)
            @Item = item
            @ASIN = (n = @Item.at('./xmlns:ASIN')) && n.content
            @ParentASIN = (n = @Item.at('./xmlns:ParentASIN')) && n.content
            @DetailPageURL = (n = @Item.at('./xmlns:DetailPageURL')) && n.content
            @ItemLinks = (@Item / './xmlns:ItemLinks/xmlns:ItemLink').inject([]) { |lst, itm| lst << ItemLink.new(itm) }
            @ItemAttributes = (n = @Item.at('./xmlns:ItemAttributes')) && ItemAttributes.new(n)
            @OfferSummary = (n = @Item.at('./xmlns:OfferSummary')) && OfferSummary.new(n)
            @Offers = (n = @Item.at('./xmlns:Offers')) && Offers.new(n)
            @Reviews = (n = @Item.at('./xmlns:CustomerReviews')) && CustomerReviews.new(n)
            @BrowseNodes = (n = @Item.at('./xmlns:BrowseNode')) && BrowseNodes.new(n)
          end

          class ItemLink
            attr_accessor :ItemLink
            attr_accessor :Description
            attr_accessor :URL
            def initialize(item_link)
              @ItemLink = item_link
              @Description = (n = @ItemLink.at('./xmlns:Description')) && n.content
              @URL = (n = @ItemLink.at('./xmlns:URL')) && n.content
            end
          end

          class ItemAttributes
            attr_accessor :ItemAttributes
            attr_accessor :Brand
            attr_accessor :Manufacturer
            attr_accessor :Model
            attr_accessor :PartNumber
            attr_accessor :ProductGroup
            attr_accessor :Size
            attr_accessor :Title
            def initialize(item_attributes)
              @ItemAttributes = item_attributes
              @Brand = (n = @ItemAttributes.at('./xmlns:Brand')) && n.content
              @Manufacturer = (n = @ItemAttributes.at('./xmlns:Manufacturer')) && n.content
              @Model = (n = @ItemAttributes.at('./xmlns:Model')) && n.content
              @PartNumber = (n = @ItemAttributes.at('./xmlns:PartNumber')) && n.content
              @ProductGroup = (n = @ItemAttributes.at('./xmlns:ProductGroup')) && n.content
              @Size = (n = @ItemAttributes.at('./xmlns:Size')) && n.content
              @Title = (n = @ItemAttributes.at('./xmlns:Title')) && n.content
            end
          end

          class OfferSummary
            attr_accessor :OfferSummary
            attr_accessor :LowestNewPrice
            attr_accessor :LowestUsedPrice
            attr_accessor :LowestRefurbishedPrice
            attr_accessor :TotalNew
            attr_accessor :TotalUsed
            attr_accessor :TotalCollectible
            attr_accessor :TotalRefurbished
            def initialize(offer_summary)
              @OfferSummary = offer_summary
              @LowestNewPrice = (n = @OfferSummary.at('./xmlns:LowestNewPrice')) && Price.new(n)
              @LowestUsedPrice = (n = @OfferSummary.at('./xmlns:LowestUsedPrice')) && Price.new(n)
              @LowestRefurbishedPrice = (n = @OfferSummary.at('./xmlns:LowestRefurbishedPrice')) && Price.new(n)
              @TotalNew = (n = @OfferSummary.at('./xmlns:TotalNew')) && n.content.to_i
              @TotalUsed = (n = @OfferSummary.at('./xmlns:TotalUsed')) && n.content.to_i
              @TotalCollectible = (n = @OfferSummary.at('./xmlns:TotalCollectible')) && n.content.to_i
              @TotalRefurbished = (n = @OfferSummary.at('./xmlns:TotalRefurbished')) && n.content.to_i
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
            attr_accessor :BrowseNodeId
            attr_accessor :Name
            attr_accessor :Ancestors
            attr_accessor :Children
            def initialize(browse_node)
              raise ParserError.new('Not a Node') unless browse_node.is_a?(Nokogiri::XML::Node)
              @BrowseNode = browse_node
              @BrowseNodeId = (n = @BrowseNode.at('./xmlns:BrowseNodeId')) && n.content.to_i
              @Name = (n = @HasReviews.at('./xmlns:Name')) && n.content.to_i
              @Ancestors ||= (@BrowseNode / './xmlns:Ancestors').inject([]) { |lst, itm| lst << Ancestors.new(itm) }
              @Children ||= (@BrowseNode / './xmlns:Children').inject([]) { |lst, itm| lst << Children.new(itm) }
            end
          end

          class Ancestors
            attr_accessor :Ancestors
            attr_accessor :BrowseNode
            def initialize(ancestor)
              raise ParserError.new('Not a Node') unless ancestor.is_a?(Nokogiri::XML::Node)
              @Ancestors = ancestor
              @BrowseNode = (n = @Ancestors.at('./xmlns:BrowseNode')) && BrowseNode.new(n)
            end
          end

          class Children
            attr_accessor :Children
            attr_accessor :BrowseNode
            def initialize(ancestor)
              raise ParserError.new('Not a Node') unless ancestor.is_a?(Nokogiri::XML::Node)
              @Children = ancestor
              @BrowseNode = (n = @Ancestors.at('./xmlns:BrowseNode')) && BrowseNode.new(n)
            end
          end

          class CustomerReviews
            attr_accessor :CustomerReviews
            attr_accessor :IFrameURL
            attr_accessor :HasReviews

            def initialize(customer_reviews)
              raise ParserError.new('Not a Node') unless customer_reviews.is_a?(Nokogiri::XML::Node)
              @CustomerReviews = customer_reviews
              @IFrameURL = (n = @CustomerReviews.at('./xmlns:IFrameURL')) && n.content.to_i
              @HasReviews = (n = @HasReviews.at('./xmlns:HasReviews')) && n.content.to_i
            end
          end

          class Offers
            attr_accessor :Offers
            def initialize(offers)
              raise ParserError.new('Not a Node') unless offers.is_a?(Nokogiri::XML::Node)
              @Offers = offers
            end

            def to_a
              @List ||= (@Offers / './xmlns:Offer').inject([]) { |lst, itm| lst << Offer.new(itm) }
              @List
            end
          end

          class Offer
            def initialize(offer)
              raise ParserError.new('Not a Node') unless offer.is_a?(Nokogiri::XML::Node)
              @Offer = offer
              # TODO
            end
          end

          class Price
            attr_accessor :Price
            attr_accessor :Amount
            attr_accessor :CurrencyCode
            attr_accessor :FormattedPrice
            def initialize(price)
              raise ParserError.new('Not a Node') unless price.is_a?(Nokogiri::XML::Node)
              @Price = price
              @Amount = (n = @Price.at('./xmlns:Amount')) && n.content.to_i
              @CurrencyCode = (n = @Price.at('./xmlns:CurrencyCode')) && n.content.to_sym
              @FormattedPrice = (n = @Price.at('./xmlns:FormattedPrice')) && n.content
            end
          end
        end
      end

    end
  end
end
