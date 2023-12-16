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

You also need to update your models to reflect the syncroniaztion between their columns:

```ruby
class Company < ApplicationRecord
  include ColumnSync::Model
  
  has_one :subscription

  sync_column :country, to: :subscription, column: :country_code
end

class Subscription < ApplicationRecord
  include ColumnSync::Model

  belongs_to :company

  sync_column :country_code, to: :company, column: :country
end
```

## Example

Given the following scenario:

```ruby
Company.create!(country: "es")
Subscription.create!(country_code: "es", company: Company.first)
```

Changes are reflected in memory when the value is modified:

```ruby
company = Company.first
company.country = "fr"
company.subscription.country_code
# => "fr"

company.subscription.country_code = "ca"
company.country
# => "ca"
```

Changes are also reflected in the DB when the value is persisted:

```ruby
company = Company.first
company.update(country: "it")
company.subscription.country_code
# => "it"

company.subscription.update(country_code: "ma")
company.country
# => "ma" 
```

## Limitations

- Each `sync_columns` statement can only sync a pair of columns. If the same column needs to be synchronized across multiple
  tables, multiple such statements will be needed.
- The gem expects a `has_one` - `belongs_to` association between the models involved. It uses Rails reflections to understand
  the table names and column names involved.
- It is assumed that the records are initially in sync, so it does **not** automatically sync values using any of the two 
  columns involved.
- It also does not sync values when a row is created, only when it is modified.