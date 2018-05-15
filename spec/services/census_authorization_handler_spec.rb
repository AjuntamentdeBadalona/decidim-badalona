# coding: utf-8
# frozen_string_literal: true
require "rails_helper"
require "decidim/dev/test/authorization_shared_examples"

describe CensusAuthorizationHandler do
  let(:subject) { handler }
  let(:handler) { described_class.from_params(params) }
  let(:date_of_birth) { Date.civil(1987, 9, 17) }
  let(:postal_code) { "08917" }
  let(:document_number) { "12345678A" }
  let(:document_type) { :NIE }
  let(:params) do
    {
      date_of_birth: date_of_birth,
      postal_code: postal_code,
      document_number: document_number,
      document_type: document_type
    }
  end

  it_behaves_like "an authorization handler"

  before do
    handler.user = create(:user)
  end

  context "with a valid response" do
    before do
      allow(handler)
        .to receive(:response)
        .and_return(JSON.parse("{ \"status\": \"OK\" }"))
    end

    describe "document_number" do
      context "when it isn't present" do
        let(:document_number) { nil }

        it { is_expected.not_to be_valid }
      end

      context "with an invalid format" do
        let(:document_number) { "(╯°□°）╯︵ ┻━┻" }

        it { is_expected.not_to be_valid }
      end
    end

    describe "document_type" do
      context "when it isn't present" do
        let(:document_type) { nil }

        it { is_expected.not_to be_valid }
      end

      context "when it has a weird value" do
        let(:document_type) { :driver_license }

        it { is_expected.not_to be_valid }
      end
    end

    describe "postal_code" do
      context "when it isn't present" do
        let(:postal_code) { nil }

        it { is_expected.not_to be_valid }
      end

      context "when it has an invalid format" do
        let(:postal_code) { "(ヘ･_･)ヘ┳━┳" }

        it { is_expected.not_to be_valid }
      end
    end

    describe "date_of_birth" do
      context "when it isn't present" do
        let(:date_of_birth) { nil }

        it { is_expected.not_to be_valid }
      end

      context "when the age is below 12" do
        let(:date_of_birth) { 11.years.ago.to_date }

        it { is_expected.not_to be_valid }
      end

      context "when the age is over or equal to 12" do
        let(:date_of_birth) { 12.years.ago.to_date }

        it { is_expected.to be_valid }
      end
    end

    context "when everything is fine" do
      it { is_expected.to be_valid }
    end
  end

  context "unique_id" do
    it "generates a different ID for a different document number" do
      handler.document_number = "ABC123"
      unique_id1 = handler.unique_id

      handler.document_number = "XYZ456"
      unique_id2 = handler.unique_id

      expect(unique_id1).to_not eq(unique_id2)
    end

    it "generates the same ID for the same document number" do
      handler.document_number = "ABC123"
      unique_id1 = handler.unique_id

      handler.document_number = "ABC123"
      unique_id2 = handler.unique_id

      expect(unique_id1).to eq(unique_id2)
    end

    it "hashes the document number" do
      handler.document_number = "ABC123"
      unique_id = handler.unique_id

      expect(unique_id).to_not include(handler.document_number)
    end
  end

  context "with an invalid response" do
    context "with an invalid response code" do
      before do
        allow(handler)
          .to receive(:response)
          .and_return(JSON.parse("{ \"status\": \"KO\", \"errorMessage\": \"This is an error\" }"))
      end

      it { is_expected.to_not be_valid }
    end
  end

  describe "metadata" do
    it "includes the postal code" do
      expect(subject.metadata).to include(postal_code: "08917")
    end
  end
end
