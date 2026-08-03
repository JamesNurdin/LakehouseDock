WITH sales_summary AS (
   SELECT
       cs.cs_item_sk,
       cs.cs_sold_date_sk,
       cs.cs_warehouse_sk,
       SUM(cs.cs_net_paid) AS total_net_paid,
       SUM(cs.cs_quantity) AS total_quantity
   FROM catalog_sales cs
   WHERE cs.cs_sold_date_sk BETWEEN 2451000 AND 2452000
   GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk, cs.cs_warehouse_sk
)
SELECT
   d.d_date,
   w.w_warehouse_name,
   w.w_county,
   i.inv_quantity_on_hand,
   sr.sr_return_tax,
   ss.total_net_paid,
   ss.total_quantity,
   CASE
       WHEN ss.total_net_paid > 10000 THEN 'High'
       WHEN ss.total_net_paid > 5000 THEN 'Medium'
       ELSE 'Low'
   END AS net_paid_category,
   (SELECT AVG(cs2.cs_net_paid)
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = ss.cs_item_sk) AS avg_item_net_paid,
   ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY ss.total_net_paid DESC) AS warehouse_rank,
   SUM(ss.total_net_paid) OVER (PARTITION BY w.w_warehouse_id ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_net_paid
FROM sales_summary ss
JOIN date_dim d
  ON ss.cs_sold_date_sk = d.d_date_sk
JOIN warehouse w
  ON ss.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory i
  ON i.inv_warehouse_sk = w.w_warehouse_sk
  AND i.inv_date_sk = d.d_date_sk
JOIN store_returns sr
  ON sr.sr_returned_date_sk = d.d_date_sk
WHERE w.w_warehouse_sq_ft > 600000
  AND w.w_county = 'Williamson County'
  AND i.inv_quantity_on_hand >= 800
  AND sr.sr_return_tax > 5.00
  AND d.d_year = 2001
ORDER BY ss.total_net_paid DESC
LIMIT 100
