class User < ActiveRecord::Base
  has_many :rates, foreign_key: "UserID"
  validates :uid, presence: true
  validates :name, presence: true
  validates :oauth_token, presence: true
  validates :provider, presence: true
  validate :provder_as_facebook_only
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
	    user.provider = auth.provider 
	    user.uid      = auth.uid
	    user.name     = auth.info.name
	    user.oauth_token = auth.credentials.token
	    user.oauth_expires_at = Time.at(auth.credentials.expires_at)
	    user.save!
	end
  end

  def provder_as_facebook_only
  	if(self.provider != "facebook")
  		errors.add(:provider, "Only facebook can be a provider")
  	end
  end
end
