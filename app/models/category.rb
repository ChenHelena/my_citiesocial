class Category < ApplicationRecord
  acts_as_paranoid
  acts_as_list

  default_scope { order(position: :asc)}

  has_many :products
  validates :name, presence: true
end
