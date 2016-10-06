require_relative "../test_helper"

class TestAdminUiApiUsersAllowedReferers < Minitest::Capybara::Test
  include Capybara::Screenshot::MiniTestPlugin
  include ApiUmbrellaTests::AdminAuth
  include ApiUmbrellaTests::Setup

  def setup
    setup_server
  end

  def test_empty_input_saves_as_null
    admin_login
    visit "/admin/#/api_users/new"

    fill_in "E-mail", :with => "example@example.com"
    fill_in "First Name", :with => "John"
    fill_in "Last Name", :with => "Doe"
    check "User agrees to the terms and conditions"
    click_button("Save")

    assert_content("Successfully saved the user")
    user = ApiUser.order_by(:created_at.asc).last
    assert_nil(user["settings"]["allowed_referers"])
  end

  def test_multiple_lines_saves_as_array
    admin_login
    visit "/admin/#/api_users/new"

    fill_in "E-mail", :with => "example@example.com"
    fill_in "First Name", :with => "John"
    fill_in "Last Name", :with => "Doe"
    check "User agrees to the terms and conditions"
    fill_in "Restrict Access to HTTP Referers", :with => "*.example.com/*\n\n\n\nhttp://google.com/*"
    click_button("Save")

    assert_content("Successfully saved the user")
    user = ApiUser.order_by(:created_at.asc).last
    assert_equal(["*.example.com/*", "http://google.com/*"], user["settings"]["allowed_referers"])
  end

  def test_displays_existing_array_as_multiple_lines
    user = FactoryGirl.create(:api_user, :settings => { :allowed_referers => ["*.example.com/*", "http://google.com/*"] })
    admin_login
    visit "/admin/#/api_users/#{user.id}/edit"

    assert_equal("*.example.com/*\nhttp://google.com/*", find_field("Restrict Access to HTTP Referers").value)
  end

  def test_nullifies_existing_array_when_empty_input_saved
    user = FactoryGirl.create(:api_user, :settings => { :allowed_referers => ["*.example.com/*", "http://google.com/*"] })
    admin_login
    visit "/admin/#/api_users/#{user.id}/edit"

    assert_equal("*.example.com/*\nhttp://google.com/*", find_field("Restrict Access to HTTP Referers").value)
    fill_in "Restrict Access to HTTP Referers", :with => ""
    click_button("Save")

    assert_content("Successfully saved the user")
    user.reload
    assert_nil(user["settings"]["allowed_referers"])
  end
end
