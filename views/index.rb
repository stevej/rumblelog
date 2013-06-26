class Rumblelog
  module Views
    class Index < Layout
      def pages
        @pages
      end

      def content
        "Not a blog. c'mon guys."
      end
    end
  end
end
