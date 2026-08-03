/*
  Goal: Analyze high‑value items shipped via the AIRBORNE carrier that have both a high list price and zero shipping cost, aggregating sales, discounts, distinct customers, and ranking items by total sales.
*/
WITH high_price_items AS (
  SELECT cs_item_sk
  FROM tpcds.catalog_sales
  WHERE cs_ext_list_price > 4000
    AND cs_ship_mode_sk = 1
),
zero_ship_cost_items AS (
  SELECT cs_item_sk
  FROM tpcds.catalog_sales
  WHERE cs_ext_ship_cost = 0
    AND cs_ship_mode_sk = 2
),
intersect_items AS (
  SELECT cs_item_sk FROM high_price_items
  INTERSECT
  SELECT cs_item_sk FROM zero_ship_cost_items
),
sales_agg AS (
  SELECT
    cs.cs_item_sk,
    sm.sm_carrier,
    i.i_units,
    SUM(cs.cs_ext_sales_price)               AS total_sales,
    AVG(cs.cs_ext_discount_amt)              AS avg_discount,
    COUNT(DISTINCT cs.cs_bill_customer_sk)   AS distinct_bill_customers,
    COUNT(DISTINCT cs.cs_ship_customer_sk)   AS distinct_ship_customers,
    MIN(cs.cs_ext_ship_cost)                 AS min_ship_cost,
    MAX(cs.cs_ext_ship_cost)                 AS max_ship_cost
  FROM tpcds.catalog_sales cs
  JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN intersect_items ii
    ON cs.cs_item_sk = ii.cs_item_sk
  WHERE sm.sm_carrier = 'AIRBORNE'
    AND i.i_units = 'Ton'
    AND cs.cs_ext_list_price > 3000
  GROUP BY cs.cs_item_sk, sm.sm_carrier, i.i_units
)
SELECT
  s.cs_item_sk,
  s.sm_carrier,
  s.i_units,
  s.total_sales,
  s.avg_discount,
  s.distinct_bill_customers,
  s.distinct_ship_customers,
  s.min_ship_cost,
  s.max_ship_cost,
  (
    SELECT SUM(cs2.cs_net_profit)
    FROM tpcds.catalog_sales cs2
    WHERE cs2.cs_item_sk = s.cs_item_sk
  ) AS total_net_profit,
  RANK() OVER (PARTITION BY s.sm_carrier ORDER BY s.total_sales DESC) AS sales_rank
FROM sales_agg s
ORDER BY s.total_sales DESC
LIMIT 100
