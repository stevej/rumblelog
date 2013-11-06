class Rumblelog
  module Views
    class EditSinglePage < Layout
      def page
        @page
      end

      def rawtags
        @page[0].tags.join(", ")
      end

      def body
        @page[0].body
      end
    end
  end
end
