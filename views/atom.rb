class Rumblelog
  module Views
    class Atom < Mustache
      def pages
        @pages
      end

      def title
        @title
      end

      def subtitle
        @subtitle
      end

      def full_url
        @full_url_prefix
      end

      def last_updated
        if @pages.empty?
          Time.now.to_i
        else
          @pages[0].ts_for_atom
        end
      end
    end
  end
end
