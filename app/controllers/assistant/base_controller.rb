module Assistant
  # The assistant panel's actions. Without an Anthropic API key there is no assistant, so they don't exist.
  class BaseController < ApplicationController
    before_action { head :not_found unless assistant_available? }
  end
end
