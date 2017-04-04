# frozen_string_literal: true

class TranslationSerializer < ActiveModel::Serializer
  attributes :id, :is_published, :version

  belongs_to :resource
  belongs_to :language

  has_many :custom_pages
end
