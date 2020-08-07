class ApplicationController < ActionController::API
  def index
    details = {
      "apiVersion" => '1',
      "author" => "jesseschroder",
      "color" => "#a40000",
      "head" => "evil",
      "tail" => "hook",
    }

    render json: details
  end
end
