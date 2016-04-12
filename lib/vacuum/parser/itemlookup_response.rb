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
        OperationRequest.new(@Document.at('/xmlns:ItemLookupResponse/xmlns:OperationRequest'))
      end

      def isValid?
        (n = @Document.at('/xmlns:ItemLookupResponse/xmlns:Items/xmlns:Request/xmlns:IsValid')) &&
            (n.content == 'True')
      end

      def request
        @Document.at('/xmlns:ItemLookupResponse/xmlns:Items/xmlns:Request/xmlns:ItemLookupRequest')
      end

      def error
        error = @Document.at('/xmlns:ItemLookupResponse/xmlns:Items/xmlns:Request/xmlns:Errors/xmlns:Error')
        error.content if error
      end

      def items
        return nil unless isValid?
        @Items ||= Items.new(@Document.at('/xmlns:ItemLookupResponse/xmlns:Items'))
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
        attr_accessor :error

        def initialize(items)
          raise ParserError.new('Not a Node') unless items.is_a?(Nokogiri::XML::Node)
          @Items = items
          #@TotalResults = @Items.at('./xmlns:TotalResults').content.to_i
          @error = @Items.at('./xmlns:Request/xmlns:Errors/xmlns:Error').present? ? true : false
          #@TotalPages = @Items.at('./xmlns:TotalPages').content.to_i
          #@MoreSearchResultsUrl = @Items.at('./xmlns:MoreSearchResultsUrl').content
        end

        def to_a
          @List ||= (@Items / './xmlns:Item').inject([]) { |lst, itm| lst << Entry.new(itm) }
          @List
        end

        class Entry
          attr_accessor :Item
          attr_accessor :asin
          attr_accessor :parent_asin
          attr_accessor :detail_page_url
          attr_accessor :item_links
          attr_accessor :item_attributes
          attr_accessor :offer_summary
          attr_accessor :offers
          attr_accessor :browse_nodes
          attr_accessor :customer_reviews
          attr_accessor :sales_rank
          attr_accessor :list
          attr_accessor :large_image

          def initialize(item)
            raise ParserError.new('Not a Node') unless item.is_a?(Nokogiri::XML::Node)
            @Item = item
            @asin = (n = @Item.at('./xmlns:ASIN')) && n.content
            @parent_asin = (n = @Item.at('./xmlns:ParentASIN')) && n.content
            @detail_page_url = (n = @Item.at('./xmlns:DetailPageURL')) && n.content
            @sales_rank = (n = @Item.at('./xmlns:SalesRank')) && n.content
            @item_links = (@Item / './xmlns:ItemLinks/xmlns:ItemLink').inject([]) { |lst, itm| lst << ItemLink.new(itm) }
            @item_attributes = (n = @Item.at('./xmlns:ItemAttributes')) && ItemAttributes.new(n)
            @offer_summary = (n = @Item.at('./xmlns:OfferSummary')) && OfferSummary.new(n)
            @offers = (n = @Item.at('./xmlns:Offers')) && Offers.new(n)
            @customer_reviews = (n = @Item.at('./xmlns:CustomerReviews')) && CustomerReviews.new(n)
            @browse_nodes = (n = @Item.at('./xmlns:BrowseNodes')) && BrowseNodes.new(n)
            @list = (n = @Item.at('./xmlns:List')) && List.new(n)
            @large_image = (n = @Item.at('./xmlns:LargeImage//xmlns:URL')) && n.content
          end

          class List
            attr_accessor :List
            attr_accessor :date_created

            def initialize(item)
              @List = item
              @date_created = (n = @List.at('./xmlns:DateCreated')) && n.content
            end
          end

          class ItemLink
            attr_accessor :ItemLink
            attr_accessor :description
            attr_accessor :url
            def initialize(item_link)
              @ItemLink = item_link
              @description = (n = @ItemLink.at('./xmlns:Description')) && n.content
              @url = (n = @ItemLink.at('./xmlns:URL')) && n.content
            end
          end

          class ItemAttributes
            attr_accessor :ItemAttributes
            attr_accessor :brand
            attr_accessor :manufacturer
            attr_accessor :model
            attr_accessor :part_number
            attr_accessor :product_group
            attr_accessor :size
            attr_accessor :title
            attr_accessor :upc
            attr_accessor :item_dimensions
            attr_accessor :list_price

            def initialize(item_attributes)
              @ItemAttributes = item_attributes
              @brand = (n = @ItemAttributes.at('./xmlns:Brand')) && n.content
              @manufacturer = (n = @ItemAttributes.at('./xmlns:Manufacturer')) && n.content
              @model = (n = @ItemAttributes.at('./xmlns:Model')) && n.content
              @part_number = (n = @ItemAttributes.at('./xmlns:PartNumber')) && n.content
              @product_group = (n = @ItemAttributes.at('./xmlns:ProductGroup')) && n.content
              @size = (n = @ItemAttributes.at('./xmlns:Size')) && n.content
              @title = (n = @ItemAttributes.at('./xmlns:Title')) && n.content
              @upc = (n = @ItemAttributes.at('./xmlns:UPC')) && n.content
              @list_price = (n = @ItemAttributes.at('./xmlns:ListPrice/xmlns:Amount')) && n.content
              @item_dimensions = (n = @ItemAttributes.at('./xmlns:ItemDimensions')) && ItemDimensions.new(n)
            end

            class ItemDimensions
              attr_accessor :ItemDimensions, :height, :weight, :width, :length, :units
              def initialize(item)
                @ItemDimensions = item
                @height = dimension(@ItemDimensions.at('./xmlns:Height'))
                @length = dimension(@ItemDimensions.at('./xmlns:Length'))
                @width = dimension(@ItemDimensions.at('./xmlns:Width'))
                @weight = dimension(@ItemDimensions.at('./xmlns:Weight'))
              end

              def dimension(dim)
                amount = dim.content
                units = dim.attribute('Units').content
                if units == "hundredths-inches" || units == "hundredths-pounds"
                  amount.to_i / 100.0
                else
                  amount.to_i / 1.0
                end
              end
            end
          end

          class OfferSummary
            attr_accessor :OfferSummary
            attr_accessor :lowest_new_price
            attr_accessor :lowest_used_price
            attr_accessor :lowest_refurbished_price
            attr_accessor :total_new
            attr_accessor :total_used
            attr_accessor :total_collectible
            attr_accessor :total_refurbished
            def initialize(offer_summary)
              @OfferSummary = offer_summary
              @lowest_new_price = (n = @OfferSummary.at('./xmlns:LowestNewPrice')) && Price.new(n)
              @lowest_used_price = (n = @OfferSummary.at('./xmlns:LowestUsedPrice')) && Price.new(n)
              @lowest_refurbished_price = (n = @OfferSummary.at('./xmlns:LowestRefurbishedPrice')) && Price.new(n)
              @total_new = (n = @OfferSummary.at('./xmlns:TotalNew')) && n.content.to_i
              @total_used = (n = @OfferSummary.at('./xmlns:TotalUsed')) && n.content.to_i
              @total_collectible = (n = @OfferSummary.at('./xmlns:TotalCollectible')) && n.content.to_i
              @total_refurbished = (n = @OfferSummary.at('./xmlns:TotalRefurbished')) && n.content.to_i
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

          class CustomerReviews
            attr_accessor :CustomerReviews
            attr_accessor :i_frame_url
            attr_accessor :has_reviews

            def initialize(customer_reviews)
              raise ParserError.new('Not a Node') unless customer_reviews.is_a?(Nokogiri::XML::Node)
              @CustomerReviews = customer_reviews
              @i_frame_url = (n = @CustomerReviews.at('./xmlns:IFrameURL')) && n.content.to_s
              @has_reviews = (n = @CustomerReviews.at('./xmlns:HasReviews')) && n.content.to_s
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
            attr_accessor :price
            attr_accessor :amount
            attr_accessor :currency_code
            attr_accessor :formatted_price
            def initialize(price)
              raise ParserError.new('Not a Node') unless price.is_a?(Nokogiri::XML::Node)
              @price = price
              @amount = (n = @price.at('./xmlns:Amount')) && n.content.to_i
              @currency_code = (n = @price.at('./xmlns:CurrencyCode')) && n.content.to_sym
              @formatted_price = (n = @price.at('./xmlns:FormattedPrice')) && n.content
            end
          end
        end
      end

    end
  end
end
