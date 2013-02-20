module RailsSettings
  class Settings < ActiveRecord::Base
    attr_accessible :var
    after_create  :write_cache
    after_update  :write_cache
    after_destroy :clear_cache

    self.table_name = 'settings'

    class SettingNotFound < RuntimeError; end

    cattr_accessor :defaults
    @@defaults = {}.with_indifferent_access

    # Support old plugin
    if defined?(SettingsDefaults::DEFAULTS)
      @@defaults = SettingsDefaults::DEFAULTS.with_indifferent_access
    end

    #get or set a variable with the variable as the called method
    def self.method_missing(method, *args)
      method_name = method.to_s
      super(method, *args)

    rescue NoMethodError
      #set a value for a variable
      if method_name =~ /=$/
        var_name = method_name.gsub('=', '')
        value = args.first
        self[var_name] = value

      #retrieve a value
      else
        self[method_name]

      end
    end

    def self.defaults=(defaults)
      @@defaults = defaults.with_indifferent_access
    end

    #destroy the specified settings record
    def self.destroy(var_name)
      var_name = var_name.to_s
      if self[var_name]
        object(var_name).destroy
        true
      else
        raise SettingNotFound, "Setting variable \"#{var_name}\" not found"
      end
    end

    #retrieve all settings as a hash (optionally starting with a given namespace)
    def self.all(starting_with=nil)
      options = starting_with ? { :conditions => "var LIKE '#{starting_with}%'"} : {}
      vars = thing_scoped.find(:all, {:select => 'var, value'}.merge(options))

      result = {}
      vars.each do |record|
        result[record.var] = record.value
      end
      @@defaults.select { |k,_| k =~ /^#{starting_with}/ }.merge(result).with_indifferent_access
    end

    #get a setting value by [] notation
    def self.[](var_name)
      cached_key = Rails.cache.fetch("settings:#{var_name}")
      return cached_key if cached_key
      if var = object(var_name)
        var.value
      elsif @@defaults[var_name.to_s]
        @@defaults[var_name.to_s]
      else
        nil
      end
    end

    #set a setting value by [] notation
    def self.[]=(var_name, value)
      var_name = var_name.to_s

      record = object(var_name) || thing_scoped.new(:var => var_name)
      record.value = value
      record.save!

      value
    end

    def self.merge!(var_name, hash_value)
      raise ArgumentError unless hash_value.is_a?(Hash)

      old_value = self[var_name] || {}
      raise TypeError, "Existing value is not a hash, can't merge!" unless old_value.is_a?(Hash)

      new_value = old_value.merge(hash_value)
      self[var_name] = new_value if new_value != old_value

      new_value
    end

    def self.object(var_name)
      thing_scoped.find_by_var(var_name.to_s)
    end

    def self.thing_scoped
      self.where(:thing_type => nil, :thing_id => nil)
    end

    #get the value field, YAML decoded
    def value
      YAML::load(self[:value])
    end

    #set the value field, YAML encoded
    def value=(new_value)
      self[:value] = new_value.to_yaml
    end

    def write_cache
      Rails.cache.write(cache_key, self.value)
    end

    def clear_cache
      Rails.cache.delete(cache_key)
    end

    def cache_key
      thing_type && thing_id ? "settings:#{thing_type.downcase}:#{thing_id}:#{self.var}" : "settings:#{self.var}"
    end

  end
end
