require 'nokogiri'
require 'net/http'
require 'dm-core'
require 'dm-migrations'

class Prediction
  include DataMapper::Resource
  property :id, Serial
  belongs_to :snapshot
  property :minutes, Integer
end

class Snapshot
  include DataMapper::Resource
  property :id, Serial
  has n, :predictions
  property :created_at, DateTime
end

def username
  p YAML.load_file("config.yml")
  YAML.load_file("config.yml")[:username]
end

def password
  YAML.load_file("config.yml")[:password]
end

DataMapper.setup(:default, {adapter: 'postgres', host: 'localhost', database: 'buses', username: username, password: password})
DataMapper.finalize

DataMapper.auto_upgrade!

raw = Net::HTTP.get(URI("http://www.ctabustracker.com/bustime/map/getStopPredictions.jsp?eta=true&route=all&stop=1327"))

prediction_times = Nokogiri.parse(raw).css("stop pre pt").map do |node|
  node.children.first.text.to_i
end

Snapshot.create(
  created_at: Time.now,
  predictions: prediction_times.map {|t| Prediction.new(minutes: t)}
)
