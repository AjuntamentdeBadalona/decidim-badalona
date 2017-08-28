# frozen_string_literal: true

require "spec_helper"

describe "Authorizations", type: :feature, perform_enqueued: true do
  let(:organization) { create :organization, available_authorizations: authorizations }
  let(:authorizations) { ["CensusAuthorizationHandler"] }

  def fill_in_authorization_form
    page.execute_script("$('#date_field_authorization_handler_date_of_birth').focus()")
    page.find(".datepicker-dropdown .day", text: "12").click
    fill_in "Codi postal", with: "08225"
    select "DNI del ciutadà", from: "Tipus de document"
    fill_in "Número de document", with: "12345678A"
  end

  before do
    Decidim.authorization_handlers = [CensusAuthorizationHandler]
    allow_any_instance_of(CensusAuthorizationHandler).to receive(:response).and_return(JSON.parse("{ \"status\": \"OK\" }"))
    switch_to_host(organization.host)
  end

  context "a new user" do
    let(:user) { create(:user, :confirmed, organization: organization) }

    context "when one authorization has been configured" do
      before do
        visit decidim.root_path
        find(".sign-in-link").click

        within "form.new_user" do
          fill_in :user_email, with: user.email
          fill_in :user_password, with: "password1234"
          find("*[type=submit]").click
        end
      end

      it "redirects the user to the authorization form after the first sign in" do
        fill_in_authorization_form
        click_button "Send"
        expect(page).to have_content("successfully")
      end

      it "allows the user to skip it" do
        find(".skip a").click
        expect(page).to have_content("Welcome")
      end
    end
  end

  context "user account" do
    let(:user) { create(:user, :confirmed) }

    before do
      login_as user, scope: :user
      visit decidim.root_path
    end

    it "allows the user to authorize against available authorizations" do
      visit decidim.new_authorization_path(handler: "census_authorization_handler")

      fill_in_authorization_form
      click_button "Send"

      expect(page).to have_content("successfully")

      visit decidim.authorizations_path

      within ".authorizations-list" do
        expect(page).to have_content("El padró")
        expect(page).not_to have_link("El padró")
      end
    end

    context "when the user has already been authorised" do
      let!(:authorization) do
        create(:authorization,
               name: CensusAuthorizationHandler.handler_name,
               user: user)
      end

      it "shows the authorization at their account" do
        visit decidim.authorizations_path

        within ".authorizations-list" do
          expect(page).to have_content("El padró")
          expect(page).not_to have_link("El padró")
          expect(page).to have_content(I18n.localize(authorization.created_at, format: :long))
        end
      end
    end
  end
end
