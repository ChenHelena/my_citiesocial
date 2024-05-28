require 'rails_helper'

RSpec.describe Vendor, type: :model do
  it "有填寫" do
    vendor = Vendor.new(title: 'Hello')
    expect(vendor).to be_valid
  end
  it "沒有填寫" do
    vendor = Vendor.new
    expect(vendor).not_to be_valid
  end
end
