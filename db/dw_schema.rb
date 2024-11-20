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

ActiveRecord::Schema[8.0].define(version: 2024_11_20_092310) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bb_grouped_work_overviews", force: :cascade do |t|
    t.string "uid"
    t.integer "account_id"
    t.integer "company_id"
    t.integer "user_id"
    t.integer "customer_id"
    t.integer "project_id"
    t.integer "timesheet_id"
    t.integer "projectuser_id"
    t.integer "invoice_id"
    t.integer "month"
    t.integer "year"
    t.string "account_name"
    t.string "company_name"
    t.string "target"
    t.string "group"
    t.string "row_type"
    t.string "user_name"
    t.string "customer_name"
    t.string "project_name"
    t.string "broker"
    t.date "start_date"
    t.date "end_date"
    t.string "calculation_type"
    t.string "hour_type"
    t.decimal "hours", precision: 10, scale: 2
    t.decimal "rate", precision: 10, scale: 2
    t.jsonb "invoices", default: {}
    t.jsonb "progress", default: {}
    t.string "frequence"
    t.string "type_amount"
    t.decimal "period_amount", precision: 10, scale: 2
    t.boolean "credit"
    t.string "status"
    t.date "invoice_date"
    t.decimal "turnover_excl_vat", precision: 10, scale: 2
    t.decimal "vat", precision: 10, scale: 2
    t.decimal "turnover_incl_vat", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "show_name"
    t.index ["account_id"], name: "index_bb_grouped_work_overviews_on_account_id"
    t.index ["company_id"], name: "index_bb_grouped_work_overviews_on_company_id"
    t.index ["customer_id"], name: "index_bb_grouped_work_overviews_on_customer_id"
    t.index ["group"], name: "index_bb_grouped_work_overviews_on_group"
    t.index ["invoice_id"], name: "index_bb_grouped_work_overviews_on_invoice_id"
    t.index ["month"], name: "index_bb_grouped_work_overviews_on_month"
    t.index ["project_id"], name: "index_bb_grouped_work_overviews_on_project_id"
    t.index ["projectuser_id"], name: "index_bb_grouped_work_overviews_on_projectuser_id"
    t.index ["show_name"], name: "index_bb_grouped_work_overviews_on_show_name"
    t.index ["target"], name: "index_bb_grouped_work_overviews_on_target"
    t.index ["timesheet_id"], name: "index_bb_grouped_work_overviews_on_timesheet_id"
    t.index ["uid"], name: "index_bb_grouped_work_overviews_on_uid", unique: true
    t.index ["user_id"], name: "index_bb_grouped_work_overviews_on_user_id"
    t.index ["year"], name: "index_bb_grouped_work_overviews_on_year"
  end

  create_table "bb_invoice_overviews", force: :cascade do |t|
    t.string "uid"
    t.integer "account_id"
    t.integer "company_id"
    t.integer "user_id"
    t.integer "customer_id"
    t.integer "invoice_id"
    t.integer "project_id"
    t.string "account_name"
    t.string "company_name"
    t.string "invoice_nr"
    t.date "invoice_date"
    t.string "invoice_type"
    t.integer "month"
    t.integer "year"
    t.string "user_name"
    t.string "customer_name"
    t.string "project_name"
    t.string "description"
    t.decimal "quantity", precision: 10, scale: 2
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_bb_invoice_overviews_on_account_id"
    t.index ["company_id"], name: "index_bb_invoice_overviews_on_company_id"
    t.index ["customer_id"], name: "index_bb_invoice_overviews_on_customer_id"
    t.index ["invoice_date"], name: "index_bb_invoice_overviews_on_invoice_date"
    t.index ["invoice_id"], name: "index_bb_invoice_overviews_on_invoice_id"
    t.index ["invoice_nr"], name: "index_bb_invoice_overviews_on_invoice_nr"
    t.index ["invoice_type"], name: "index_bb_invoice_overviews_on_invoice_type"
    t.index ["month"], name: "index_bb_invoice_overviews_on_month"
    t.index ["project_id"], name: "index_bb_invoice_overviews_on_project_id"
    t.index ["uid"], name: "index_bb_invoice_overviews_on_uid", unique: true
    t.index ["user_id"], name: "index_bb_invoice_overviews_on_user_id"
    t.index ["year"], name: "index_bb_invoice_overviews_on_year"
  end

  create_table "bb_open_invoicing_overviews", force: :cascade do |t|
    t.string "uid"
    t.integer "account_id"
    t.integer "company_id"
    t.integer "user_id"
    t.integer "customer_id"
    t.integer "invoice_id"
    t.string "account_name"
    t.string "company_name"
    t.string "user_name"
    t.string "customer_name"
    t.string "project_name"
    t.string "status"
    t.string "category"
    t.decimal "quantity", precision: 10, scale: 2
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "month"
    t.integer "year"
    t.index ["account_id"], name: "index_bb_open_invoicing_overviews_on_account_id"
    t.index ["category"], name: "index_bb_open_invoicing_overviews_on_category"
    t.index ["company_id"], name: "index_bb_open_invoicing_overviews_on_company_id"
    t.index ["customer_id"], name: "index_bb_open_invoicing_overviews_on_customer_id"
    t.index ["invoice_id"], name: "index_bb_open_invoicing_overviews_on_invoice_id"
    t.index ["month", "year"], name: "index_bb_open_invoicing_overviews_on_month_and_year"
    t.index ["status"], name: "index_bb_open_invoicing_overviews_on_status"
    t.index ["uid"], name: "index_bb_open_invoicing_overviews_on_uid", unique: true
    t.index ["user_id"], name: "index_bb_open_invoicing_overviews_on_user_id"
  end

  create_table "bb_rws_ohw_overviews", force: :cascade do |t|
    t.string "uid"
    t.integer "account_id"
    t.integer "year"
    t.integer "month"
    t.integer "offer_id"
    t.string "offer_nr"
    t.string "status"
    t.string "deliverable_name"
    t.string "invoice_nr_purchasing"
    t.decimal "amount_purchasing", precision: 10, scale: 2
    t.string "invoice_nr_sales"
    t.date "invoice_date_sales"
    t.decimal "amount_sales", precision: 10, scale: 2
    t.string "employee_name"
    t.decimal "hours", precision: 10, scale: 2
    t.decimal "rate", precision: 10, scale: 2
    t.decimal "total_employee", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_bb_rws_ohw_overviews_on_account_id"
    t.index ["month"], name: "index_bb_rws_ohw_overviews_on_month"
    t.index ["offer_id"], name: "index_bb_rws_ohw_overviews_on_offer_id"
    t.index ["status"], name: "index_bb_rws_ohw_overviews_on_status"
    t.index ["uid"], name: "index_bb_rws_ohw_overviews_on_uid", unique: true
    t.index ["year"], name: "index_bb_rws_ohw_overviews_on_year"
  end

  create_table "bb_timesheet_hour_overviews", force: :cascade do |t|
    t.string "uid"
    t.integer "account_id"
    t.integer "company_id"
    t.integer "user_id"
    t.integer "customer_id"
    t.integer "unbillable_id"
    t.integer "month"
    t.integer "year"
    t.integer "day"
    t.string "account_name"
    t.string "company_name"
    t.string "user_name"
    t.string "customer_name"
    t.string "project_name"
    t.string "unbillable_name"
    t.decimal "hours", precision: 10, scale: 2
    t.decimal "rate", precision: 10, scale: 2
    t.decimal "purchase_price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_bb_timesheet_hour_overviews_on_account_id"
    t.index ["company_id"], name: "index_bb_timesheet_hour_overviews_on_company_id"
    t.index ["customer_id"], name: "index_bb_timesheet_hour_overviews_on_customer_id"
    t.index ["month"], name: "index_bb_timesheet_hour_overviews_on_month"
    t.index ["uid"], name: "index_bb_timesheet_hour_overviews_on_uid", unique: true
    t.index ["unbillable_id"], name: "index_bb_timesheet_hour_overviews_on_unbillable_id"
    t.index ["user_id"], name: "index_bb_timesheet_hour_overviews_on_user_id"
    t.index ["year"], name: "index_bb_timesheet_hour_overviews_on_year"
  end

  create_table "bb_timesheet_invoice_hours", force: :cascade do |t|
    t.bigint "uid"
    t.integer "account_id"
    t.integer "month"
    t.integer "year"
    t.string "account_name"
    t.string "company_name"
    t.string "user_name"
    t.string "customer_name"
    t.decimal "timesheet_hours", precision: 10, scale: 2
    t.decimal "invoice_hours", precision: 10, scale: 2
    t.decimal "diff_hours", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "company_id"
    t.index ["account_id"], name: "index_bb_timesheet_invoice_hours_on_account_id"
    t.index ["company_id"], name: "index_bb_timesheet_invoice_hours_on_company_id"
    t.index ["month"], name: "index_bb_timesheet_invoice_hours_on_month"
    t.index ["uid"], name: "index_bb_timesheet_invoice_hours_on_uid", unique: true
    t.index ["year"], name: "index_bb_timesheet_invoice_hours_on_year"
  end

  create_table "dim_accounts", force: :cascade do |t|
    t.integer "original_id"
    t.string "name"
    t.string "is_holding"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_holding"], name: "index_dim_accounts_on_is_holding"
    t.index ["original_id"], name: "index_dim_accounts_on_original_id", unique: true
  end

  create_table "dim_companies", force: :cascade do |t|
    t.integer "account_id"
    t.string "original_id"
    t.string "name"
    t.string "name_short"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "original_id"], name: "index_dim_companies_on_account_id_and_original_id", unique: true
    t.index ["account_id"], name: "index_dim_companies_on_account_id"
    t.index ["original_id"], name: "index_dim_companies_on_original_id"
  end

  create_table "dim_customers", force: :cascade do |t|
    t.integer "account_id"
    t.string "original_id"
    t.string "name"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "original_id"], name: "index_dim_customers_on_account_id_and_original_id", unique: true
    t.index ["account_id"], name: "index_dim_customers_on_account_id"
    t.index ["original_id"], name: "index_dim_customers_on_original_id"
    t.index ["status"], name: "index_dim_customers_on_status"
  end

  create_table "dim_dates", force: :cascade do |t|
    t.integer "year"
    t.integer "month"
    t.string "month_name"
    t.string "month_name_short"
    t.integer "day"
    t.integer "day_of_week"
    t.string "day_name"
    t.string "day_name_short"
    t.integer "quarter"
    t.integer "week_nr"
    t.boolean "is_workday"
    t.boolean "is_holiday_nl"
    t.boolean "is_holiday_be"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "original_date"
    t.integer "yearmonth"
    t.integer "iso_year"
    t.integer "iso_week"
    t.index ["day"], name: "index_dim_dates_on_day"
    t.index ["day_of_week"], name: "index_dim_dates_on_day_of_week"
    t.index ["is_holiday_be"], name: "index_dim_dates_on_is_holiday_be"
    t.index ["is_holiday_nl"], name: "index_dim_dates_on_is_holiday_nl"
    t.index ["is_workday"], name: "index_dim_dates_on_is_workday"
    t.index ["iso_week"], name: "index_dim_dates_on_iso_week"
    t.index ["iso_year"], name: "index_dim_dates_on_iso_year"
    t.index ["month"], name: "index_dim_dates_on_month"
    t.index ["original_date"], name: "index_dim_dates_on_original_date"
    t.index ["quarter"], name: "index_dim_dates_on_quarter"
    t.index ["week_nr"], name: "index_dim_dates_on_week_nr"
    t.index ["year"], name: "index_dim_dates_on_year"
    t.index ["yearmonth"], name: "index_dim_dates_on_yearmonth"
  end

  create_table "dim_holidays", force: :cascade do |t|
    t.string "uid"
    t.integer "account_id"
    t.integer "company_id"
    t.integer "holiday_date"
    t.string "name"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_dim_holidays_on_account_id"
    t.index ["company_id"], name: "index_dim_holidays_on_company_id"
    t.index ["country"], name: "index_dim_holidays_on_country"
    t.index ["holiday_date"], name: "index_dim_holidays_on_holiday_date"
    t.index ["uid"], name: "index_dim_holidays_on_uid", unique: true
  end

  create_table "dim_ledgers", force: :cascade do |t|
    t.integer "account_id"
    t.string "original_reknr"
    t.string "reknr"
    t.string "description"
    t.string "origin"
    t.string "administration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "origin", "administration", "reknr"], name: "idx_on_account_id_origin_administration_reknr_53e5fbe151", unique: true
    t.index ["account_id"], name: "index_dim_ledgers_on_account_id"
    t.index ["administration"], name: "index_dim_ledgers_on_administration"
    t.index ["origin"], name: "index_dim_ledgers_on_origin"
    t.index ["reknr"], name: "index_dim_ledgers_on_reknr"
  end

  create_table "dim_projects", force: :cascade do |t|
    t.integer "account_id"
    t.string "original_id"
    t.string "name"
    t.string "status"
    t.integer "company_id"
    t.string "calculation_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "start_date"
    t.integer "end_date"
    t.integer "customer_id"
    t.integer "expected_end_date"
    t.index ["account_id", "original_id", "start_date", "end_date"], name: "idx_on_account_id_original_id_start_date_end_date_529d8461b2", unique: true
    t.index ["account_id"], name: "index_dim_projects_on_account_id"
    t.index ["calculation_type"], name: "index_dim_projects_on_calculation_type"
    t.index ["company_id"], name: "index_dim_projects_on_company_id"
    t.index ["customer_id"], name: "index_dim_projects_on_customer_id"
    t.index ["end_date"], name: "index_dim_projects_on_end_date"
    t.index ["expected_end_date"], name: "index_dim_projects_on_expected_end_date"
    t.index ["original_id"], name: "index_dim_projects_on_original_id"
    t.index ["start_date"], name: "index_dim_projects_on_start_date"
    t.index ["status"], name: "index_dim_projects_on_status"
  end

  create_table "dim_roles", force: :cascade do |t|
    t.string "uid"
    t.string "role"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_dim_roles_on_uid", unique: true
  end

  create_table "dim_unbillables", force: :cascade do |t|
    t.integer "account_id"
    t.string "original_id"
    t.string "name"
    t.string "name_short"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "original_id"], name: "index_dim_unbillables_on_account_id_and_original_id", unique: true
    t.index ["account_id"], name: "index_dim_unbillables_on_account_id"
    t.index ["original_id"], name: "index_dim_unbillables_on_original_id"
  end

  create_table "dim_users", force: :cascade do |t|
    t.integer "account_id"
    t.string "original_id"
    t.string "full_name"
    t.integer "company_id"
    t.string "role"
    t.string "email"
    t.string "employee_type"
    t.string "contract"
    t.integer "contract_hours"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "salary"
    t.integer "start_date"
    t.integer "leave_date"
    t.string "address"
    t.string "zipcode"
    t.string "city"
    t.string "country"
    t.integer "unavailable_before"
    t.index ["account_id", "original_id"], name: "index_dim_users_on_account_id_and_original_id", unique: true
    t.index ["account_id"], name: "index_dim_users_on_account_id"
    t.index ["company_id"], name: "index_dim_users_on_company_id"
    t.index ["contract"], name: "index_dim_users_on_contract"
    t.index ["country"], name: "index_dim_users_on_country"
    t.index ["employee_type"], name: "index_dim_users_on_employee_type"
    t.index ["original_id"], name: "index_dim_users_on_original_id"
    t.index ["role"], name: "index_dim_users_on_role"
    t.index ["unavailable_before"], name: "index_dim_users_on_unavailable_before"
  end

  create_table "dp_logs", force: :cascade do |t|
    t.integer "dp_run_id"
    t.string "message"
    t.string "status"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dp_run_id"], name: "index_dp_logs_on_dp_run_id"
    t.index ["status"], name: "index_dp_logs_on_status"
  end

  create_table "dp_pipelines", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "status", default: "inactive"
    t.datetime "last_executed_at"
    t.integer "frequency", default: 24
    t.string "load_method", default: "incremental"
    t.integer "dp_tasks_count", default: 0
    t.integer "dp_runs_count", default: 0
    t.jsonb "account_ids", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pipeline_key"
    t.integer "month"
    t.integer "year"
    t.integer "position"
    t.integer "scoped_user_id"
    t.index ["account_ids"], name: "index_dp_pipelines_on_account_ids", using: :gin
    t.index ["dp_runs_count"], name: "index_dp_pipelines_on_dp_runs_count"
    t.index ["dp_tasks_count"], name: "index_dp_pipelines_on_dp_tasks_count"
    t.index ["frequency"], name: "index_dp_pipelines_on_frequency"
    t.index ["last_executed_at"], name: "index_dp_pipelines_on_last_executed_at"
    t.index ["load_method"], name: "index_dp_pipelines_on_load_method"
    t.index ["month"], name: "index_dp_pipelines_on_month"
    t.index ["name"], name: "index_dp_pipelines_on_name", unique: true
    t.index ["pipeline_key"], name: "index_dp_pipelines_on_pipeline_key"
    t.index ["position"], name: "index_dp_pipelines_on_position"
    t.index ["scoped_user_id"], name: "index_dp_pipelines_on_scoped_user_id"
    t.index ["status"], name: "index_dp_pipelines_on_status"
    t.index ["year"], name: "index_dp_pipelines_on_year"
  end

  create_table "dp_quality_checks", force: :cascade do |t|
    t.integer "dp_run_id"
    t.integer "dp_task_id"
    t.string "check_type"
    t.string "description"
    t.integer "expected"
    t.integer "actual"
    t.string "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["check_type"], name: "index_dp_quality_checks_on_check_type"
    t.index ["dp_run_id"], name: "index_dp_quality_checks_on_dp_run_id"
    t.index ["dp_task_id"], name: "index_dp_quality_checks_on_dp_task_id"
    t.index ["result"], name: "index_dp_quality_checks_on_result"
  end

  create_table "dp_results", force: :cascade do |t|
    t.integer "dp_task_id"
    t.integer "dp_run_id"
    t.string "job_id"
    t.string "status"
    t.string "error"
    t.jsonb "depends_on", default: []
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dp_run_id"], name: "index_dp_results_on_dp_run_id"
    t.index ["dp_task_id"], name: "index_dp_results_on_dp_task_id"
    t.index ["job_id"], name: "index_dp_results_on_job_id"
    t.index ["status"], name: "index_dp_results_on_status"
  end

  create_table "dp_runs", force: :cascade do |t|
    t.integer "account_id"
    t.string "status", default: "new"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer "dp_pipeline_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_dp_runs_on_account_id"
    t.index ["dp_pipeline_id"], name: "index_dp_runs_on_dp_pipeline_id"
    t.index ["status"], name: "index_dp_runs_on_status"
  end

  create_table "dp_tasks", force: :cascade do |t|
    t.string "name"
    t.string "task_key"
    t.string "description"
    t.string "status", default: "active"
    t.integer "sequence"
    t.jsonb "depends_on", default: []
    t.integer "dp_pipeline_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dp_pipeline_id"], name: "index_dp_tasks_on_dp_pipeline_id"
    t.index ["name"], name: "index_dp_tasks_on_name"
    t.index ["sequence"], name: "index_dp_tasks_on_sequence"
    t.index ["status"], name: "index_dp_tasks_on_status"
    t.index ["task_key"], name: "index_dp_tasks_on_task_key"
  end

  create_table "etl_storages", force: :cascade do |t|
    t.integer "account_id"
    t.string "identifier"
    t.string "etl"
    t.jsonb "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_etl_storages_on_account_id"
    t.index ["etl"], name: "index_etl_storages_on_etl"
    t.index ["identifier"], name: "index_etl_storages_on_identifier"
  end

  create_table "fact_activities", force: :cascade do |t|
    t.integer "account_id"
    t.string "original_id"
    t.integer "customer_id"
    t.integer "unbillable_id"
    t.integer "user_id"
    t.integer "company_id"
    t.integer "projectuser_id"
    t.integer "project_id"
    t.decimal "hours", precision: 10, scale: 2
    t.decimal "rate", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "activity_date"
    t.integer "refreshed"
    t.index ["account_id", "original_id"], name: "index_fact_activities_on_account_id_and_original_id", unique: true
    t.index ["account_id"], name: "index_fact_activities_on_account_id"
    t.index ["company_id"], name: "index_fact_activities_on_company_id"
    t.index ["customer_id"], name: "index_fact_activities_on_customer_id"
    t.index ["original_id"], name: "index_fact_activities_on_original_id"
    t.index ["project_id"], name: "index_fact_activities_on_project_id"
    t.index ["projectuser_id"], name: "index_fact_activities_on_projectuser_id"
    t.index ["refreshed"], name: "index_fact_activities_on_refreshed"
    t.index ["unbillable_id"], name: "index_fact_activities_on_unbillable_id"
    t.index ["user_id"], name: "index_fact_activities_on_user_id"
  end

  create_table "fact_invoices", force: :cascade do |t|
    t.integer "account_id"
    t.string "original_id"
    t.integer "invoice_date"
    t.string "status"
    t.integer "project_id"
    t.integer "customer_id"
    t.integer "user_id"
    t.integer "company_id"
    t.integer "timesheet_month"
    t.integer "timesheet_year"
    t.boolean "credit"
    t.integer "condition_days"
    t.boolean "internal_charging"
    t.decimal "amount_excl_vat", precision: 10, scale: 2
    t.decimal "vat_6", precision: 10, scale: 2
    t.decimal "vat_9", precision: 10, scale: 2
    t.decimal "vat_21", precision: 10, scale: 2
    t.decimal "vat_total", precision: 10, scale: 2
    t.decimal "amount_incl_vat", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "original_id"], name: "index_fact_invoices_on_account_id_and_original_id", unique: true
    t.index ["company_id"], name: "index_fact_invoices_on_company_id"
    t.index ["condition_days"], name: "index_fact_invoices_on_condition_days"
    t.index ["credit"], name: "index_fact_invoices_on_credit"
    t.index ["customer_id"], name: "index_fact_invoices_on_customer_id"
    t.index ["internal_charging"], name: "index_fact_invoices_on_internal_charging"
    t.index ["invoice_date"], name: "index_fact_invoices_on_invoice_date"
    t.index ["project_id"], name: "index_fact_invoices_on_project_id"
    t.index ["status"], name: "index_fact_invoices_on_status"
    t.index ["timesheet_month"], name: "index_fact_invoices_on_timesheet_month"
    t.index ["timesheet_year"], name: "index_fact_invoices_on_timesheet_year"
    t.index ["user_id"], name: "index_fact_invoices_on_user_id"
  end

  create_table "fact_ledger_mutations", force: :cascade do |t|
    t.integer "account_id"
    t.string "original_reknr"
    t.string "reknr"
    t.string "description"
    t.string "origin"
    t.string "administration"
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "mutation_date"
    t.integer "year"
    t.integer "month"
    t.index ["account_id", "origin", "administration", "reknr"], name: "idx_on_account_id_origin_administration_reknr_6605a1077e", unique: true
    t.index ["account_id"], name: "index_fact_ledger_mutations_on_account_id"
    t.index ["administration"], name: "index_fact_ledger_mutations_on_administration"
    t.index ["month"], name: "index_fact_ledger_mutations_on_month"
    t.index ["origin"], name: "index_fact_ledger_mutations_on_origin"
    t.index ["reknr"], name: "index_fact_ledger_mutations_on_reknr"
    t.index ["year"], name: "index_fact_ledger_mutations_on_year"
  end

  create_table "fact_projectusers", force: :cascade do |t|
    t.integer "account_id"
    t.string "original_id"
    t.integer "user_id"
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "start_date"
    t.integer "end_date"
    t.integer "expected_end_date"
    t.index ["account_id", "original_id"], name: "index_fact_projectusers_on_account_id_and_original_id", unique: true
    t.index ["account_id"], name: "index_fact_projectusers_on_account_id"
    t.index ["expected_end_date"], name: "index_fact_projectusers_on_expected_end_date"
    t.index ["original_id"], name: "index_fact_projectusers_on_original_id"
    t.index ["project_id"], name: "index_fact_projectusers_on_project_id"
    t.index ["user_id"], name: "index_fact_projectusers_on_user_id"
  end

  create_table "fact_rates", force: :cascade do |t|
    t.integer "account_id"
    t.integer "company_id"
    t.integer "user_id"
    t.decimal "hours", precision: 10, scale: 2
    t.decimal "avg_rate", precision: 10, scale: 2
    t.decimal "bcr", precision: 10, scale: 2
    t.decimal "ucr", precision: 10, scale: 2
    t.decimal "company_bcr", precision: 10, scale: 2
    t.decimal "company_ucr", precision: 10, scale: 2
    t.string "contract"
    t.decimal "contract_hours", precision: 10, scale: 2
    t.decimal "salary", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rate_date"
    t.string "role"
    t.string "show_user", default: "Y"
    t.index ["account_id", "user_id", "rate_date"], name: "index_fact_rates_on_account_id_and_user_id_and_rate_date", unique: true
    t.index ["account_id"], name: "index_fact_rates_on_account_id"
    t.index ["company_id"], name: "index_fact_rates_on_company_id"
    t.index ["contract"], name: "index_fact_rates_on_contract"
    t.index ["role"], name: "index_fact_rates_on_role"
    t.index ["show_user"], name: "index_fact_rates_on_show_user"
    t.index ["user_id"], name: "index_fact_rates_on_user_id"
  end

  create_table "fact_targets", force: :cascade do |t|
    t.string "uid"
    t.integer "account_id"
    t.string "original_id"
    t.integer "company_id"
    t.integer "year"
    t.integer "month"
    t.string "role_group"
    t.decimal "fte"
    t.integer "billable_hours"
    t.decimal "cost_price"
    t.decimal "bruto_margin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "target_date"
    t.integer "workable_hours"
    t.decimal "productivity", precision: 5, scale: 2
    t.decimal "hour_rate", precision: 5, scale: 2
    t.decimal "turnover", precision: 10, scale: 2
    t.integer "quarter"
    t.decimal "employee_attrition"
    t.decimal "employee_absence"
    t.index ["account_id"], name: "index_fact_targets_on_account_id"
    t.index ["company_id"], name: "index_fact_targets_on_company_id"
    t.index ["employee_absence"], name: "index_fact_targets_on_employee_absence"
    t.index ["employee_attrition"], name: "index_fact_targets_on_employee_attrition"
    t.index ["month"], name: "index_fact_targets_on_month"
    t.index ["original_id"], name: "index_fact_targets_on_original_id"
    t.index ["quarter"], name: "index_fact_targets_on_quarter"
    t.index ["role_group"], name: "index_fact_targets_on_role_group"
    t.index ["target_date"], name: "index_fact_targets_on_target_date"
    t.index ["uid"], name: "index_fact_targets_on_uid", unique: true
    t.index ["year"], name: "index_fact_targets_on_year"
  end

  create_table "lucanet_transactions", force: :cascade do |t|
    t.string "uid"
    t.string "period"
    t.integer "month"
    t.integer "year"
    t.integer "quarter"
    t.string "currency"
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "export_timestamp"
    t.string "adjustment_level_name"
    t.string "adjustment_level_type"
    t.string "adjustment_level_order"
    t.string "data_level_name"
    t.string "data_level_type"
    t.integer "data_level_period_from"
    t.integer "data_level_period_to"
    t.string "partner_id"
    t.string "partner_name"
    t.string "organisation_element_id"
    t.string "organisation_element_name"
    t.string "organisation_accounting_or_consolidation_area"
    t.string "transaction_structure_type_id"
    t.string "transaction_type_name"
    t.string "transaction_type_type"
    t.string "account_report_element_id"
    t.string "account_name"
    t.string "account_balance_type"
    t.string "account_level_1"
    t.string "account_level_2"
    t.string "account_level_3"
    t.string "account_level_4"
    t.string "account_level_5"
    t.string "account_level_6"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_balance_type"], name: "index_lucanet_transactions_on_account_balance_type"
    t.index ["account_level_1"], name: "index_lucanet_transactions_on_account_level_1"
    t.index ["account_level_2"], name: "index_lucanet_transactions_on_account_level_2"
    t.index ["account_level_3"], name: "index_lucanet_transactions_on_account_level_3"
    t.index ["account_level_4"], name: "index_lucanet_transactions_on_account_level_4"
    t.index ["account_level_5"], name: "index_lucanet_transactions_on_account_level_5"
    t.index ["account_level_6"], name: "index_lucanet_transactions_on_account_level_6"
    t.index ["account_name"], name: "index_lucanet_transactions_on_account_name"
    t.index ["account_report_element_id"], name: "index_lucanet_transactions_on_account_report_element_id"
    t.index ["adjustment_level_name"], name: "index_lucanet_transactions_on_adjustment_level_name"
    t.index ["adjustment_level_order"], name: "index_lucanet_transactions_on_adjustment_level_order"
    t.index ["adjustment_level_type"], name: "index_lucanet_transactions_on_adjustment_level_type"
    t.index ["data_level_name"], name: "index_lucanet_transactions_on_data_level_name"
    t.index ["data_level_period_from"], name: "index_lucanet_transactions_on_data_level_period_from"
    t.index ["data_level_period_to"], name: "index_lucanet_transactions_on_data_level_period_to"
    t.index ["data_level_type"], name: "index_lucanet_transactions_on_data_level_type"
    t.index ["month"], name: "index_lucanet_transactions_on_month"
    t.index ["organisation_element_id"], name: "index_lucanet_transactions_on_organisation_element_id"
    t.index ["partner_id"], name: "index_lucanet_transactions_on_partner_id"
    t.index ["period"], name: "index_lucanet_transactions_on_period"
    t.index ["quarter"], name: "index_lucanet_transactions_on_quarter"
    t.index ["transaction_structure_type_id"], name: "index_lucanet_transactions_on_transaction_structure_type_id"
    t.index ["transaction_type_name"], name: "index_lucanet_transactions_on_transaction_type_name"
    t.index ["transaction_type_type"], name: "index_lucanet_transactions_on_transaction_type_type"
    t.index ["uid"], name: "index_lucanet_transactions_on_uid", unique: true
    t.index ["year"], name: "index_lucanet_transactions_on_year"
  end
end
