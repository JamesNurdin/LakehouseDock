SELECT i.i_item_id,
       i.i_product_name,
       p.p_promo_name,
       p.p_cost,
       i.i_current_price
FROM promotion AS p
JOIN item AS i
  ON p.p_item_sk = i.i_item_sk
WHERE i.i_class_id = 7
  AND i.i_rec_start_date >= DATE '2000-01-01'
  AND p.p_channel_email = 'N'
ORDER BY p.p_cost DESC
LIMIT 100
