class Rumblelog
  module Views
    class Index < Layout
      def pages
        @pages
      end

      def title
        @title
      end

      def subtitle
        @subtitle
      end
    end
  end
end
