module MockTeapotAdapter
  def self.post(url, message)
    Net::HTTPOK.new("1.1", 418, "I'm a teapot and you never actually sent a message")
  end
end
