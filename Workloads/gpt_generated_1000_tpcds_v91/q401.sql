SELECT i_brand,
       COUNT(*) AS brand_item_count,
       AVG(i_current_price) AS avg_current_price
FROM tpcds.item
WHERE i_rec_start_date >= DATE '2000-01-01'
  AND i_container = 'Unknown'
GROUP BY i_brand
ORDER BY avg_current_price DESC
