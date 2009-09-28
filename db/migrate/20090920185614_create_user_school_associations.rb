class CreateUserSchoolAssociations < ActiveRecord::Migration
  def self.up
    create_table :user_school_associations do |t|
      t.integer :user_id
      t.integer :school_id
      t.integer :role_id
      t.integer :access_key_id
      t.timestamps
    end
  end

  def self.down
    drop_table :user_school_associations
  end
end
