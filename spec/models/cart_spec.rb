require 'rails_helper'

RSpec.describe Cart, type: :model do
  let(:cart) { Cart.new }
  context "基本功能" do 
    it "把商品放入購物車，購物車會顯示商品種類" do
      cart.add_sku(2)
      # expect(cart.empty?).to be false
      expect(cart).not_to be_empty
    end

    it "加了相同商品到購物車，購買項目並不會增加，但商品的數量會改變" do

      3.times { cart.add_sku(1) }
      2.times { cart.add_sku(2) }

      expect(cart.items.count).to be 2
      expect(cart.items.first.quantity).to be 3
    end

    it "商品可以放到購物車裡，在拿出來" do

      # v1 = Vendor.create(title: 'v1')
      # p1 = Product.create(name: '吉卜力', list_price: 10, sell_price: 5, vendor: v1)
      p1 = FactoryBot.create(:product, :with_skus)
      cart.add_sku(p1.skus.first.id)

      expect(cart.items.first.product).to be_a Product
    end

    it "計算整台購物車總和" do

      p1 = FactoryBot.create(:product, :with_skus, sell_price: 5)
      p2 = FactoryBot.create(:product, :with_skus, sell_price: 10)

      3.times { cart.add_sku(p1.skus.first.id) }
      2.times { cart.add_sku(p2.skus.first.id) }

      expect(cart.total_price).to eq 35
    end

  end

  context "進階功能" do
    it "將購物車內容轉換成hash並存到session裡" do

      p1 = FactoryBot.create(:product, :with_skus)
      p2 = FactoryBot.create(:product, :with_skus)

      3.times { cart.add_sku(p1.id) }
      2.times { cart.add_sku(p2.id) }


      expect(cart.serialize).to eq cart_hash
    end

    it "存放在session裡面的內容（hash格式），還原成購物車內容" do
      cart = Cart.from_hash(cart_hash)
      
      expect(cart.items.first.quantity).to be 3
    end
  end

  private
  def cart_hash
    {
      "items" => [
        { "sku_id" => 1, "quantity" => 3 },
        { "sku_id" => 2, "quantity" => 2 }
      ]
    }
  end
end
