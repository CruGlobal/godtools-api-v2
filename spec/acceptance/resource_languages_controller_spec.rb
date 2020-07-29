# frozen_string_literal: true

require "acceptance_helper"

resource "ResourceLanguage" do
  header "Accept", "application/vnd.api+json"
  header "Content-Type", "application/vnd.api+json"

  let(:raw_post) { params.to_json }
  let(:authorization) { AuthToken.create!(access_code: AccessCode.find(1)).token }
  let(:test_structure) { '<?xml version="1.0" encoding="UTF-8" ?><page> new page </page>' }

  get "resources/:resource_id/languages/:id" do
    let(:resource) { Resource.first }
    let(:language) { Language.first }
    let(:language2) { Language.second }
    let(:resource_id) { resource.id }
    let(:id) { language.id }
    let!(:attribute1) { FactoryBot.create(:attribute, resource: resource, key: "resource_attribute", value: "resource_value") }
    let!(:attribute2) { FactoryBot.create(:language_attribute, language: language, resource: resource, key: "language_attribute", value: "language_value") }
    let!(:attribute3) { FactoryBot.create(:language_attribute, language: language, resource: resource, key: "something_else", value: "some_other_value") }
    let!(:attribute4) { FactoryBot.create(:language_attribute, language: language2, resource: resource, key: "other_language_attribute", value: "language2_value") }

    let(:structure) do
      '<?xml version="1.0" encoding="UTF-8" ?>
	<page xmlns="https://mobile-content-api.cru.org/xmlns/tract"
				xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
	</page>'
    end

    let!(:page) { FactoryBot.create(:page, resource: resource, structure: structure, position: 10) }
    let!(:custom_page) { FactoryBot.create(:custom_page, page: page, structure: structure, language: language) }
    let!(:custom_page2) { FactoryBot.create(:custom_page, page: page, structure: structure, language: language2) }

    let(:tip_structure) do
      %(<tip xmlns="https://mobile-content-api.cru.org/xmlns/training"
					xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
						<pages>
								<page>
										<content:paragraph>
												<content:text />
										</content:paragraph>
										<content:text />
								</page>
						</pages>
				</tip>)
    end
    let!(:tip) { FactoryBot.create(:tip, resource: resource, structure: tip_structure) }
    let!(:custom_tip) { FactoryBot.create(:custom_tip, tip: tip, structure: tip_structure, language: language) }
    let!(:custom_tip2) { FactoryBot.create(:custom_tip, tip: tip, structure: tip_structure, language: language2) }

    it "get resource_language data" do
      do_request

      expect(status).to eq(200)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
      expect(JSON.parse(response_body)).to eq(
        {
          "data" => {
            "id" => "1-1",
            "type" => "resource-language",
            "attributes" => {
              "attr-language-attribute" => "language_value",
              "attr-something-else" => "some_other_value",
            },
            "relationships" => {
              "resource" => {
                "data" => {
                  "id" => "1",
                  "type" => "resource",
                },
              },
              "language" => {
                "data" => {
                  "id" => language.id.to_s,
                  "type" => "language",
                },
              },
              "custom-pages" => {
                "data" => [
                  {
                    "id" => custom_page.id.to_s,
                    "type" => "custom-page",
                  },
                ],
              },
              "custom-tips" => {
                "data" => [
                  {
                    "id" => custom_tip.id.to_s,
                    "type" => "custom-tip",
                  },
                ],
              },
            },
          },
        }
      )
    end
    #
    #     it "sets location header", document: false do
    #       do_request data: {type: :page, attributes: attrs}
    #
    #       expect(response_headers["Location"]).to eq("pages/12345")
    #     end
  end
  # TODO

  put "resources/:resource_id/languages/:id" do
    let(:resource) { Resource.first }
    let(:language) { Language.first }
    let(:resource_id) { resource.id }
    let(:id) { language.id }
    let(:data) do
      {
        "type": "resource-language",
        "id": "#{resource.id}-#{language.id}",
        "attributes": {
          "attr-enable-tips": true,
          "attr-other-key": nil,
        },
      }
    end

    requires_authorization

    it "update resource language" do
      do_request data: data
      expect(status).to eq(200)
      expect(JSON.parse(response_body)["data"]).not_to be_nil
      att = LanguageAttribute.find_by(resource: resource, language: language, key: "enable_tips")
      expect(att).to_not be_nil
      expect(att.value).to eq("true")
      att = LanguageAttribute.find_by(resource: resource, language: language, key: "other_key")
      expect(att).to be_nil
    end
  end
end
