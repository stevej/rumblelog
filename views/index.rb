class Rumblelog
  module Views
    class Index < Layout
      def pages
        @pages
      end

      def content
        "An example blog powered by the fauna cloud database."
      end
    end
  end
end
