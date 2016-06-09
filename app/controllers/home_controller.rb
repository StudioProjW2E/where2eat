class HomeController < ApplicationController
  skip_before_action :ensure_login, only: [:show]
  def show
  end
end
