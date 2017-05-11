# frozen_string_literal: true

class AttributesController < SecureController
  def create
    create_attribute
  end

  def update
    update_attr
  end

  def destroy
    destroy_attribute
  end

  private

  def create_attribute
    Attribute.create!(params[:data][:attributes].permit(permitted_params))
    head :no_content # TODO: location header?
  end

  def update_attr
    load_attribute.update!(params[:data][:attributes].permit(permitted_params))
    head :no_content
  end

  def destroy_attribute
    load_attribute.destroy!
    head :no_content
  end

  def load_attribute
    Attribute.find(params[:id])
  end

  def permitted_params
    [:key, :value, :resource_id]
  end
end
