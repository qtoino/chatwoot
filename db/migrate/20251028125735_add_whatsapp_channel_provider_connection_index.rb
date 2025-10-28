class AddWhatsappChannelProviderConnectionIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :channel_whatsapp, :provider_connection,
              using: :gin,
              where: "provider IN ('baileys', 'zapi')",
              name: 'index_channel_whatsapp_provider_connection',
              algorithm: :concurrently
  end
end
