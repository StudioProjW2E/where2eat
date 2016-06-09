class Restaurant < ActiveRecord::Base
	extend ActiveSupport::Concern
	has_many :rates, foreign_key: "RestaurantID"
	has_many :users, :through => :rates, foreign_key: "RestaurantID"
	establish_connection :default
	self.table_name = "Restaurants"
	# scope :active, ->{ order('RestaurantID desc') }

	def self.search(search)
		if search
			where('Name LIKE ?',"%#{search}%")
		else
			all
		end
	end
	def self.categorize(categories)
		if categories
			categories_arr = categories.map{|val| "#{val}"}.join("|")
			where('Description REGEXP ?',categories_arr)
		else
			all
		end
	end
	
	def avg_rate
		rates.average(:Rate)
	end
end