# frozen_string_literal: true

class TranslatedPagesController < SecureController
  def create
    t = TranslatedPage.create!(permitted_params)
    render json: t, location: "translated_pages/#{t.id}", status: :created
  end

  def update
    t = load_translated_page.update!(permitted_params)
    render json: t, status: :created
  end

  def destroy
    load_translated_page.destroy!
    head :no_content
  end

  private

  def load_translated_page
    TranslatedPage.find(params[:id])
  end

  def permitted_params
    permit_params(:value, :resource_id, :language_id)
  end
end
