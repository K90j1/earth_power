require 'spec_helper'

describe EarthPower do
  it 'has a version number' do
    expect(EarthPower::VERSION).not_to be nil
  end

  let(:target) { Struct.new(:earth_power) { include EarthPower } }
  purchase = 1000
  base_cost = 0
  current_price = 0
  binding = '本'
  sipping_fee = 0
  is_fba = 1
  is_large_business = 0
  is_media = 0
  storage_days = 1
  weight = 281
  volume = [18, 150, 210]
  let(:earth_power) { target.new(purchase\
    , base_cost, current_price, binding\
    , sipping_fee, is_fba, is_large_business, is_media\
    , storage_days, weight, volume) }

  describe '.get_profit' do
    it '514' do
      expect(earth_power.get_profit).to eql 514
    end
  end
end