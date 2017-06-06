# frozen_string_literal: true

require 'acceptance_helper'

resource 'Follow Ups' do
  header 'Accept', 'application/vnd.api+json'
  header 'Content-Type', 'application/vnd.api+json'
  let(:raw_post) { params.to_json }

  post 'follow_ups/' do
    let(:data) { { type: :follow_up, attributes: { name: 'Billy Bob', email: 'bob@test.com', language_id: 2 } } }

    it 'create a subscriber' do
      do_request data: data

      expect(status).to be(204)
      expect(response_body['data']).to be_nil
    end
  end
end
