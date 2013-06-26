class Rumblelog
  module Views
    class Status < Layout
      def connection?
        !!Fauna.connection
      end
    end
  end
end
