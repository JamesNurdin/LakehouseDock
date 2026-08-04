SELECT i.i_item_id,
       i.i_product_name,
       i.i_current_price,
       p.p_promo_name,
       p.p_cost
FROM tpcds.item i
JOIN tpcds.promotion p
  ON p.p_item_sk = i.i_item_sk
WHERE i.i_class = 'hockey'
  AND p.p_channel_press = 'N'
LIMIT 100
