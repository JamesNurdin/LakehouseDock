WITH
  -- Sample a fraction of catalog sales and apply selective filters
  sampled_catalog_sales AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND cs_quantity > 1
      AND cs_sales_price > 20.00
  ),

  -- Intersect order numbers that appear in both returns and sales (with additional filters)
  returns_intersect AS (
    SELECT cr_order_number AS order_num
    FROM catalog_returns
    WHERE cr_return_quantity > 0
    INTERSECT
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 2
  ),

  -- Join sampled catalog sales to ship mode and time, left‑joining possible returns
  catalog_joined AS (
    SELECT
      cs.cs_sold_time_sk,
      cs.cs_ship_mode_sk,
      cs.cs_order_number,
      cs.cs_net_paid,
      sm.sm_code,
      td.t_hour,
      cr.cr_return_quantity,
      cr.cr_return_amount
    FROM sampled_catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td   ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
     AND cs.cs_ship_mode_sk = cr.cr_ship_mode_sk
    WHERE sm.sm_code = 'AIR'
  ),

  -- Store sales narrowed to California stores and joined to time
  store_sales_sub AS (
    SELECT
      ss.ss_sold_time_sk,
      ss.ss_store_sk,
      ss.ss_ticket_number,
      ss.ss_net_profit,
      ss.ss_quantity,
      st.s_state,
      td.t_hour
    FROM store_sales ss
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE st.s_state = 'CA'
      AND ss.ss_quantity >= 2
  ),

  -- Web sales restricted to home pages and joined to time
  web_sales_sub AS (
    SELECT
      ws.ws_sold_time_sk,
      ws.ws_web_page_sk,
      ws.ws_net_profit,
      ws.ws_quantity,
      wp.wp_type,
      td.t_hour
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE wp.wp_type = 'home'
      AND ws.ws_quantity >= 2
  ),

  -- Full outer join of store and web sales on the common time key
  full_joined AS (
    SELECT
      COALESCE(ss.ss_sold_time_sk, ws.ws_sold_time_sk) AS sold_time_sk,
      ss.ss_store_sk,
      ws.ws_web_page_sk,
      ss.ss_net_profit AS store_profit,
      ws.ws_net_profit AS web_profit,
      ss.ss_quantity AS store_qty,
      ws.ws_quantity AS web_qty,
      ss.s_state,
      ws.wp_type
    FROM store_sales_sub ss
    FULL OUTER JOIN web_sales_sub ws
      ON ss.ss_sold_time_sk = ws.ws_sold_time_sk
  )

SELECT
  fj.sold_time_sk,
  COUNT(DISTINCT fj.ss_store_sk) AS distinct_store_cnt,
  SUM(COALESCE(fj.store_profit, 0)) AS total_store_profit,
  SUM(COALESCE(fj.web_profit,   0)) AS total_web_profit,
  SUM(CASE WHEN fj.s_state = 'CA' THEN fj.store_profit ELSE 0 END) AS ca_store_profit,
  SUM(CASE WHEN fj.wp_type = 'home' THEN fj.web_profit ELSE 0 END) AS home_web_profit,
  COUNT(*) AS total_rows,
  -- Example aggregation using the intersected order numbers
  COUNT(DISTINCT cj.cs_order_number) FILTER (WHERE cj.cs_order_number IN (SELECT order_num FROM returns_intersect)) AS intersected_orders_cnt,
  -- Example CASE expression on ship mode code from catalog data
  SUM(CASE WHEN cj.sm_code = 'AIR' THEN cj.cs_net_paid ELSE 0 END) AS air_mode_net_paid
FROM full_joined fj
JOIN catalog_joined cj
  ON fj.sold_time_sk = cj.cs_sold_time_sk
WHERE fj.sold_time_sk NOT IN (
        SELECT t_time_sk FROM time_dim WHERE t_hour = 0
      )
GROUP BY fj.sold_time_sk
ORDER BY total_store_profit DESC
LIMIT 100
