# frozen_string_literal: true

require 'zip'
require 'page_util'

class S3Util
  def initialize(translation)
    @translation = translation
    @zip_file_name = "version_#{@translation.version}.zip"
  end

  def push_translation
    build_zip
    upload

    PageUtil.delete_temp_pages
  rescue StandardError => e
    PageUtil.delete_temp_pages
    raise e
  end

  private

  def build_zip
    @document = Nokogiri::XML::Document.new
    root_node = Nokogiri::XML::Node.new('manifest', @document)
    @document.root = root_node

    pages_node = Nokogiri::XML::Node.new('pages', @document)
    resources_node = Nokogiri::XML::Node.new('resources', @document)
    root_node.add_child(pages_node)
    root_node.add_child(resources_node)

    Zip::File.open("pages/#{@zip_file_name}", Zip::File::CREATE) do |zip_file|
      add_pages(zip_file, pages_node)
      add_attachments(zip_file, resources_node)

      manifest_filename = write_manifest_to_file
      zip_file.add(manifest_filename, "pages/#{manifest_filename}")
    end
  end

  def add_pages(zip_file, pages_node)
    @translation.resource.pages.each do |page|
      sha_filename = write_page_to_file(page)
      zip_file.add(sha_filename, "pages/#{sha_filename}")

      add_page_node(pages_node, page.filename, sha_filename)
    end
  end

  def write_page_to_file(page)
    translated_page = @translation.build_translated_page(page.id, true)
    sha_filename = "#{Digest::SHA256.hexdigest(translated_page)}.xml"

    File.write("pages/#{sha_filename}", translated_page)

    sha_filename
  end

  def add_attachments(zip_file, resources_node)
    @translation.resource.attachments.each do |a|
      string_io_bytes = open(a.file.url).read
      filename = Digest::SHA256.hexdigest(string_io_bytes)

      File.binwrite("pages/#{filename}", string_io_bytes)

      zip_file.add(filename, "pages/#{filename}")
      add_resource_node(resources_node, a.file.original_filename, filename)
    end
  end

  def write_manifest_to_file
    filename = "#{Digest::SHA256.hexdigest(@document.to_s)}.xml"
    @translation.manifest_name = filename

    file = File.open("pages/#{filename}", 'w')
    @document.write_to(file)
    file.close

    filename
  end

  def add_page_node(parent, filename, sha_filename)
    node = Nokogiri::XML::Node.new('page', @document)
    node['filename'] = filename
    node['src'] = sha_filename
    parent.add_child(node)
  end

  def add_resource_node(parent, filename, sha_filename)
    node = Nokogiri::XML::Node.new('resource', @document)
    node['filename'] = filename
    node['src'] = sha_filename
    parent.add_child(node)
  end

  def upload
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['MOBILE_CONTENT_API_BUCKET'])
    obj = bucket.object("#{@translation.resource.system.name}/#{@translation.resource.abbreviation}"\
                        "/#{@translation.language.code}/#{@zip_file_name}")
    obj.upload_file("pages/#{@zip_file_name}", acl: 'public-read')
  end
end
