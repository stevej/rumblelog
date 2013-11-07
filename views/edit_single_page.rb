class Rumblelog
  module Views
    class EditSinglePage < Layout
      def pages
        @pages
      end

      def rawtags
        @pages[0].tags.join(", ")
      end

      def body
        @pages[0].body
      end
    end
  end
end
