class AddInboundWebhooks < ActiveRecord::Migration[7.0]
  def change
    create_table :inbound_webhooks do |t|
      t.string :status, default: "pending", null: false
      t.text :body
      t.references :school, null: false, foreign_key: true

      t.timestamps
    end
  end
end
