SELECT i_brand,
       i_brand_id,
       COUNT(*) AS item_count,
       AVG(i_current_price) AS avg_price
FROM tpcds.item
WHERE i_units = 'Dozen'
  AND i_rec_end_date > DATE '2000-01-01'
GROUP BY i_brand, i_brand_id
ORDER BY avg_price DESC
LIMIT 10
