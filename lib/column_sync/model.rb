require "active_support/concern"

module ColumnSync
  module Model
    extend ActiveSupport::Concern

    included do
      scope :disabled, -> { where(disabled: true) }

      before_update :propagate_changes

      private

      def propagate_changes
        changes.each do |attribute, (_before, after)|
          propagate_changes_in_memory(attribute, after)
        end
      end

      def propagate_changes_in_memory(attribute, value)
        self.class.columns_to_sync[attribute]&.each do |sync|
          object = public_send(sync[:to])
          next unless object

          current_value = object.attributes[sync[:column].to_s]

          object.public_send("#{sync[:column]}=", value) if current_value.to_s != value.to_s
        end
      end
    end

    class_methods do
      attr_reader :columns_to_sync

      def sync_column(column_name, to:, column:)
        @columns_to_sync ||= {}
        @columns_to_sync[column_name.to_s] ||= []
        @columns_to_sync[column_name.to_s] << { to: to, column: column }

        define_method("#{column_name}=") do |value|
          super(value)

          propagate_changes_in_memory(column_name.to_s, value)
        end
      end
    end
  end
end
