require 'test_helper'

class UserTest < ActiveSupport::TestCase
   test "the truth" do
     assert true
   end
   test "should not save user without uid" do
   	user = User.new
   	assert_not user.save
   end
   test "should report error" do
   	some_random_var
   	assert true
   end
end
