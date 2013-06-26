class Rumblelog
  module Views
    class Create < Layout
      # Generate's a fresh page URL to be overwritten by the user.
      def fresh_page_url
        Time.now.to_i
      end
    end
  end
end
