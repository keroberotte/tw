
module Tw
  class Client::Stream
    def initialize(user=nil)
      user = Tw::Auth.get_or_regist_user user
      UserStream.configure do |config|
        config.consumer_key = Conf['consumer_key']
        config.consumer_secret = Conf['consumer_secret']
        config.oauth_token = user['access_token']
        config.oauth_token_secret = user['access_secret']
      end

      @client = UserStream::Client.new
    end

    def user_stream(&block)
      raise ArgumentError, 'block not given' unless block_given?
      @client.user do |m|
        if data = tweet?(m)
          yield data
	elsif data = faved?(m)
          yield data
        end
      end
    end

    def filter(*track_words, &block)
      raise ArgumentError, 'block not given' unless block_given?
      @client.filter :track => track_words.join(',') do |m|
        if data = tweet?(m)
          yield data
        end
      end
    end

    private
    def tweet?(chunk)
      return false unless chunk.user and chunk.user.screen_name and chunk.text and chunk.created_at and chunk.id
      Tw::Tweet.new(:id => chunk.id,
                    :user => chunk.user.screen_name,
                    :text => chunk.text,
                    :time => (Time.parse chunk.created_at))
    end

    # 相互から自分と、自分から相互への通知しか取れないっぽい
    # 通知専用のdisplayメソッドを作りたい
    def faved?(chunk)
      return false unless chunk.target_object and chunk.target_object.id and chunk.event and chunk.event == "favorite"
      Tw::Tweet.new(:id => chunk.target_object.id,
                    :user => chunk.target.screen_name,
                    :text => chunk.target_object.text + " favorited by @" + chunk.source.screen_name,
                    :time => (Time.parse chunk.created_at))
    end

  end
end
