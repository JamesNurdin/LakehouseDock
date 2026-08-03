WITH
  -- Full outer join between store returns and the date dimension (allowed join rule)
  full_sr_date AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_return_amt,
      sr.sr_net_loss,
      d.d_year,
      d.d_month_seq,
      d.d_date_sk
    FROM store_returns sr
    FULL OUTER JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
  ),

  -- Core web‑sales related data, joining every remaining table in a left‑deep chain
  ws_core AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_ship_mode_sk,
      ws.ws_promo_sk,
      ws.ws_web_page_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      d.d_year,
      d.d_month_seq,
      t.t_hour,
      sm.sm_type,
      p.p_promo_name,
      p.p_discount_active,
      wp.wp_type,
      cc.cc_company,
      cc.cc_company_name
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN call_center cc
      ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000                      -- predicate 1
      AND t.t_hour BETWEEN 9 AND 17           -- predicate 2
      AND sm.sm_type = 'AIR'                  -- predicate 3
      AND p.p_discount_active = 'Y'          -- predicate 4
      AND wp.wp_type = 'HOME'                 -- predicate 5
      AND cc.cc_company = 3                  -- predicate 6
  ),

  -- First branch: aggregates from web sales
  sales_agg AS (
    SELECT
      d_year AS year,
      d_month_seq AS month,
      SUM(ws_ext_sales_price) AS sales_amount,
      SUM(ws_net_profit) AS profit,
      COUNT(*) AS order_cnt,
      CASE
        WHEN SUM(ws_ext_sales_price) > (SELECT MAX(p_cost) FROM promotion) THEN 'HIGH'
        ELSE 'LOW'
      END AS sales_category
    FROM ws_core
    GROUP BY d_year, d_month_seq
  ),

  -- Second branch: aggregates from store returns (through the full outer join CTE)
  returns_agg AS (
    SELECT
      d_year AS year,
      d_month_seq AS month,
      -SUM(COALESCE(sr_return_amt, 0)) AS sales_amount,   -- returns reduce sales
      -SUM(COALESCE(sr_net_loss, 0)) AS profit,
      COUNT(*) AS order_cnt,
      CASE
        WHEN -SUM(COALESCE(sr_return_amt, 0)) > (SELECT MAX(p_cost) FROM promotion) THEN 'HIGH'
        ELSE 'LOW'
      END AS sales_category
    FROM full_sr_date
    WHERE sr_return_amt IS NOT NULL
    GROUP BY d_year, d_month_seq
  ),

  -- Union of the two branches (deduped by UNION)
  union_data AS (
    SELECT * FROM sales_agg
    UNION
    SELECT * FROM returns_agg
  )

SELECT
  ud.year,
  ud.month,
  SUM(ud.sales_amount) AS total_sales,
  SUM(ud.profit) AS total_profit,
  SUM(ud.order_cnt) AS total_orders,
  CASE
    WHEN SUM(ud.sales_amount) > 0 THEN 'POS'
    ELSE 'NEG'
  END AS overall_sign,
  COUNT(DISTINCT ud.sales_category) AS category_variants
FROM union_data ud
WHERE ud.year BETWEEN 1999 AND 2001               -- additional filter 1
  AND ud.month IN (1, 2, 3, 4, 5)                  -- additional filter 2
  AND ud.sales_category = 'HIGH'                  -- additional filter 3
GROUP BY ud.year, ud.month
ORDER BY total_sales DESC
LIMIT 100
