class Maintainer::DeploymentItem

  include DataMapper::Resource
  
  property :id,       Serial
  property :sha,      String,   :nullable => false, :length => 40
  property :message,  Text,     :nullable => false
  property :time,     DateTime, :nullable => false
  
end
