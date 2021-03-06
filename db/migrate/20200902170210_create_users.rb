class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    begin
      enable_extension "citext"
    rescue ActiveRecord::StatementInvalid
    end

    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.citext :email
      t.string :sso_guid

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :sso_guid, unique: true
  end
end
