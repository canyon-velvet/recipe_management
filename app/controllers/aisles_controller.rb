class AislesController < ApplicationController
  def create
    aisle = Aisle.add_before_other(current_user, params.require(:aisle).permit(:name)[:name])

    if aisle.persisted?
      render json: { id: aisle.id, name: aisle.name }, status: :created
    else
      render json: { errors: aisle.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
