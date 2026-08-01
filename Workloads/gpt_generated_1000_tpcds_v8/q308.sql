SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    p.p_promo_name,
    p.p_discount_active
FROM promotion p
JOIN item i
  ON p.p_item_sk = i.i_item_sk
WHERE i.i_class_id = 15
  AND p.p_purpose = 'Unknown'
  AND i.i_current_price > 50
ORDER BY i.i_current_price DESC
LIMIT 100
