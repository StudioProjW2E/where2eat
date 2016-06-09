require 'test_helper'

class RestaurantsControllerTest < ActionController::TestCase
  test "should get index" do
    get(:index,{'user_id'=>1})
    assert_redirected_to home_show_path
  end

  test "should get show" do
    get :show
    assert_redirected_to home_show_path
  end
  test "sould get add rate" do
  	get :add_rate
  	# assert_template layout:"index/_listing"
  	assert_redirected_to home_show_path
  end

end
