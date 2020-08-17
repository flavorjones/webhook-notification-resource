module GitterActivityFeedAdapter
  def self.post(url, message)
    Net::HTTP.post_form(URI(url), "message" => message)
  end
end
