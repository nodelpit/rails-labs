class RenameApiTokensToTokens < ActiveRecord::Migration[8.0]
  def change
    rename_table :api_tokens, :tokens
  end
end
