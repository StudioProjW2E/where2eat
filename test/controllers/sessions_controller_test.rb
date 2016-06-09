require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  test "should get create" do
    get :create
    assert_redirected_to restaurants_index_path
  end

  test "should get destroy" do
    get :destroy
    assert_response :success
  end

  test "should create user" do
  	user = User.create(:id=>1,:uid=>1,:provider=>"facebook")
  	Session.session[:user_id] = user.id
  	assert_redirected_to restaurants_index_path
  end
end
