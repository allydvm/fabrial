# frozen_string_literal: true

module Maker
  SYNC_CLASSES = [Appointment, AppointmentType, AppliedAppointmentType,
    AppointmentResource, AppointmentStatus, Breed, ClientClass, Client, Employee,
    Owner, Patient, Species, Prescription, Reminder, ReminderType, Transaction,
    InvoiceItem, Product, ProductCategory].freeze

  SyncRecordLog.load_all_models
  LOG_CLASSES = SyncRecordLog.descendants

  MAKE_CLASSES = (SYNC_CLASSES + LOG_CLASSES + [Source, Practice, Site, User, Alert,
    Request, Schedule, Schedule::Category, Schedule::Entry, Schedule::BreakTime,
    DailyStats, CommunicationRecord, CommunicationSetting, DirectMessageTemplate,
    Trigger, RetentionActivity, LoyaltyTransaction, Reward, PracticeConfiguration,
    SurveyResponse, Enterprise, DailyStatsSnapshot, ClientConnectionClinic,
    EmergencyContact, Package, Dashboard, EnterpriseAffiliation,
    EnterpriseMembership, DataAuthorization]).freeze

  module_function

  def init(negative_ids: false)
    @initialized = true
    DefaultData.initialize

    AutoIds.negative_ids = true if negative_ids

    MAKE_CLASSES.each do |klass|
      klass._attr_readonly = [] # Remove all read only column declarations

      # Define a make function to mimic machinist's make funciton. This will
      # allow tests and seeds to share hierarchical record creation logic
      klass.define_singleton_method :make! do |data = {}|
        Maker.make(self, data)
      end
    end
  end

  def make(klass, data = {})
    # Find the base class of any STI types
    base = klass.base_class

    defaults = DefaultData[klass]
    defaults ||= DefaultData[base]
    raise "#{klass.name} not prepped for Maker" unless defaults

    data = defaults.merge data
    klass_id = base.name.foreign_key.to_sym
    # Get the primary keys
    find_by = if base == Site
                data[:site_id] ||= AutoIds.next base
                data.extract! :source_id, :site_id, :source
              elsif base.in? SYNC_CLASSES
                data[klass_id] ||= AutoIds.next base
                data.extract! klass_id, :source_id, :source
              else
                data[:id] ||= AutoIds.next base
                data.extract! :id
              end
    find_by[:source_id] = find_by.delete(:source).id if find_by[:source]

    # Normally, we NEVER write to the sync data. We need to here in order to
    # 'seed' our dev database with some 'test' data. This differs from the test
    # database, which is set/cleared per test. Temporarily override the 'read-only'
    # nature of the sync data
    ImmutableRecord.thoughtfully_change do
      klass.find_or_initialize_by(find_by).tap { |obj| obj.update! data }
    end
  end

  def next_bank(*args)
    AutoIds.next_bank(*args) if @initialized
  end

  module DefaultData
    @data = {}

    module_function

    def [](key)
      @data[key]
    end

    def initialize
      auto_defaults
      manual_defaults
    end

    # Default most columns to 'something'
    def auto_defaults
      MAKE_CLASSES.each do |klass|
        data = {}
        klass.columns.each do |col|
          next if col.name.ends_with? 'id', 'token', 'type'

          data[col.name.to_sym] =
            case col.type
            when :string    then col.name.camelcase
            when :text      then col.name.camelcase
            when :integer   then 1
            when :date      then Time.zone.today
            when :datetime  then Time.current
            when :boolean   then false
            end
        end
        @data[klass] = data
      end
    end

    # Merge in some hand-crafted defaults.
    def manual_defaults # rubocop:disable MethodLength - large constant
      @data.deep_merge!(
        User => {
          encrypted_api_key: nil,
        },
        Source => {
          sync_client_id: 'ABC-123'
        },
        Site => {
          practice_id_override: nil,
        },
        Client => {
          mobile_phone: '9096480001',
          home_phone: '9096480002',
          work_phone: '9096480003',
          state: 'CA',
          postal_code: '12345',
          email: 'myemail@test.com',
        },
        ClientLog => {
          mobile_phone: nil,
          home_phone: nil,
          work_phone: nil,
        },
        Patient => {
          birthdate: Time.zone.today - 3.years,
          deceased_date: nil,
        },
        Owner => { percentage: 100 },
        Alert => {
          resolved_status: nil,
          resolved_at: nil,
          daily_stats_credited_date: nil,
          resolution_condition: nil
        },
        CommunicationRecord => {
          opened_count: 0,
          clicked_count: 0,
          medium_type: :email,
        },
        CommunicationSetting => { settings: nil },
        LoyaltyTransaction => { fulfilled_at: nil },
        PracticeConfiguration => { settings: {} },
        Enterprise => { permission_set: nil },
      )
    end
  end

  module AutoIds
    # When klass_id is not passed, we will use the ids hash to auto-generate
    # ids. Note that these ids start at 10,000; lower ids are free to use
    # manually.  NOTE: The order of records, within a create_dev_data call,
    # using auto ids needs to be constant in order for records to update
    # correctly. When reorder is necessary, be sure to start with empty
    # databases with
    #   spring rake db:sync:reset db:drop db:create db:structure:load
    # before running
    #   spring rake db:seed
    @ids = {}

    class << self
      attr_accessor :negative_ids
    end

    module_function

    # Get the next auto-incrementing id for the given symbol
    def next(klass)
      id = @ids[klass] || 10_000 * sign
      @ids[klass] += 1 * sign
      id
    end

    # Advance the auto-incrementing id to the bank of 1000
    def next_bank(klass)
      @ids[klass] =
        ((@ids[klass] || 9000 * sign) / 1000 + 1 * sign) * 1000
    end

    def sign
      negative_ids ? -1 : 1
    end
  end
end
