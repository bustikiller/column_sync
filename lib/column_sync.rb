# frozen_string_literal: true

require "active_record"
require "fx"

require "column_sync/version"
require "column_sync/service"
require "column_sync/migration"

module ColumnSync
  class Error < StandardError; end

  ::ActiveRecord::Migration.include(ColumnSync::Migration)
end
