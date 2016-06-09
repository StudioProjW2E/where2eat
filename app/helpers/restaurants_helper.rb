module RestaurantsHelper
	def url_with_protocol(url)
		/^http/i.match(url) ? url : "http://#{url}"
	end
	def get_restaurant_avg_rate(id)
		Restaurant.all.find_by(:RestaurantID=>id).rates.average(:Rate)
	end
end