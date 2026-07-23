WITH distinct_promos AS (
  SELECT DISTINCT p.p_promo_sk, p.p_promo_name
  FROM promotion p
  WHERE p.p_discount_active = 'Y'
),
sales_agg AS (
  SELECT
    i.i_brand AS brand,
    sm.sm_type AS ship_type,
    d_sold.d_year AS year,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ss.ss_net_paid) AS total_store_paid,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN distinct_promos dp ON cs.cs_promo_sk = dp.p_promo_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
   AND ss.ss_item_sk = i.i_item_sk
   AND ss.ss_customer_sk = c_bill.c_customer_sk
   AND ss.ss_hdemo_sk = hd_bill.hd_demo_sk
   AND ss.ss_promo_sk = dp.p_promo_sk
  WHERE d_sold.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND sm.sm_type = 'AIR'
    AND w.w_state = 'CA'
  GROUP BY i.i_brand, sm.sm_type, d_sold.d_year
)
SELECT
  brand,
  ship_type,
  year,
  total_catalog_profit,
  total_store_paid,
  distinct_orders,
  distinct_tickets,
  (total_catalog_profit + total_store_paid) / (distinct_orders + distinct_tickets) AS avg_profit_per_transaction
FROM sales_agg
WHERE (total_catalog_profit + total_store_paid) > 10000
ORDER BY avg_profit_per_transaction DESC
LIMIT 100
