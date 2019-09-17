# frozen_string_literal: true

require "rest-client"

class FollowUp < ActiveRecord::Base
  belongs_to :language
  belongs_to :destination

  validates :email, presence: true, email_format: {message: "Invalid email address"}
  validates :language, presence: true
  validates :destination, presence: true

  def send_to_api
    save! if changed?
    Rails.logger.info "Sending follow up with id: #{id}."
    perform_request
  end

  private

  def body
    auth_params.merge(subscriber: subscriber_params).to_query
  end

  def auth_params
    {access_id: destination.access_key_id, access_secret: destination.access_key_secret}
  end

  def subscriber_params
    {route_id: destination.route_id, language_code: language.code, email: email}.merge(name_params)
  end

  def name_params
    return nil if name.nil?

    names = name.split(" ")
    {first_name: names[0], last_name: names[1]}
  end

  def headers
    {'Content-Type': "application/x-www-form-urlencoded"}
  end

  def perform_request
    code = RestClient.post(destination.url, body, headers).code
    Rails.logger.info "Received response code: #{code} from destination: #{destination.id}"
    raise Error::BadRequestError, "Received response code: #{code} from destination: #{destination.id}" if code != 201
  end
end
