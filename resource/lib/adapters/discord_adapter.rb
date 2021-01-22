# coding: utf-8
# frozen_string_literal: true
# sending messages to discord: https://discord.com/developers/docs/resources/channel#create-message
# executing discord webhook: https://discord.com/developers/docs/resources/webhook#execute-webhook
# helpful gist: https://gist.github.com/jagrosh/5b1761213e33fc5b54ec7f6379034a22
# formatting: https://gist.github.com/Birdie0/78ee79402a4301b1faf412ab5f1cdcf9
module DiscordAdapter
  def self.post(url, message)
    if message[0] == "{"
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json")
      request.body = message
      http.request(request)
    else
      Net::HTTP.post_form(URI(url), "content" => message)
    end
  end

  def self.status_message_for(status)
    {
      embeds: [
        {
          title: "$BUILD_PIPELINE_NAME/$BUILD_JOB_NAME/$BUILD_NAME",
          description: "**Build #{status.capitalize}**",
          url: "${BUILD_URL}",
          thumbnail: { url: "https://ci.nokogiri.org/public/images/favicon-#{status}.png" }
        },
      ],
    }.to_json
  end
end
