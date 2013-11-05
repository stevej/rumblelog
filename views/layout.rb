class Rumblelog
  module Views
    class Layout < Mustache
      def title
        @title
      end

      def subtitle
        @subtitle
      end
    end
  end
end
