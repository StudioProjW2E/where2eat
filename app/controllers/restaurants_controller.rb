class RestaurantsController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  include ApplicationHelper
  before_action :set_restaurant, only:[:show,:edit]
  helper :restaurants
  helper :application
  helper SmartListing::Helper

  def index
    @UserID = current_user.id

    # Counters for recommender, sun must equal 1.0
    @category_counter = 0.1
    @popularity_counter = 0.4
    @average_rates_counter = 0.5

    @restaurants_avg_rates = set_avg_rates
    @already_rated = find_already_rated
    @restaurants = create_smart_list
    @recomendations = recommendation_system
  end
  
  # main evaluation method, check /restaurants/evaluation 
  def evaluation
    @UserID = current_user.id
    # Counters for recommender, sun must equal 1.0
    @category_counter = 0.1
    @popularity_counter = 0.4
    @average_rates_counter = 0.5

    # global helpers
    @restaurants_avg_rates = set_avg_rates
    @already_rated = find_already_rated
    @category_listing = recommendation_system
    evaluation = evaluate_recommender_data
    
    #sorting attribute
    sort_by_attr = params[:sort]
    
    # hash of restaurants data, used in view, table
    @restaurants = evaluation_restaurants_data.sort_by{|a| a[sort_by_attr].nil? ? 0 : a[sort_by_attr]}.reverse

    # average evaluation for all rated restaurants
    @avg_evaluation = (evaluation.inject(0) {|sum,e| sum+e[1]} / evaluation.inject(0) {|sum,e| e[1] != 0 ? sum+1 : sum}).round(4)
    
    # allows dynamic sorting with js
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @already_rated = find_already_rated
    create_marker_data
  end

  def edit
    
  end

  # dynamic rate addition
  def add_rate
    rate_to_be_added = params[:rate_data].to_i
    @restaurant_id = params[:rest_id]
    add_rate_helper(rate_to_be_added,@restaurant_id)  
    respond_to do |format|
      format.js
    end
    # redirect_to :back
  end

  private
  	# Use callbacks to share common setup or constraints between actions.
  	def set_restaurant
  	 @restaurant = Restaurant.find(params[:id])
  	end
  	# Never trust parameters from the scary internet, only allow the white list through.
  	def restaurant_params
  	  params.require(:restaurant).permit(:name, :description, :address, :link_to_web, :x, :y, :link_to_photo)
    end

    def set_avg_rates
      Restaurant.joins("LEFT OUTER JOIN Rates USING(RestaurantID)").group('Restaurants.RestaurantID').average(:Rate)
    end

    # creating restaurants list for index
    def create_smart_list
     smart_listing_create(:restaurants,Restaurant.joins("LEFT OUTER JOIN Rates USING(RestaurantID)")
      .group('Restaurants.RestaurantID')
      .search(params[:search])
      .categorize(params[:categories]),
        partial: "restaurants/listing",
        # sort_attributes: [
        #   [:name, 'Name'],
        #   [:address,'Address'],
        #   [:average_sort,"avg(Rate)"]
        # ],
        # default_sort: {average_sort: "desc"}
      )
    end

    def url_with_protocol(url)
      /^http/i.match(url) ? url : "http://#{url}"
    end

    # creating marker for show method, google maps api
    def create_marker_data
      if @restaurant.Latitude!=0
        @hash_restaurant_data = Gmaps4rails.build_markers(@restaurant) do |rest,marker|
          marker.lat rest.Latitude
          marker.lng rest.Longitude
          # marker.picture [url:"where2eat_marker.png",width:32,height:32]
          if rest.Link!=""
            marker.infowindow "<a href=#{url_with_protocol(rest.Link)}>#{rest.Name}</a><br>#{rest.Address}"
          else
            marker.infowindow "#{rest.Name}<br>#{rest.Address}"
          end
        end
      else
        @hash_restaurant_data = nil
      end
    end

    # Find already rated restaurants by current_user.id
    def find_already_rated
      tmp_rated = Restaurant.joins(:rates).where('Rates.UserID' => @UserID).group('Restaurants.RestaurantID').pluck(:RestaurantID,:Rate)
      find_already_rated = {}
      Restaurant.all.each do |rest|
        find_already_rated[rest.id] = 0
      end
      unless tmp_rated.size == 0
        tmp_rated.each do |rest_rate|
          find_already_rated[rest_rate[0]] = rest_rate[1].round(2)
        end
      end
      find_already_rated
    end

    # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    # XXXXXXXXXXXXXXXXXXXXXXXXXXX RECOMENDATION STUFF XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

    # main recommendation method, joining all others
    def recommendation_system
      restaurants_popularity = get_popularity_score
      restaurants_categories = get_categories_score
      restaurants_average_ratings = get_average_rates_score
      recommendation_array = {}
      Restaurant.all.each do |rest|
        id = rest.id
        recommendation_array[id] ||= {}
        recommendation_array[id][:popularity] = restaurants_popularity[id].nil? ? 0 : restaurants_popularity[id]
        recommendation_array[id][:categories] = restaurants_categories[id]
        recommendation_array[id][:average_rates_score] = restaurants_average_ratings[id]
        recommendation_array[id][:sum] = (recommendation_array[id][:popularity].to_f * @popularity_counter +
         (recommendation_array[id][:average_rates_score].to_f * @average_rates_counter) +
         recommendation_array[id][:categories] * @category_counter ).round(2)
        
        # restaurant_recomendation_array.sum * 100
        # (restaurants_popularity[id] * 0.3 + restaurant_recomendation_array.sum * 100 *0.2 + @restaurants_avg_rates[id]*10*0.5).to_i.to_s+"%"
      end
      recommendation_array
    end
    
    # % of average rates
    def get_average_rates_score
      restaurants_average_ratings = {}
      @restaurants_avg_rates.each do |id,rate|
        if !rate.nil?
          restaurants_average_ratings[id] = (rate*10).round(2)
        else
          restaurants_average_ratings[id] = 0
        end
      end
      restaurants_average_ratings
    end

    # Recommender score for user's favorite categories multiplied by restaurant categories
    def get_categories_score
      user_favorite_categories = get_current_user_categories_normalized_array
      restaurant_categories = {}
      get_restaurants_categories_array.each do |id,restaurant_categories_array|
        if restaurant_categories_array.sum == 0 
          restaurant_categories[id] = 0
        else
          amount_of_ones = restaurant_categories_array.sum
          restaurant_recomendation_array = Array.new(user_favorite_categories.size) { 0 }
          restaurant_categories_array.each_with_index do |restaurant_category,i|
            restaurant_recomendation_array[i] = restaurant_category * user_favorite_categories[i]
          end
          restaurant_categories[id] = (restaurant_recomendation_array.sum/amount_of_ones).to_i
        end
      end
      restaurant_categories
    end

    # defines recommendation by popularity of restaurant, depending also on rating
    def get_popularity_score
      most_common_rated_hash = get_most_common_rated_restaurants
      max_amount = most_common_rated_hash.first[1] # gives 100%
      min_amount = most_common_rated_hash.to_a.last[1] # gives 0%
      divider = (5.0 / 10.0) # above this rate popularity score gets incremented, else decremented
      step_amount = (100/max_amount) # step_amount -> how many % gives 1 rate for restaurant divided by divider
      step_amount_down = step_amount * (divider)
      step_amount_up = step_amount * (1 - divider)
      popularity_score = {}

      # starting with 1-divider % popularity, goes down for low rating, goes up for good one
      most_common_rated_hash.each do |rest_id,amount|
        popularity_score[rest_id] = 100 * divider
        
        if @restaurants_avg_rates[rest_id] > ((divider)*10)
         
          popularity_score[rest_id] = popularity_score[rest_id] + (step_amount_up*amount).round(2)
        else
         
          popularity_score[rest_id] = popularity_score[rest_id] - (step_amount_down*amount).round(2)
        end
        
      end
      popularity_score
    end

    # counting rates for each restaurant, ordered by count, grouped by restaurant id
    def get_most_common_rated_restaurants
      Rate.all.group(:RestaurantID).order('count_Rate desc').count(:Rate)
    end
    
    # Not used right now
    # Matrix of restaurants x users, including rates
    def get_restaurants_x_users_rating_hash
      # rating array
      # RestaurantID x UserID = Rate
      restaurants = Restaurant.all
      users = User.all
      rates = Rate.all.pluck(:RestaurantID,:UserID,:rate)
      max_users_id = users.maximum(:id) 
      ratingHash = Array.new(restaurants.maximum(:RestaurantID)) {Array.new(max_users_id) { 0 }}
      rates.each do |rate|
        ratingHash[rate[0]][rate[1]] = rate[2] unless rate[2].nil?
      end
    end

    # What current user likes
    def get_current_user_categories_normalized_array
      categories = get_categories
      user_likes_categories = Array.new(categories.size) { 0 }
      #szuka najczesciej wystepujacych kategorii w ocenionych restauracjach
      Restaurant.joins(:rates).where('Rates.UserID' => @UserID).group('Restaurants.RestaurantID').each do |rest|
        categories.each_with_index do |category,cat_id|
          if rest.Description.include? category
            user_likes_categories[cat_id] = user_likes_categories[cat_id] + 1
          end
        end
      end
      if user_likes_categories.sum != 0
        sorted = user_likes_categories.sort.reverse
        divider = 100/sorted.first
        return_array = []
        sorted.each_with_index do |e,i|
          return_array[i] = e * divider
        end
        return_array
      else
        user_likes_categories
      end
   end

    # Arrays of categories ids from all restaurants
    def get_restaurants_categories_array
      categories = get_categories
      restaurant_categories = {}
      restaurants = Restaurant.all.pluck(:RestaurantID,:Description)
      restaurants.each do |rest|
        restaurant_categories[rest[0]] = Array.new(categories.size) { 0 }  
          categories.each_with_index do |category,cat_id|
          if rest[1].downcase.include? category        
            restaurant_categories[rest[0]][cat_id] = 1
          end
        end
      end
      restaurant_categories
    end

    # Normalization of array
    def normalize(arr)
      avg = arr.sum.to_f/arr.size.to_f #suma wystapien wszystkich kat/ ilosc występujących kat
      ret_arr = Array.new(arr.size){0}
      arr.each_with_index do |a,i|
        ret_arr[i]=a*avg/arr.sum  #ilosc wystapien danej kat * srednia / sume wystapien wszystkich kat ??po co * srednia
      end
      ret_arr
    end

    # EVALUATION
    def evaluate_recommender_data
      evaluate_recommender_array = {}
      @category_listing.each do |k,rest|
        evaluate_recommender_array[k] = 0.0
      end
      @already_rated.each do |id,rate|
        if rate != 0
          evaluate_recommender_array[id] = ((rate * 10 - @category_listing[id][:sum]).abs / (rate * 10) * 100).round(2) #cat_list to zwrotka z rekomendacji cala tablica
        end
      end
      evaluate_recommender_array
    end

    # Converting SQL ActiveRecord data into hashes
    def evaluation_restaurants_data
      restaurants = Restaurant.joins("LEFT OUTER JOIN Rates USING(RestaurantID)")
        .group('Restaurants.RestaurantID')
        .search(params[:search])
        .categorize(params[:categories])
        .to_a.map(&:serializable_hash)  
      evaluation = evaluate_recommender_data
      restaurants.each do |rest|
        rest["category"] = @category_listing[rest["RestaurantID"]][:categories]
        rest["popularity"] = @category_listing[rest["RestaurantID"]][:popularity]
        rest["average_rates_score"] = @category_listing[rest["RestaurantID"]][:average_rates_score]
        rest["average_rates"] = @restaurants_avg_rates[rest["RestaurantID"]]
        rest["already_rated"] = @already_rated[rest["RestaurantID"]]
        rest["recommendation_sum"] = @category_listing[rest["RestaurantID"]][:sum]
        rest["evaluation"] = evaluation[rest["RestaurantID"]]
    restaurants
    end
  end
end