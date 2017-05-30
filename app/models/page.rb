# frozen_string_literal: true

class Page < AbstractPage
  belongs_to :resource
  has_many :custom_pages
  has_many :translated_pages

  validates :filename, presence: true
  validates :resource, presence: true
  validates :position, presence: true, uniqueness: { scope: :resource }

  def onesky_phrases # TODO: refactor this method
    phrases = {}

    Nokogiri::XML(structure).xpath('//content:text[@i18n-id]').each do |node|
      phrases[node['i18n-id']] = node.content
    end

    phrases
  end
end
