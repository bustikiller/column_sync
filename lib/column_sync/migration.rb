# frozen_string_literal: true

module ColumnSync
  module Migration
    def sync_columns(columns)
      service = Service.new(columns)

      each_function(service) { |name| create_function(name) }
      each_trigger(service) { |name, table_name| create_trigger(name, on: table_name) }
    end

    def unsync_columns(columns)
      service = Service.new(columns)

      each_trigger(service) { |name, table_name| drop_trigger(name, on: table_name) }
      each_function(service) { |name| drop_function(name) }
    end

    private

    def each_function(service)
      service.functions.each do |name, definition|
        function_name = "#{name}_v01".to_sym
        file_name = "db/functions/#{function_name}.sql"
        File.open(file_name, "w") { |f| f.write(definition) }
        yield name
      ensure
        FileUtils.rm_f(file_name)
      end
    end

    def each_trigger(service)
      service.triggers.each do |name, config|
        trigger_name = "#{name}_v01".to_sym
        file_name = "db/triggers/#{trigger_name}.sql"
        File.open(file_name, "w") { |f| f.write(config[:definition]) }
        yield name, config[:table_name]
      ensure
        FileUtils.rm_f(file_name)
      end
    end
  end
end
