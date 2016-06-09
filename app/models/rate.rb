class Rate < ActiveRecord::Base
	belongs_to :user, foreign_key: "UserID"
	belongs_to :restaurant, foreign_key: "RestaurantID"
	validates_inclusion_of :Rate, :in => 1..10
	establish_connection :default
	self.table_name = "Rates"

	def self.get_most_common_rated_restaurants
      Rate.all.group(:RestaurantID).order('count_Rate desc').count(:Rate)
    end
end