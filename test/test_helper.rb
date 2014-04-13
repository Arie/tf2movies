ENV['RAILS_ENV'] = 'test'

require 'codeclimate-test-reporter'
require 'simplecov'

if ENV['CI'] == 'true'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  CodeClimate::TestReporter::Formatter
  ]
end

SimpleCov.start('rails') do
  add_group 'Policies', 'app/policies'
  add_group 'Services', 'app/services'
end

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/rails'
require 'minitest/pride'
require 'minitest/metadata'
require 'capybara/rails'
require 'capybara_minitest_spec'
require 'capybara/poltergeist'
require 'database_cleaner'
require 'webmock/minitest'
require 'vcr'

# VCR configuration
VCR.configure do |c|
  c.cassette_library_dir = 'test/cassettes'
  c.hook_into :webmock
  c.ignore_localhost = true
  c.ignore_hosts 'codeclimate.com' # whitelisted for coverage report
end

# requires PhantomJS to be installed
Capybara.javascript_driver = :poltergeist

# Database is cleaned between tests
DatabaseCleaner.strategy = :deletion

class MiniTest::Spec
  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end
end

class ActionDispatch::IntegrationTest
  include Capybara::DSL # Capybara DSL in integration Tests
  include MiniTest::Metadata

  setup do
    if metadata[:js] == true
      Capybara.current_driver = Capybara.javascript_driver
    end
  end

  teardown do
    DatabaseCleaner.clean # Clean database
    Capybara.reset_sessions! # Reset sessions
    Capybara.current_driver = Capybara.default_driver
  end
end

module SharedIntegrationSteps
  def login
    # Omniauth mock
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:steam] = OmniAuth::AuthHash.new(
      :provider => 'steam',
      :info => {
        :nickname => 'Bob',
        :urls => { :Profile => 'http://steamcommunity.com/12345' }
        },
      :uid => '12345'
    )

    visit(root_path)
    click_link('login')
    find('.alert.alert-success')
  end

  def logout
    visit(root_path)
    find('#user').click
    find('#logout').click
    find('.alert.alert-success')
  end
end

def as_logged_in_user
  user = FactoryGirl.create(:user)
  session[:user_id] = user.id
  yield
  session.delete :user_id
end

def as_logged_in_banned_user
  banned = FactoryGirl.create(:banned)
  session[:user_id] = banned.id
  yield
  session.delete :user_id
end

def as_logged_in_moderator
  moderator = FactoryGirl.create(:moderator)
  session[:user_id] = moderator.id
  yield
  session.delete :user_id
end

def as_logged_in_admin
  admin = FactoryGirl.create(:admin)
  session[:user_id] = admin.id
  yield
  session.delete :user_id
end