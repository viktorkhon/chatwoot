class AddShopifyNameAndVectorDatabaseNamespaceToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :shopify_name, :string
    add_column :accounts, :vector_database_namespace, :string
  end
end 