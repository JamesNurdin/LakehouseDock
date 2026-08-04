SELECT i_brand,
       COUNT(*) AS brand_item_cnt,
       AVG(i_current_price) AS avg_price
FROM tpcds.item
WHERE i_brand IN ('edu packimporto #2', 'exportiimporto #1')
  AND i_current_price > 50.00
GROUP BY i_brand
ORDER BY brand_item_cnt DESC
