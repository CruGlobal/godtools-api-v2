# frozen_string_literal: true

module XmlUtil
  def self.translatable_nodes(xml)
    xml.xpath('//content:text[@i18n-id]')
  end

  def self.xml_filename_sha(data)
    "#{filename_sha(data)}.xml"
  end

  def self.filename_sha(data)
    Digest::SHA256.hexdigest(data)
  end
end
