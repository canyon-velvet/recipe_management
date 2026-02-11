class SourcesController < ApplicationController
  def search
    sources = Source.where("name ILIKE ?", "%#{params[:q]}%")
                   .order(:name)
                   .limit(20)
    render json: sources.map { |s| { id: s.id, name: s.name } }
  end

  def create
    source = Source.new(source_params)

    if source.save
      render json: { id: source.id, name: source.name }, status: :created
    else
      render json: { errors: source.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def source_params
    params.require(:source).permit(:name, :url)
  end
end
