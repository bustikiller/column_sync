# frozen_string_literal: true

module ColumnSync
  class Service
    FUNCTION_PREFIX = "column_sync"
    attr_reader :referenced_table_name,
                :referenced_column_name,
                :referenced_primary_key,
                :referencer_table_name,
                :referencer_column_name,
                :referencer_fk_column_name

    def initialize(columns)
      raise ArgumentError, "columns must be a hash" unless columns.is_a?(Hash)
      raise ArgumentError, "two tables and columns must be provided" unless columns.size == 2

      referenced_model, referencer_model = columns.keys.permutation(2).find do |(referenced, referencer)|
        referenced.reflect_on_all_associations(:has_one)
                  .find { |association| association.klass == referencer }
                  .tap { |association| @referencer_fk_column_name = association.foreign_key if association }
      end

      raise ArgumentError, "no valid column relation found" unless referenced_model && referencer_model

      @referenced_column_name = columns[referenced_model].to_s
      @referencer_column_name = columns[referencer_model].to_s

      unless referenced_model.column_names.include?(referenced_column_name)
        raise ArgumentError, "referenced column #{referenced_column_name} does not exist"
      end

      unless referencer_model.column_names.include?(referencer_column_name)
        raise ArgumentError, "referencer column #{referencer_column_name} does not exist"
      end

      @referenced_table_name = referenced_model.table_name
      @referenced_primary_key = referenced_model.primary_key
      @referencer_table_name = referencer_model.table_name
    end

    def functions
      {
        referencer_sync_name => referencer_update_function,
        referenced_sync_name => referenced_update_function
      }
    end

    def triggers
      {
        referencer_sync_name => { definition: referencer_trigger, table_name: referenced_table_name },
        referenced_sync_name => { definition: referenced_trigger, table_name: referencer_table_name }
      }
    end

    private

    def referencer_sync_name
      "#{FUNCTION_PREFIX}_#{referencer_table_name}_#{referencer_column_name}_on_#{referenced_table_name}_update"
    end

    def referenced_sync_name
      "#{FUNCTION_PREFIX}_#{referenced_table_name}_#{referenced_column_name}_on_#{referencer_table_name}_update"
    end

    def referencer_update_function
      <<~SQL
        CREATE OR REPLACE FUNCTION #{FUNCTION_PREFIX}_#{referencer_table_name}_#{referencer_column_name}_on_#{referenced_table_name}_update()
        RETURNS TRIGGER AS $$
        BEGIN
        IF NEW.#{referenced_column_name} IS DISTINCT FROM OLD.#{referenced_column_name} THEN
          UPDATE #{referencer_table_name}
          SET #{referencer_column_name} = NEW.#{referenced_column_name}
          WHERE #{referencer_fk_column_name} = NEW.#{referenced_primary_key};
        END IF;
        RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL
    end

    def referenced_update_function
      <<~SQL
        CREATE OR REPLACE FUNCTION #{FUNCTION_PREFIX}_#{referenced_table_name}_#{referenced_column_name}_on_#{referencer_table_name}_update()
        RETURNS TRIGGER AS $$
        BEGIN
        IF NEW.#{referencer_column_name} IS DISTINCT FROM OLD.#{referencer_column_name} THEN
          UPDATE #{referenced_table_name}
          SET #{referenced_column_name} = NEW.#{referencer_column_name}
          WHERE #{referenced_primary_key} = NEW.#{referencer_fk_column_name};
        END IF;
        RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL
    end

    def referencer_trigger
      <<~SQL
        CREATE TRIGGER #{FUNCTION_PREFIX}_#{referencer_table_name}_#{referencer_column_name}_on_#{referenced_table_name}_update
        AFTER UPDATE ON #{referenced_table_name}
        FOR EACH ROW EXECUTE PROCEDURE #{FUNCTION_PREFIX}_#{referencer_table_name}_#{referencer_column_name}_on_#{referenced_table_name}_update();
      SQL
    end

    def referenced_trigger
      <<~SQL
        CREATE TRIGGER #{FUNCTION_PREFIX}_#{referenced_table_name}_#{referenced_column_name}_on_#{referencer_table_name}_update
        AFTER UPDATE ON #{referencer_table_name}
        FOR EACH ROW EXECUTE PROCEDURE #{FUNCTION_PREFIX}_#{referenced_table_name}_#{referenced_column_name}_on_#{referencer_table_name}_update();
      SQL
    end
  end
end
