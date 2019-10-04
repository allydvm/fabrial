# # frozen_string_literal: true

require 'test_helper'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table(:sources) do |t|
    t.string :name
    t.timestamps null: false
  end

  create_table(:enterprises) do |t|
    t.timestamps null: false
  end

  create_table(:enterprise_memberships) do |t|
    t.timestamps null: false
  end

  create_table(:practices) do |t|
    t.string :name
    t.string :email
    t.string 
    t.timestamps null: false
  end

  create_table(:clients) do |t|
    t.timestamps null: false
  end

  create_table(:patients) do |t|
    t.timestamps null: false
  end

  create_table(:owners) do |t|
    t.timestamps null: false
  end

  create_table(:requests) do |t|
    t.timestamps null: false
  end

  create_table(:appointments) do |t|
    t.timestamps null: false
  end

  create_table(:requests) do |t|
    t.timestamps null: false
  end

  create_table(:requests) do |t|
    t.timestamps null: false
  end

  create_table(:schedules) do |t|
    t.timestamps null: false
  end
end

class FabricateTest < ActiveSupport::TestCase
  describe 'return values' do
    test 'return top object (Practice) from single tree' do
      object = create_test_objects practice: { id: 5, client: {} }
      assert_equal 5, object.id
      assert_kind_of Practice, object
    end
    test 'return top object (not Practice) from single tree' do
      object = create_test_objects patient: { name: 'Red', reminder: {} }
      assert_equal 'Red', object.name
      assert_kind_of Patient, object
    end
    test 'return first object from list of trees' do
      object = create_test_objects(
        client: { last_name: 'Suzuki' },
        client_class: {},
      )
      assert_equal 'Suzuki', object.last_name
    end
    test 'return first object from first array of objects' do
      object = create_test_objects(
        client: [
          { last_name: 'Aaaa' },
          { last_name: 'Bbbb' },
          { last_name: 'Cccc' },
        ],
        client_class: [{}, {}]
      )
      assert_equal 'Aaaa', object.last_name
    end
    test 'return specified object' do
      object = create_test_objects client: { patient: {
        appointment: { RETURN: true }
      } }
      assert_instance_of Appointment, object
      object = create_test_objects client: { patient: {
        RETURN: true, appointment: {}
      } }
      assert_instance_of Patient, object
    end
    test 'returns list of specified objects' do
      app1, app2 = create_test_objects client: { patient: { appointments: [
        { notes: 'hi', RETURN: true },
        { notes: 'there', RETURN: true },
      ] } }
      assert_equal 'hi', app1.notes
      assert_equal 'there', app2.notes

      client, patient = create_test_objects client: {
        RETURN: true,
        patient: {
          RETURN: true,
          appointments: [
            { notes: 'hi' },
            { notes: 'there' },
          ]
        }
      }
      assert_instance_of Client, client
      assert_instance_of Patient, patient
    end
    test 'returns hash of specified objects' do
      hash = create_test_objects client: {
        RETURN: :val_1,
        patient: {
          RETURN: :a_patient,
          appointments: [
            { notes: 'hi', RETURN: :stuff },
            { notes: 'there' },
          ]
        }
      }
      assert_instance_of Client, hash[:val_1]
      assert_instance_of Patient, hash[:a_patient]
      assert_equal 'hi', hash[:stuff].notes
    end
  end

  describe 'practice assignment' do
    test 'Default practice is created' do
      create_test_objects client: {}
      assert_equal MakeObjectTree::DEFAULT_PRACTICE_ID, Practice.first.id
    end
    test 'Default practice is used, if practice is not parent' do
      create_test_objects client: {}
      assert_equal MakeObjectTree::DEFAULT_PRACTICE_ID, Client.first.practice_id
    end
    test 'Parent practice is used' do
      create_test_objects practice: { id: 7, client: {} }
      assert_equal 7, Client.first.practice_id
    end
    test 'Given practice_id is used' do
      create_test_objects practice: { id: 2 }
      create_test_objects practice: { id: 3, client: { practice_id: 2 } }
      assert_equal 2, Client.first.practice_id
    end
    test 'Given practice object is used' do
      practice = create_test_objects practice: { id: 2 }
      create_test_objects practice: { id: 3, client: { practice: practice } }
      assert_equal 2, Client.first.practice_id
    end
    test 'specifying source attaches default practice' do
      create_test_objects source: { id: 2, client: {} }
      assert_equal 1, Source.count
      assert_equal 1, Practice.count # default created practice
      assert_equal 2, Practice.first.source_id
    end
    describe "doesn't create defaults if no_default: true" do
      test 'default source and practice created above enterprise' do
        create_test_objects enterprise: { source: { practice: {} } }
        assert_equal 2, Source.count
        assert_equal 2, Practice.count
      end
      test 'no defaults created' do
        create_test_objects NO_DEFAULTS: true,
          enterprise: { source: { practice: {} } }
        assert_equal 1, Source.count
        assert_equal 1, Practice.count
      end
    end
  end

  describe 'child connections' do
    test 'children are assigned to parent' do
      create_test_objects patient: { reminder: {} }
      assert_equal Patient.first.patient_id, Reminder.first.patient_id
    end
    test 'children are in parent`s practice' do
      create_test_objects patient: { reminder: {} }
      assert_equal MakeObjectTree::DEFAULT_PRACTICE_ID,
        Reminder.first.practice_id
      create_test_objects practice: { id: 4, patient: { reminder: {} } }
      assert_equal 4, Reminder.last.practice_id
    end
    test 'alerts tied to clients' do
      create_test_objects client: { alert: { type: 'InvalidEmailAlert' } }
      assert_equal Client.first.client_id, Alert.first.alertable_id
    end
    test 'alerts tied to patients' do
      create_test_objects patient: { alert: { type: 'PastDueReminderAlert' } }
      assert_equal Patient.first.patient_id, Alert.first.alertable_id
    end
    test 'comm record hooks up to reminders, appointments, patients' do
      create_test_objects patient: { communication_record: {} }
      assert_equal Patient.first.patient_id, CommunicationRecord.first.regarding_id
    end
    test 'parents can be specified by object' do
      practice = create_test_objects practice: { id: 9 }
      create_test_objects practice: { object: practice, client: {} }
      assert_equal 9, Client.first.practice_id
    end
  end

  describe 'many-to-many connections' do
    test 'appointment tied to patient under client' do
      create_test_objects client: { patient: { appointment: {} } }
      appointment = Appointment.first
      assert_equal Client.first.client_id, appointment.client_id
      assert_equal Patient.first.patient_id, appointment.patient_id
    end
    test 'appointment tied to client under patient' do
      create_test_objects patient: { client: { appointment: {} } }
      appointment = Appointment.first
      assert_equal Client.first.client_id, appointment.client_id
      assert_equal Patient.first.patient_id, appointment.patient_id
    end
  end

  describe 'implicit objects' do
    test 'owner record is created for patient under client' do
      create_test_objects client: { patient: {} }
      owner = Owner.first
      assert_equal Client.first.client_id, owner.client_id
      assert_equal Patient.first.patient_id, owner.patient_id
    end
    test 'owner record created for client under patient' do
      create_test_objects patient: { client: {} }
      owner = Owner.first
      assert_equal Client.first.client_id, owner.client_id
      assert_equal Patient.first.patient_id, owner.patient_id
    end
    test 'owner record used under patient under client' do
      create_test_objects client: { patient: { owner: { percentage: 50 } } }
      owner = Owner.first
      assert_equal 1, Owner.count
      assert_equal 50, owner.percentage
      assert_equal Client.first.client_id, owner.client_id
      assert_equal Patient.first.patient_id, owner.patient_id
    end
    test 'owner record used under client under patient' do
      create_test_objects patient: { client: { owner: { percentage: 50 } } }
      owner = Owner.first
      assert_equal 1, Owner.count
      assert_equal 50, owner.percentage
      assert_equal Client.first.client_id, owner.client_id
      assert_equal Patient.first.patient_id, owner.patient_id
    end
    test 'membership created for practice under enterprise' do
      create_test_objects NO_DEFAULTS: true,
        source: { enterprise: { practice: {} } }
      member = EnterpriseMembership.first
      assert_equal Enterprise.first.id, member.enterprise_id
      assert_equal Practice.first.id, member.practice_id
    end
  end

  describe 'models inside modules' do
    test 'can create objects directly from class' do
      create_test_objects Schedule => {}
      assert_equal 1, Schedule.count
    end
    test 'class creation hooks up assocaitions' do
      create_test_objects schedule: {
        Schedule::Category => { appointment_length: 20 }
      }
      assert_equal 20, Schedule.first.categories.first.appointment_length
    end
    test 'can nest them' do
      create_test_objects schedule: {
        Schedule::Category => { appointment_length: 20,
          Schedule::Entry => { start_time: TimeOfDay.parse('8am') } }
      }
      assert_equal 1, Schedule.first.categories.first.entries.count
    end
  end

  test 'handles sync and non-sync classes intermixed' do
    create_test_objects(
      practice: { id: 6,
        client: { patient: { appointment: {} } } },
      user: { name: 'bob' } # doesn't crash w/ attempt to add practice_id
    )
    assert_equal 6, Client.first.practice_id
    assert_equal 6, Patient.first.practice_id
    assert_equal 6, Appointment.first.practice_id
  end
  test 'handles plural type names' do
    # doesn't blow up
    create_test_objects patients: [
      { reminder: {} },
      { reminder: {} },
    ]
  end
  test 'filter with settings' do
    # doesn't crash
    create_test_objects communication_setting: {
      type: 'AutomaticCommunicationSetting',
      filter: { type: 'ReminderTypeFilter', settings: { include: [] } }
    }
    refute_nil Filter.first.settings
  end

  # This was giving us trouble because there is a class called Content and a
  # field on Request called content.
  test 'request with content' do
    create_test_objects request: {
      type: :appointment,
      content: {
        date: '10/31/2018',
        comment: 'I want an appointment on Halloween!',
      }
    }
    refute_nil Request.first.content[:comment]
  end
end
