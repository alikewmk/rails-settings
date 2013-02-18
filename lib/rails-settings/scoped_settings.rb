module RailsSettings
  class ScopedSettings < Settings

    def self.for_thing(object)
      @object = object
      self
    end

    def self.thing_scoped
      Settings.where(:thing_type => @object.class.name.downcase, :thing_id => @object.id)
    end

    def self.[](var_name)
      Rails.cache.fetch("settings:#{@object.class.name.downcase}:#{@object.id}:#{var_name}") {
        self.thing_scoped.find_by_var(var_name.to_s)
      }
    end

    def self.[]=(var_name, value)
      var_name = var_name.to_s

      record = self.thing_scoped.find_by_var(var_name.to_s) || thing_scoped.new(var: var_name)
      record.value = value
      record.save!

      value
    end

  end
end
