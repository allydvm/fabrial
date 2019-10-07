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
    t.string :name
    t.timestamps null: false
  end

  create_table(:enterprise_memberships) do |t|
    t.integer :enterprise_id
    t.integer :practice_id
    t.timestamps null: false
  end

  create_table(:practices) do |t|
    t.string :name
    t.string :email
    t.string :address
    t.string :city
    t.string :state
    t.string :postal_code
    t.timestamps null: false
  end

  create_table(:employees) do |t|
    t.integer :source_id
    t.integer :appointment_id
    t.integer :practice_id
    t.integer :client_id
    t.integer :patient_id
    t.integer :employee_id
    t.string :first_name
    t.string :last_name
    t.timestamps null: false
  end

  create_table(:clients) do |t|
    t.integer :source_id
    t.integer :client_id
    t.integer :practice_id
    t.string :first_name
    t.string :last_name
    t.timestamps null: false
  end

  create_table(:patients) do |t|
    t.integer :source_id
    t.integer :patient_id
    t.integer :practice_id
    t.timestamps null: false
  end

  create_table(:owners) do |t|
    t.integer :source_id
    t.integer :owner_id
    t.integer :practice_id
    t.integer :client_id
    t.integer :patient_id
    t.timestamps null: false
  end

  create_table(:requests) do |t|
    t.integer :practice_id
    t.integer :source_id
    t.integer :client_id
    t.integer :patient_id
    t.timestamps null: false
  end

  create_table(:appointments) do |t|
    t.integer :source_id
    t.integer :appointment_id
    t.integer :practice_id
    t.integer :client_id
    t.integer :patient_id
    t.integer :employee_id
    t.timestamps null: false
  end

  create_table(:schedules) do |t|
    t.integer :practice_id
    t.timestamps null: false
  end
end

class Source < ActiveRecord::Base
  has_many :employeees
  has_many :clients
  has_many :patients
  has_many :requests
  has_many :appointments
  has_many :schedules
end

class Enterprise < ActiveRecord::Base
  has_many :enterprise_memberships
  has_many :practices, through: :enterprise_memberships
end

class EnterpriseMembership < ActiveRecord:Base
  belongs_to :enterprise
  belongs_to :practice
end

class Practice < ActiveRecord::Base
  has_many :enterprise_memberships
  has_many :enterprises, through: :enterprise_memberships
  has_many :clients
  has_many :patients
  has_many :owners
  has_many :requests
  has_many :appointments
  has_many :schedules
end

class Employee < ActiveRecord::Base
  belongs_to :source
  belongs_to :appointment
  belongs_to :practice
  belongs_to :client
  belongs_to :patient
end

class Client < ActiveRecord::Base
  belongs_to :source
  belongs_to :practice
end

class Patient < ActiveRecord::Base
  belongs_to :source
  belongs_to :practice
end

class Owner < ActiveRecord::Base
  belongs_to :source
  belongs_to :practice
  belongs_to :client
  belongs_to :patient
end

class Request < ActiveRecord::Base
  belongs_to :source
  belongs_to :practice
  belongs_to :client
  belongs_to :patient
end

class Appointment < ActiveRecord::Base
  belongs_to :source
  belongs_to :practice
  belongs_to :client
  belongs_to :patient
  belongs_to :employee
end

class Schedule < ActiveRecord::Base
  belongs_to :practice
end

class FabricateTest < ActiveSupport::TestCase
  describe 'return values' do
    test 'return top object (Practice) from single tree' do
      object = Fabrial.fabricate practice: { id: 5, client: {} }
      assert_equal 5, object.id
      assert_kind_of Practice, object
    end
    test 'return top object (not Practice) from single tree' do
      object = Fabrial.fabricate patient: { name: 'Red', reminder: {} }
      assert_equal 'Red', object.name
      assert_kind_of Patient, object
    end
    test 'return first object from list of trees' do
      object = Fabrial.fabricate(
        client: { last_name: 'Suzuki' },
        client_class: {},
      )
      assert_equal 'Suzuki', object.last_name
    end
    test 'return first object from first array of objects' do
      object = Fabrial.fabricate(
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
      object = Fabrial.fabricate client: { patient: {
        appointment: { RETURN: true }
      } }
      assert_instance_of Appointment, object
      object = Fabrial.fabricate client: { patient: {
        RETURN: true, appointment: {}
      } }
      assert_instance_of Patient, object
    end
    test 'returns list of specified objects' do
      app1, app2 = Fabrial.fabricate client: { patient: { appointments: [
        { notes: 'hi', RETURN: true },
        { notes: 'there', RETURN: true },
      ] } }
      assert_equal 'hi', app1.notes
      assert_equal 'there', app2.notes

      client, patient = Fabrial.fabricate client: {
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
      hash = Fabrial.fabricate client: {
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
      Fabrial.fabricate client: {}
      assert_equal MakeObjectTree::DEFAULT_PRACTICE_ID, Practice.first.id
    end
    test 'Default practice is used, if practice is not parent' do
      Fabrial.fabricate client: {}
      assert_equal MakeObjectTree::DEFAULT_PRACTICE_ID, Client.first.practice_id
    end
    test 'Parent practice is used' do
      Fabrial.fabricate practice: { id: 7, client: {} }
      assert_equal 7, Client.first.practice_id
    end
    test 'Given practice_id is used' do
      Fabrial.fabricate practice: { id: 2 }
      Fabrial.fabricate practice: { id: 3, client: { practice_id: 2 } }
      assert_equal 2, Client.first.practice_id
    end
    test 'Given practice object is used' do
      practice = Fabrial.fabricate practice: { id: 2 }
      Fabrial.fabricate practice: { id: 3, client: { practice: practice } }
      assert_equal 2, Client.first.practice_id
    end
    test 'specifying source attaches default practice' do
      Fabrial.fabricate source: { id: 2, client: {} }
      assert_equal 1, Source.count
      assert_equal 1, Practice.count # default created practice
      assert_equal 2, Practice.first.source_id
    end
    describe "doesn't create defaults if no_default: true" do
      test 'default source and practice created above enterprise' do
        Fabrial.fabricate enterprise: { source: { practice: {} } }
        assert_equal 2, Source.count
        assert_equal 2, Practice.count
      end
      test 'no defaults created' do
        Fabrial.fabricate NO_DEFAULTS: true,
          enterprise: { source: { practice: {} } }
        assert_equal 1, Source.count
        assert_equal 1, Practice.count
      end
    end
  end

  describe 'child connections' do
    test 'children are assigned to parent' do
      Fabrial.fabricate patient: { reminder: {} }
      assert_equal Patient.first.patient_id, Reminder.first.patient_id
    end
    test 'children are in parent`s practice' do
      Fabrial.fabricate patient: { reminder: {} }
      assert_equal MakeObjectTree::DEFAULT_PRACTICE_ID,
        Reminder.first.practice_id
      Fabrial.fabricate practice: { id: 4, patient: { reminder: {} } }
      assert_equal 4, Reminder.last.practice_id
    end
    test 'alerts tied to clients' do
      Fabrial.fabricate client: { alert: { type: 'InvalidEmailAlert' } }
      assert_equal Client.first.client_id, Alert.first.alertable_id
    end
    test 'alerts tied to patients' do
      Fabrial.fabricate patient: { alert: { type: 'PastDueReminderAlert' } }
      assert_equal Patient.first.patient_id, Alert.first.alertable_id
    end
    test 'comm record hooks up to reminders, appointments, patients' do
      Fabrial.fabricate patient: { communication_record: {} }
      assert_equal Patient.first.patient_id, CommunicationRecord.first.regarding_id
    end
    test 'parents can be specified by object' do
      practice = Fabrial.fabricate practice: { id: 9 }
      Fabrial.fabricate practice: { object: practice, client: {} }
      assert_equal 9, Client.first.practice_id
    end
  end

  describe 'many-to-many connections' do
    test 'appointment tied to patient under client' do
      Fabrial.fabricate client: { patient: { appointment: {} } }
      appointment = Appointment.first
      assert_equal Client.first.client_id, appointment.client_id
      assert_equal Patient.first.patient_id, appointment.patient_id
    end
    test 'appointment tied to client under patient' do
      Fabrial.fabricate patient: { client: { appointment: {} } }
      appointment = Appointment.first
      assert_equal Client.first.client_id, appointment.client_id
      assert_equal Patient.first.patient_id, appointment.patient_id
    end
  end

  describe 'implicit objects' do
    test 'owner record is created for patient under client' do
      Fabrial.fabricate client: { patient: {} }
      owner = Owner.first
      assert_equal Client.first.client_id, owner.client_id
      assert_equal Patient.first.patient_id, owner.patient_id
    end
    test 'owner record created for client under patient' do
      Fabrial.fabricate patient: { client: {} }
      owner = Owner.first
      assert_equal Client.first.client_id, owner.client_id
      assert_equal Patient.first.patient_id, owner.patient_id
    end
    test 'owner record used under patient under client' do
      Fabrial.fabricate client: { patient: { owner: { percentage: 50 } } }
      owner = Owner.first
      assert_equal 1, Owner.count
      assert_equal 50, owner.percentage
      assert_equal Client.first.client_id, owner.client_id
      assert_equal Patient.first.patient_id, owner.patient_id
    end
    test 'owner record used under client under patient' do
      Fabrial.fabricate patient: { client: { owner: { percentage: 50 } } }
      owner = Owner.first
      assert_equal 1, Owner.count
      assert_equal 50, owner.percentage
      assert_equal Client.first.client_id, owner.client_id
      assert_equal Patient.first.patient_id, owner.patient_id
    end
    test 'membership created for practice under enterprise' do
      Fabrial.fabricate NO_DEFAULTS: true,
        source: { enterprise: { practice: {} } }
      member = EnterpriseMembership.first
      assert_equal Enterprise.first.id, member.enterprise_id
      assert_equal Practice.first.id, member.practice_id
    end
  end

  describe 'models inside modules' do
    test 'can create objects directly from class' do
      Fabrial.fabricate Schedule => {}
      assert_equal 1, Schedule.count
    end
    test 'class creation hooks up assocaitions' do
      Fabrial.fabricate schedule: {
        Schedule::Category => { appointment_length: 20 }
      }
      assert_equal 20, Schedule.first.categories.first.appointment_length
    end
    test 'can nest them' do
      Fabrial.fabricate schedule: {
        Schedule::Category => { appointment_length: 20,
          Schedule::Entry => { start_time: TimeOfDay.parse('8am') } }
      }
      assert_equal 1, Schedule.first.categories.first.entries.count
    end
  end

  test 'handles sync and non-sync classes intermixed' do
    Fabrial.fabricate(
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
    Fabrial.fabricate patients: [
      { reminder: {} },
      { reminder: {} },
    ]
  end
  test 'filter with settings' do
    # doesn't crash
    Fabrial.fabricate communication_setting: {
      type: 'AutomaticCommunicationSetting',
      filter: { type: 'ReminderTypeFilter', settings: { include: [] } }
    }
    refute_nil Filter.first.settings
  end

  # This was giving us trouble because there is a class called Content and a
  # field on Request called content.
  test 'request with content' do
    Fabrial.fabricate request: {
      type: :appointment,
      content: {
        date: '10/31/2018',
        comment: 'I want an appointment on Halloween!',
      }
    }
    refute_nil Request.first.content[:comment]
  end
end