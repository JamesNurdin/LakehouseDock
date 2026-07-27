WITH
  base AS (
    SELECT
      d.d_year,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      p.p_discount_active,
      sm.sm_type,
      s.s_state,
      c.c_preferred_cust_flag,
      wp.wp_type,
      ws.ws_net_paid,
      ws.ws_ext_discount_amt,
      ws.ws_quantity,
      sr.sr_return_quantity,
      sr.sr_net_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_customer_sk = c.c_customer_sk
     AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2002
      AND i.i_category = 'Sports'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND s.s_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND wp.wp_type = 'Content'
  ),
  agg1 AS (
    SELECT
      d_year,
      i_category,
      s_state,
      SUM(ws_net_paid) AS total_net_paid,
      SUM(ws_ext_discount_amt) AS total_discount,
      SUM(sr_net_loss) AS total_net_loss,
      COUNT(DISTINCT ws_quantity) AS distinct_qty,
      CASE WHEN SUM(ws_net_paid) > 500000 THEN 'HIGH' ELSE 'LOW' END AS revenue_flag
    FROM base
    GROUP BY GROUPING SETS (
      (d_year, i_category, s_state),
      (d_year, i_category),
      (d_year),
      ()
    )
  ),
  agg2 AS (
    SELECT
      i_brand,
      p_promo_name,
      SUM(ws_net_paid) AS total_net_paid,
      SUM(ws_ext_discount_amt) AS total_discount,
      COUNT(DISTINCT ws_quantity) AS distinct_qty,
      CASE WHEN SUM(ws_ext_discount_amt) > 100000 THEN 'BIG_DISCOUNT' ELSE 'SMALL_DISCOUNT' END AS discount_level
    FROM base
    GROUP BY GROUPING SETS (
      (i_brand, p_promo_name),
      (i_brand),
      ()
    )
  ),
  combined AS (
    SELECT
      CAST(d_year AS VARCHAR) AS level1,
      i_category AS level2,
      s_state AS level3,
      total_net_paid,
      total_discount,
      CAST(total_net_loss AS DOUBLE) AS metric,
      distinct_qty,
      revenue_flag AS flag
    FROM agg1
    UNION ALL
    SELECT
      NULL AS level1,
      i_brand AS level2,
      p_promo_name AS level3,
      total_net_paid,
      total_discount,
      NULL AS metric,
      distinct_qty,
      discount_level AS flag
    FROM agg2
  )
SELECT DISTINCT
  level1,
  level2,
  level3,
  total_net_paid,
  total_discount,
  metric,
  distinct_qty,
  flag
FROM combined
ORDER BY total_net_paid DESC
LIMIT 100
