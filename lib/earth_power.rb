require 'earth_power/version'
#
#= EarthPower
#
#Authors::   K90j1
#Version::   1.0 2016-03-28
#License::   MIT
#See:: https://services.amazon.co.jp/home.html
#

STORAGE_COEFFICIENT = 8.126
STORAGE_VALUE = 1000
CONTRACT_FEE = 100
SIPPING_TYPE_KEYS = [0, 1, 2, 3, 4, 5, 6, 7, 8]
SIPPING_TYPE_PACKING = {0 => 525, 1 => 567, 2 => 603, 3 => 1250, 4 => 0, 5 => 87, 6 => 87, 7 => 77, 8 => 99}
SIPPING_TYPE_WEIGHT = {0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 57, 6 => 85, 7 => 166, 8 => 228}
INCHES_TO_MM = 0.254
POUNDS_TO_G = 4.53592
CARRY_OVER_KG = 6

module EarthPower
  @earnings = 0
  @purchase = 0
  @category = ''
  @sipping_fee = 0
  @storage_days = 0
  @weight = 0
  @weight_pattern = 0
  @volume = []
  @volume_pattern = 0
  @total_volume = 0
  @base_cost = 0
  @is_fba = 0
  @is_large_business = 0
  @is_media = 0
  @is_large_item = 0
  @total_volume = 0

  #
  #= カテゴリー成約料
  #params earnings
  #params base_cost
  #params purchase
  #params category
  #params sipping_fee
  #params is_fba
  #params is_large_business
  #params is_media
  #params storage_days
  #params weight
  #params volume[]
  #
  def initialize(earnings, base_cost, purchase, category, sipping_fee, is_fba, is_large_business, is_media, storage_days, weight, volume)
    @earnings = earnings.to_i
    @purchase = purchase.to_i
    @category = category
    @sipping_fee = sipping_fee.to_i
    @is_fba = is_fba.to_i
    @is_media = is_media.to_i
    @volume = volume.clone
    @volume_pattern = get_volume_pattern volume
    @weight = weight.to_i
    @weight_pattern = get_weight_pattern weight.to_i
    @storage_days = storage_days.to_i
    @is_large_business = is_large_business.to_i
    @base_cost = base_cost.to_i
    @total_volume = @volume[0].to_f * @volume[1].to_f * @volume[2].to_f / 1000
  end

  def get_profit
    return 0 if @earnings == 0
    contract_fee = get_contract_fee
    category_fee = get_category_fee
    sales_charge = get_sales_charge
    storage_fee = 0
    agent_sipping_fee = 0
    if @is_fba == 1
      storage_fee = get_storage_fee
      agent_sipping_fee = get_agent_sipping_fee
    end
    result = @earnings - @purchase - contract_fee - category_fee - sales_charge -storage_fee - agent_sipping_fee - @base_cost - @sipping_fee
    result.ceil
  end

  def self.get_default_volume(value)
    case value.to_i
      when 0
        return [250, 180, 20]
      when 1
        return [450, 350, 200]
      when 2
        return [300, 300, 400]
      when 3
        return [400, 400, 600]
      when 4
        return [500, 500, 700]
      else
        return [600, 600, 800]
    end
  end

  def self.get_default_weight(value)
    case value.to_i
      when 0
        return 249
      when 1
        return 4500
      else
        return 9000
    end
  end

  def self.convert_inches_mm(value)
    value.to_f * INCHES_TO_MM.to_f
  end

  def self.convert_pounds_g(value)
    value.to_f * POUNDS_TO_G.to_f
  end

  #
  #= WEIGHT PATTERN
  # 250g未満, 9kg未満, 9kg以上
  #
  def get_weight_pattern(weight)
    if weight < 250
      0
    elsif weight < 9000
      1
    else
      2
    end
  end

  #
  #= VOLUME PATTERN
  #params Array[height, length, width]
  # 25x18x2, 45x35x20, 100(30x30x40), 140(40x40x60), 170(50x50x70), 200(60x60x80)
  #
  def get_volume_pattern(volume)
    return 0 if recursive_measuring(volume, [250, 180, 20])
    return 1 if recursive_measuring(volume, [450, 350, 200])
    return 2 if recursive_measuring(volume, [300, 300, 400])
    return 3 if recursive_measuring(volume, [400, 400, 600])
    return 4 if recursive_measuring(volume, [500, 500, 700])
    5
  end

  private
  def recursive_measuring(exactly, expected)
    return true if exactly.empty?
    result = false
    exactly.each_with_index do |value, key|
      expected.each_with_index do |pattern, pattern_key|
        if value <= pattern
          exactly.delete_at key
          expected.delete_at pattern_key
          result = recursive_measuring(exactly, expected)
        end
      end
    end
    result
  end

  #
  #= カテゴリー成約料
  #see https://www.amazon.co.jp/gp/help/customer/display.html?nodeId=1085246
  #
  def get_category_fee
    case @category
      when '本', '洋書', 'コミック', '雑誌', '古本・古書'
        @is_media = 1
        category_fee = 60
      when 'ミュージック', 'DVD', 'PCソフト', 'ゲーム'
        @is_media = 1
        category_fee = 140
      when 'VHS'
        @is_media = 1
        category_fee = 30
      else
        @is_media = 0
        # category_fee = 100
        category_fee = 0
    end
    category_fee
  end

  #
  #= 販売手数料
  #see https://www.amazon.co.jp/gp/help/customer/display.html?nodeId=1085246
  #
  def get_sales_charge
    earnings = @earnings
    case @category
      when '大型家電', 'パソコン・周辺機器', '楽器・音響機器'
        charge = earnings.to_i * 0.08
      when '本', '洋書', 'コミック', '雑誌', '古本・古書', 'ミュージック', 'VHS', 'DVD', 'ゲーム', 'PCソフト', '文房具・オフィス用品', 'ホーム＆キッチン', 'DIY・工具', 'ホビー', 'おもちゃ', 'スポーツ＆アウトドア', '車＆バイク', 'ベビー＆マタニティ'
        charge = earnings.to_i * 0.15
      when 'Kindleストア'
        charge = earnings.to_i * 0.45
      else
        charge = earnings.to_i * 0.10
    end
    charge
  end

  #
  #= 基本成約料
  #
  def get_contract_fee
    return 0 if @is_large_business == 1
    CONTRACT_FEE
  end

  #
  #= 在庫保管手数料
  #
  def get_storage_fee
    STORAGE_COEFFICIENT.to_f * ((@total_volume) / STORAGE_VALUE.to_f) * @storage_days
  end

  #
  #= 配送代行手数料
  # 出荷作業手数料
  # 発送重量手数料
  #
  def get_agent_sipping_fee
    type = get_agent_sipping_type
    weight = SIPPING_TYPE_WEIGHT[type]
    coefficient = 0
    if (type == 6 || type == 8) && (@weight - 2000) > 0
      coefficient = (@weight - 2000) / 1000
    end
    weight += coefficient.ceil * CARRY_OVER_KG.to_i
    # ApiRequest.logging("出荷作業手数料 #{SIPPING_TYPE_PACKING[type]}")
    # ApiRequest.logging("発送重量手数料 #{weight}")
    SIPPING_TYPE_PACKING[type].to_i + weight.to_i
  end

  def is_expensive
    return true if @earnings > 45000 && @is_large_item == 0
    false
  end

  #
  #= 区分
  # 大型区分1, 大型区分2, 大型区分3, 特殊大型, 高額商品, メディア小型, メディア標準, メディア以外小型, メディア以外標準
  #
  def get_agent_sipping_type
    if @weight_pattern == 2
      @is_large_item = true
      case @volume_pattern
        when 3
          return SIPPING_TYPE_KEYS[1]
        when 4
          return SIPPING_TYPE_KEYS[2]
        when 5
          return SIPPING_TYPE_KEYS[3]
        else
          return SIPPING_TYPE_KEYS[0]
      end
    end
    if is_expensive
      return SIPPING_TYPE_KEYS[4]
    end
    if @is_media == 1
      case @volume_pattern
        when 0
          return SIPPING_TYPE_KEYS[5]
        else
          return SIPPING_TYPE_KEYS[6]
      end
    end
    case @volume_pattern
      when 0
        return SIPPING_TYPE_KEYS[7]
      else
        return SIPPING_TYPE_KEYS[8]
    end
  end
end