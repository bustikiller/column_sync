# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2023_12_10_132345) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "expires_at"
    t.string "country_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_subscriptions_on_company_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "subscriptions", "companies"
  create_function :column_sync_subscriptions_country_code_on_companies_update, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.column_sync_subscriptions_country_code_on_companies_update()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
      IF NEW.country IS DISTINCT FROM OLD.country THEN
        UPDATE subscriptions
        SET country_code = NEW.country
        WHERE company_id = NEW.id;
      END IF;
      RETURN NEW;
      END;
      $function$
  SQL
  create_function :column_sync_companies_country_on_subscriptions_update, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.column_sync_companies_country_on_subscriptions_update()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
      IF NEW.country_code IS DISTINCT FROM OLD.country_code THEN
        UPDATE companies
        SET country = NEW.country_code
        WHERE id = NEW.company_id;
      END IF;
      RETURN NEW;
      END;
      $function$
  SQL


  create_trigger :column_sync_subscriptions_country_code_on_companies_update, sql_definition: <<-SQL
      CREATE TRIGGER column_sync_subscriptions_country_code_on_companies_update AFTER UPDATE ON public.companies FOR EACH ROW EXECUTE FUNCTION column_sync_subscriptions_country_code_on_companies_update()
  SQL
  create_trigger :column_sync_companies_country_on_subscriptions_update, sql_definition: <<-SQL
      CREATE TRIGGER column_sync_companies_country_on_subscriptions_update AFTER UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION column_sync_companies_country_on_subscriptions_update()
  SQL
end
