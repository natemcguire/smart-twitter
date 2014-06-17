# A smart way to use twitter for business
require 'rubygems'
require 'twitter'
require 'yaml'

# set up the twitter configuration
twittercred = YAML.load_file(File.expand_path('twitter.yml'))
 
user = Twitter.configure do |config|
  config.consumer_key = twittercred['consumer_key']
  config.consumer_secret = twittercred['consumer_secret']
  config.oauth_token = twittercred['oauth_token']
  config.oauth_token_secret = twittercred['oauth_token_secret']
end

# get our followers to use later
@my_followers = user.follower_ids.ids
@my_friends = user.friend_ids.ids

puts 'What do you want to do?'
puts '1. Follow or favorite tweets based on a specific user'
puts '2. Favorite people\'s tweets based on a specific query'

# get the first input to start the query
$stdout.flush
@step1 = gets

def select_action
  case @step1.strip
  when "1"
    query_user
  when "2"
    query_tweets
  else
    puts "Sorry, that is not acceptable input, try again."
    exit
  end
end

# Find people to follow based on other twitter users
def query_user
  puts 'First, pick one:'
  puts '1. Get a user\'s followers'
  puts '2. Get a user\'s friends'
  step2 = gets
  case step2.strip
  when "1"
    find_followers
    @unique_user_ids = @followers - @my_friends
    puts "There are #{@unique_user_ids.size} unique users that you don't follow"
    follow_or_favorite
  when "2"
    find_friends
    @unique_user_ids = @friends - @my_friends
    puts "There are #{@unique_user_ids.size} unique users that you don't follow"
    follow_or_favorite
  else
    puts "Sorry, that is not acceptable input, try again."
    $stdout.flush
    step1 = gets
    query_user
  end
end

# decide whether to follow users or favorite their tweets
def follow_or_favorite
  puts "What do you want to do next?"
  puts "1. Follow these users"
  puts "2. Favorite their last tweet"
  @follow_or_favorite = gets
  case @follow_or_favorite.strip
  when "1"
    follow_users
  when "2"
    favorite_user_tweets
  else
    puts "Sorry, that is not acceptable input, try again."
    exit
  end
end

# Query tweets
def query_tweets
  puts 'Let\'s find some tweets to favorite. Enter a query:'
  @query = gets
  @tweets = Twitter.search(@query).statuses
  favorite_tweets
end

# find the followers for another user
def find_followers
  puts 'Enter the other user\'s twitter handle'
  @other_user = gets
  @followers = Twitter.follower_ids(@other_user).ids
end

# find the friends for another user
def find_friends
  puts 'Enter the other user\'s twitter handle'
  @other_user = gets
  @friends = Twitter.friend_ids(@other_user).ids
end

# follow the users you have selected
def follow_users
  puts "Are you sure you want to follow ALL of the unique users of #{@other_user.strip}? Y/N"
  @decision = gets

  case @decision.strip
  when "Y"
    @unique_user_ids.each do |followerId|
        begin
        Twitter.follow(followerId)
      rescue Twitter::Error::TooManyRequests => error
          puts "Oops, we are rate limited. We will try again at: #{Time.now + error.rate_limit.reset_in + 5}"
          sleep error.rate_limit.reset_in + 5
          retry
      rescue Twitter::Error::ServiceUnavailable => error
        sleep(10)
        retry
      else 
        puts ">>> followed followerID #{followerId}"
      end
      sleep(1)
    end
  when "N"
    puts "Ok, well that was a waste of time."
  else
    puts "Something went wrong here. Start over."
  end
end

# favorite the tweets from the query
def favorite_tweets
  puts "Do you want to favorite all of the tweets from the query? The query '#{@query.strip}' has #{@tweets.size} tweets. Y/N"
  @decision = gets
  @tweets.each do |tweet|
    begin
      Twitter.favorite(tweet.id)
    rescue Twitter::Error::TooManyRequests => error
        puts "Oops, we are rate limited. We will try again at: #{Time.now + error.rate_limit.reset_in + 5}"
        sleep error.rate_limit.reset_in + 5
        retry
    rescue Twitter::Error::ServiceUnavailable => error
      sleep(10)
      retry
    rescue Twitter::Error::Forbidden => error
      puts "You already favorited tweet from #{tweet.user.screen_name}"
      next
    else
      puts "Favorited '#{tweet.text}' from #{tweet.user.screen_name}"
    end
    sleep(1)
  end
end

# Favorite the most recent tweet of a user
def favorite_user_tweets
  puts "Are you sure you want to favorite the most recent tweet of ALL of the unique users of #{@other_user.strip}? Y/N"
  @decision = gets

  case @decision.strip
  when "Y"
    @unique_user_ids.each do |followerId|
        begin
        @favorite_user = Twitter.user(followerId)
        if @favorite_user.status.nil?
          puts "Blank status for #{@favorite_user.screen_name}"
          next
        else
          Twitter.favorite(@favorite_user.status.id)
        end
      rescue Twitter::Error::TooManyRequests => error
          puts "Oops, we are rate limited. We will try again at: #{Time.now + error.rate_limit.reset_in + 5}"
          sleep error.rate_limit.reset_in + 5
          retry
      rescue Twitter::Error::ServiceUnavailable => error
        sleep(10)
        retry
      rescue Twitter::Error::Forbidden => error
        puts "You already favorited tweet from #{@favorite_user.screen_name}"
        next
      else
        puts ">>> Favorited last tweet of #{@favorite_user.screen_name}."
      end
      sleep(1)
    end
  when "N"
    puts "Ok, well that was a waste of time."
  else
    puts "Something went wrong here. Start over."
  end

end

select_action