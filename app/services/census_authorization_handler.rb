# frozen_string_literal: true
# Checks the authorization against the census for Badalona.
require "digest/md5"

# This class performs a check against the official census database in order
# to verify the citizen's residence.
class CensusAuthorizationHandler < Decidim::AuthorizationHandler
  include ActionView::Helpers::SanitizeHelper
  include Virtus::Multiparams

  attribute :date_of_birth, Date
  attribute :postal_code, String
  attribute :document_number, String
  attribute :document_type, Symbol

  validates :date_of_birth, presence: true
  validates :postal_code, presence: true, format: { with: /\A[0-9]*\z/ }
  validates :document_type, inclusion: { in: %i(DNI NIE PASS) }, presence: true
  validates :document_number, format: { with: /\A[A-z0-9]*\z/ }, presence: true

  validate :check_response

  # If you need to store any of the defined attributes in the authorization you
  # can do it here.
  #
  # You must return a Hash that will be serialized to the authorization when
  # it's created, and available though authorization.metadata
  def metadata
    super.merge(postal_code: postal_code)
  end

  def census_document_types
    %i(DNI NIE PASS).map do |type|
      [I18n.t(type, scope: "decidim.census_authorization_handler.document_types"), type]
    end
  end

  def unique_id
    Digest::MD5.hexdigest(
      "#{document_number}-#{Rails.application.secrets.secret_key_base}"
    )
  end

  private

  def check_response
    errors.add(:base, :invalid) unless response.present? && response["status"] == "OK"
  end

  def sanitized_date_of_birth
    @sanitized_date_of_birth ||= date_of_birth&.strftime("%d/%m/%Y")
  end

  def response
    return nil if date_of_birth.blank? ||
                  postal_code.blank? ||
                  document_type.blank? ||
                  document_number.blank?

    return @response if defined?(@response)

    connection = Faraday.new Rails.application.secrets.dig(:census, :url), ssl: { verify: false }
    connection.basic_auth(Rails.application.secrets.dig(:census, :auth_user), Rails.application.secrets.dig(:census, :auth_pass))

    response = connection.get do |request|
      request.params = request_params
    end

    @response ||= JSON.parse(response.body)
  end

  def request_params
    {
      datnaix: sanitized_date_of_birth,
      cdpost: postal_code,
      tipdoc: document_type,
      docident: document_number
    }
  end
end
