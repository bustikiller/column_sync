# ColumnSync

Keeping in sync columns in different tables is a pretty common step during database refactorings. The
`column_sync` gem provides ActiveRecord migration helpers to facilitate the sync of data between
columns.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add column_sync

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install column_sync

## Usage

The following snippet should be used as a migration template:

```ruby
class SyncColumns < ActiveRecord::Migration[7.1]
  def up
    sync_columns(Subscription => :country_code, Company => :country)
  end

  def down
    unsync_columns(Subscription => :country_code, Company => :country)
  end
end
```

The migration above generates the functions and triggers needed to keep `subscriptions.country_code` in sync with `companies.country`.

## Limitations

- Each `sync_columns` statement can only sync a pair of columns. If the same column needs to be synchronized across multiple
  tables, multiple such statements will be needed.
- The gem expects a `has_one` - `belongs_to` association between the models involved. It uses Rails reflections to understand
  the table names and column names involved.
- The columns involved in the migration will be kept in sync via database triggers executed on row update.
  It assumes the records are initially in sync, so it does **not** automatically sync values using any of the two columns involved.
- It also does not sync values when a row is created, only when it is modified.