SELECT i.i_category,
       sum(ss.ss_quantity) AS total_quantity,
       sum(ss.ss_quantity * i.i_price) AS total_revenue,
       avg(i.i_price) AS avg_price
FROM store_sales ss
JOIN items i
  ON ss.ss_item_id = i.i_item_id
WHERE i.i_price > 20.00
GROUP BY i.i_category
HAVING sum(ss.ss_quantity) > 100
ORDER BY total_revenue DESC
