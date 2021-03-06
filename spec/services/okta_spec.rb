require "rails_helper"

RSpec.describe Okta do
  let(:okta_user_info) do
    {
      ssoguid: "qwer",
      email: "okta@okta.com",
      first_name: "Okta",
      last_name: "Test"
    }
  end

  let(:jwt_payload) { {exp: 1.minute.from_now.to_i} }
  let(:okta_client_id) { ENV["OKTA_SERVER_AUDIENCE"].split(",").first }
  let(:jwt_default_payload) { {iss: ENV["OKTA_SERVER_PATH"], aud: ENV["OKTA_SERVER_PATH"], cid: okta_client_id} }
  let(:access_token) { JWT.encode(jwt_default_payload.merge(jwt_payload), nil, "none") }

  def stub_successful_profile
    stub_request(:get, "https://dev1-signon.okta.com/oauth2/v1/userinfo")
      .with(headers: {Authorization: "Bearer #{access_token}"})
      .to_return(body: okta_user_info.to_json)
  end

  def stub_unsuccessful_profile
    stub_request(:get, "https://dev1-signon.okta.com/oauth2/v1/userinfo").to_return(status: 401)
  end

  describe ".find_user_by_access_token" do
    it "return a newly User" do
      stub_successful_profile

      expect {
        expect(described_class.find_user_by_access_token(access_token)).to be_a User
      }.to change(User, :count).by(1)
    end

    context "with existing user" do
      let!(:user) { FactoryBot.create(:user, sso_guid: "qwer") }

      before { stub_successful_profile }

      it "returns existing user" do
        expect {
          expect(described_class.find_user_by_access_token(access_token)).to eq user
        }.to change(User, :count).by(0)
      end
    end

    context "with expired token" do
      let(:jwt_payload) { {exp: 1.minute.ago.to_i} }

      it "raises error" do
        expect { described_class.find_user_by_access_token(access_token) }.to raise_error Okta::FailedAuthentication
      end

      it "does not create a user" do
        expect {
          begin
            described_class.find_user_by_access_token(access_token)
          rescue Okta::FailedAuthentication
            nil
          end
        }.to change(User, :count).by(0)
      end
    end

    context "invalid ticket signing" do
      before { stub_unsuccessful_profile }

      describe "#validate" do
        it "raises an authentication error with a message" do
          expect { described_class.find_user_by_access_token(access_token) }.to(
            raise_error(
              Okta::FailedAuthentication,
              "Error validating access_token with Okta"
            )
          )
        end
      end
    end
  end
end
