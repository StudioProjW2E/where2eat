class RatesController < ApplicationController
	before_action :set_restaurant, only: [:create,:update]
	def create
		@rate = @restaurant.rate.new(rate_params)
		if @note.save
			redirect_to restaurants_index_path
		else
			redirect_to restaurants_index_path, alert:"Unable to add Rate"
		end
	end

	def update
		@rate = @restaurant.rate.new(rate_params)
		if @rate.update
			redirect_to restaurants_index_path
		else
			redirect_to restaurants_index_path, alert:"Unable to update Rate"
		end
	end
	private
		def set_restaurant
			@restaurant = Restaurant.find(params[:restaurant_id])
		end

		def rate_params
			params.require(:rate).permit(:Rate,:Comment)
		end
end
