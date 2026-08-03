SELECT i.i_item_id,
       i.i_product_name,
       COUNT(p.p_promo_sk) AS promo_count
FROM tpcds.item i
JOIN tpcds.promotion p
  ON p.p_item_sk = i.i_item_sk
WHERE i.i_rec_start_date >= DATE '2000-01-01'
  AND i.i_item_desc LIKE '%Revolutionary%'
GROUP BY i.i_item_id, i.i_product_name
ORDER BY promo_count DESC
LIMIT 10
