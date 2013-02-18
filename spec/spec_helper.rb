require 'rubygems'
require "rspec"
require "active_record"
require 'active_support'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'rails'))
require "init"
require "rails/railtie"

module Rails
  def self.cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Base.configurations = true

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define(:version => 1) do
  create_table :settings do |t|
    t.string  :var, :null => false
    t.text    :value
    t.integer :thing_id
    t.string  :thing_type, :limit => 30
  end

  create_table :users do |t|
    t.string :name
  end
end

RSpec.configure do |config|
  config.before(:all) do
    class ::Setting < RailsSettings::Settings
    end

    class User < ActiveRecord::Base
      include RailsSettings
    end

    ::Setting.destroy_all
    Rails.cache.clear
  end

  config.after(:all) do
    Object.send(:remove_const, :Setting)
  end
end
