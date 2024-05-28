class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :sku
  has_one :product, through: :sku

  def total_price
    quantity * sku.product.sell_price
  end
end
