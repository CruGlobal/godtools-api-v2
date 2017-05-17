# frozen_string_literal: true

require 'page_util'

class ResourcesController < ApplicationController
  before_action :authorize!, only: :update

  def index
    render json: all_resources, include: params[:include], status: :ok
  end

  def show
    render json: load_resource, include: params[:include], status: :ok
  end

  def update
    PageUtil.new(load_resource, 'en').push_new_onesky_translation(params['keep-existing-phrases'])

    head :no_content
  end

  private

  def all_resources
    if params['filter']
      Resource.system_name(params['filter']['system'])
    else
      Resource.all
    end
  end

  def load_resource
    Resource.find(params[:id])
  end
end