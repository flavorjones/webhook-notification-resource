# sending messages to discord: https://discord.com/developers/docs/resources/channel#create-message
# executing discord webhook: https://discord.com/developers/docs/resources/webhook#execute-webhook
# helpful gist: https://gist.github.com/jagrosh/5b1761213e33fc5b54ec7f6379034a22
module DiscordAdapter
  def self.post(url, message)
    Net::HTTP.post_form(URI(url), "content" => message)
  end
end
