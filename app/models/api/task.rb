class Api::Task < ApplicationRecord
  self.table_name = "tasks"

  belongs_to :user, optional: true
end
