WITH
  intersect_orders AS (
    SELECT order_number FROM (
      SELECT cs_order_number AS order_number FROM catalog_sales WHERE cs_quantity > 10
    ) INTERSECT
    SELECT ws_order_number AS order_number FROM web_sales WHERE ws_quantity > 10
  ),
  catalog_unnest AS (
    SELECT
      cs.cs_order_number,
      ca.ca_state,
      p.p_promo_name,
      sm.sm_type,
      cs.cs_net_paid,
      cs.cs_net_paid_inc_tax,
      cs.cs_net_paid_inc_ship_tax,
      d.d_year,
      ss.ss_net_paid AS store_net_paid,
      ws.ws_net_paid AS web_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 2002
      AND p.p_promo_name = 'Holiday Sale'
      AND sm.sm_type = 'AIR'
      AND ss.ss_store_sk = 16
      AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  ),
  unnested_sales AS (
    SELECT
      cs_order_number,
      ca_state,
      p_promo_name,
      sm_type,
      val AS sales_val,
      store_net_paid,
      web_net_paid
    FROM catalog_unnest
    CROSS JOIN UNNEST(ARRAY[cs_net_paid, cs_net_paid_inc_tax, cs_net_paid_inc_ship_tax]) AS t(val)
  )
SELECT
  ca_state,
  p_promo_name,
  sm_type,
  SUM(sales_val) AS total_catalog_sales,
  SUM(store_net_paid) AS total_store_sales,
  SUM(web_net_paid) AS total_web_sales,
  COUNT(DISTINCT cs_order_number) AS order_count
FROM unnested_sales us
JOIN intersect_orders io ON us.cs_order_number = io.order_number
GROUP BY ca_state, p_promo_name, sm_type
ORDER BY total_catalog_sales DESC
LIMIT 100
