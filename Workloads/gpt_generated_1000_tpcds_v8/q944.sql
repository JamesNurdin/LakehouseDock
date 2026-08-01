SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    p.p_promo_name,
    p.p_cost
FROM tpcds.promotion p
JOIN tpcds.item i
  ON p.p_item_sk = i.i_item_sk
WHERE i.i_brand_id = 3002001
  AND p.p_channel_email = 'N'
ORDER BY p.p_cost DESC
