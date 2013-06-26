class Rumblelog
  module Views
    class Layout < Mustache
      def title
        @title || "Rumblelog"
      end
    end
  end
end
