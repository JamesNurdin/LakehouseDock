WITH cs_sample AS (
  SELECT *
  FROM catalog_sales
  TABLESAMPLE BERNOULLI (5)
),
agg_inventory AS (
  SELECT inv_item_sk,
         inv_date_sk,
         SUM(inv_quantity_on_hand) AS total_qty_on_hand
  FROM inventory
  GROUP BY inv_item_sk,
           inv_date_sk
)
SELECT
  ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS row_num,
  s.s_store_id,
  s.s_state,
  d.d_year,
  sm.sm_type,
  i.i_brand,
  COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  SUM(cs.cs_ext_discount_amt) AS total_discount,
  SUM(ai.total_qty_on_hand) AS total_inventory,
  AVG(cs.cs_sales_price) AS avg_unit_price
FROM agg_inventory ai
JOIN cs_sample cs
  ON cs.cs_item_sk = ai.inv_item_sk
 AND cs.cs_sold_date_sk = ai.inv_date_sk
JOIN store_sales ss
  ON ss.ss_item_sk = cs.cs_item_sk
 AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
JOIN web_returns wr
  ON wr.wr_item_sk = cs.cs_item_sk
 AND wr.wr_returned_date_sk = cs.cs_sold_date_sk
JOIN date_dim d
  ON d.d_date_sk = cs.cs_sold_date_sk
JOIN time_dim t
  ON t.t_time_sk = cs.cs_sold_time_sk
JOIN customer c
  ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN customer_address ca
  ON ca.ca_address_sk = c.c_current_addr_sk
JOIN item i
  ON i.i_item_sk = cs.cs_item_sk
JOIN promotion p
  ON p.p_promo_sk = cs.cs_promo_sk
JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN store s
  ON s.s_store_sk = ss.ss_store_sk
WHERE
  s.s_state = 'CA'
  AND d.d_year = 2001
  AND sm.sm_type = 'EXPRESS'
  AND EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = cs.cs_item_sk
      AND wr2.wr_returned_date_sk = cs.cs_sold_date_sk
  )
GROUP BY
  s.s_store_id,
  s.s_state,
  d.d_year,
  sm.sm_type,
  i.i_brand
ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
