# Report the stock levels of:
#   - all variants in the order
#   - all requested variant ids
require 'open_food_network/scope_variant_to_hub'

class VariantsStockLevels
  def call(order, requested_variant_ids)
    variant_stock_levels = variant_stock_levels(order.line_items)

    order_variant_ids = variant_stock_levels.keys
    missing_variant_ids = requested_variant_ids - order_variant_ids
    missing_variant_ids.each do |variant_id|
      variant = scoped_variant(order.distributor, Spree::Variant.find(variant_id))
      variant_stock_levels[variant_id] = { quantity: 0, max_quantity: 0, on_hand: variant.on_hand, on_demand: variant.on_demand }
    end

    variant_stock_levels
  end

  private

  def variant_stock_levels(line_items)
    Hash[
      line_items.map do |line_item|
        variant = scoped_variant(line_item.order.distributor, line_item.variant)

        [variant.id,
         { quantity: line_item.quantity,
           max_quantity: line_item.max_quantity,
           on_hand: variant.on_hand,
           on_demand: variant.on_demand }]
      end
    ]
  end

  def scoped_variant(distributor, variant)
    return variant if distributor.blank?

    scoper(distributor).scope(variant)
    variant
  end

  def scoper(distributor)
    @scoper ||= OpenFoodNetwork::ScopeVariantToHub.new(distributor)
  end
end
