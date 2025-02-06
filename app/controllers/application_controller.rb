class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Authorization
end
