require_relative "../../../test_helper"

class TestApisV1UsersCreate < Minitest::Capybara::Test
  include ApiUmbrellaTests::AdminAuth
  include ApiUmbrellaTests::Setup

  def setup
    setup_server
    ApiUser.where(:registration_source.ne => "seed").delete_all
  end

  def test_not_email_verified_by_default
    response = Typhoeus.post("https://127.0.0.1:9081/api-umbrella/v1/users.json", @@http_options.deep_merge(non_admin_key_creator_api_key).deep_merge({
      :headers => { "Content-Type" => "application/x-www-form-urlencoded" },
      :body => { :user => FactoryGirl.attributes_for(:api_user) },
    }))
    assert_equal(201, response.code, response.body)

    data = MultiJson.load(response.body)
    assert_kind_of(String, data["user"]["api_key"])
    user = ApiUser.find(data["user"]["id"])
    assert_equal(false, user.email_verified)
  end

  def test_email_verification_does_not_return_key
    response = Typhoeus.post("https://127.0.0.1:9081/api-umbrella/v1/users.json", @@http_options.deep_merge(non_admin_key_creator_api_key).deep_merge({
      :headers => { "Content-Type" => "application/x-www-form-urlencoded" },
      :body => {
        :user => FactoryGirl.attributes_for(:api_user),
        :options => { :verify_email => true },
      },
    }))
    assert_equal(201, response.code, response.body)

    data = MultiJson.load(response.body)
    assert_nil(data["user"]["api_key"])
    user = ApiUser.find(data["user"]["id"])
    assert_equal(true, user.email_verified)
    refute_match(user.api_key, response.body)
  end

  def test_always_email_verified_when_admin_creates_account
    response = Typhoeus.post("https://127.0.0.1:9081/api-umbrella/v1/users.json", @@http_options.deep_merge(admin_token).deep_merge({
      :headers => { "Content-Type" => "application/x-www-form-urlencoded" },
      :body => { :user => FactoryGirl.attributes_for(:api_user) },
    }))
    assert_equal(201, response.code, response.body)

    data = MultiJson.load(response.body)
    assert_kind_of(String, data["user"]["api_key"])
    user = ApiUser.find(data["user"]["id"])
    assert_equal(true, user.email_verified)
  end

  private

  def non_admin_key_creator_api_key
    user = FactoryGirl.create(:api_user, {
      :roles => ["api-umbrella-key-creator"],
    })

    { :headers => { "X-Api-Key" => user["api_key"] } }
  end
end
