# frozen_string_literal: true

class TranslatedAttributesController < SecureController
  def create
    create_translated_attr
  end

  def update
    update_translated_attr
  end

  def destroy
    destroy_translated_attr
  end

  private

  def create_translated_attr
    TranslatedAttribute.create!(params[:data][:attributes].permit(permitted_params))
    head :no_content # TODO: location header?
  end

  def update_translated_attr
    load_translated_attr.update!(params[:data][:attributes].permit(permitted_params))
    head :no_content
  end

  def destroy_translated_attr
    load_translated_attr.destroy!
    head :no_content
  end

  def load_translated_attr
    TranslatedAttribute.find(params[:id])
  end

  def permitted_params
    [:value, :attribute_id, :translation_id]
  end
end
