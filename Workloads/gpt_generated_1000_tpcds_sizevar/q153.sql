WITH
  -- Fact table and its direct dimensions (star topology)
  cs AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_net_profit,
      d.d_year,
      t.t_am_pm,
      sm.sm_ship_mode_id,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN time_dim t               ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk  = sm.sm_ship_mode_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND t.t_am_pm = 'PM'
      AND sm.sm_type = 'AIR'
      AND ib.ib_lower_bound >= 50000
      AND cs.cs_quantity > 5
      AND cs.cs_net_paid > 1000
  ),

  -- Catalog returns linked to the fact table
  cr AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      d.d_year,
      t.t_meal_time,
      sm.sm_ship_mode_id,
      hd.hd_income_band_sk,
      ib.ib_upper_bound
    FROM catalog_returns cr
    JOIN catalog_sales cs        ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t               ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm             ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND t.t_meal_time = 'dinner'
      AND cr.cr_return_amount > 50
      AND cr.cr_return_quantity > 1
      AND sm.sm_type = 'AIR'
  ),

  -- Store returns linked through shared dimensions
  sr AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_amt,
      d.d_year,
      t.t_am_pm,
      hd.hd_income_band_sk,
      ib.ib_lower_bound
    FROM store_returns sr
    JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t               ON sr.sr_return_time_sk   = t.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk        = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND t.t_am_pm = 'PM'
      AND sr.sr_return_amt > 30
  ),

  -- Web sales linked to the fact table
  ws AS (
    SELECT
      ws.ws_order_number,
      ws.ws_net_paid,
      d.d_year,
      t.t_meal_time,
      sm.sm_ship_mode_id,
      hd.hd_income_band_sk,
      ib.ib_upper_bound,
      wp.wp_type
    FROM web_sales ws
    JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm             ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp              ON ws.ws_web_page_sk   = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND t.t_meal_time = 'lunch'
      AND ws.ws_net_paid > 500
  ),

  -- Full outer join of the three main streams keeping unmatched rows
  full_combined AS (
    SELECT
      cs.cs_order_number            AS order_number,
      cs.cs_net_paid                AS cs_net_paid,
      cs.cs_net_profit              AS cs_net_profit,
      ws.ws_net_paid                AS ws_net_paid,
      sr.sr_return_amt              AS sr_return_amt,
      cs.d_year,
      cs.t_am_pm,
      cs.sm_ship_mode_id
    FROM cs
    FULL OUTER JOIN ws ON cs.cs_order_number = ws.ws_order_number
    FULL OUTER JOIN sr ON cs.d_year = sr.d_year AND cs.t_am_pm = sr.t_am_pm
  ),

  -- Orders that appear both in sales and returns (INTERSECT)
  intersect_orders AS (
    SELECT cs_order_number FROM cs
    INTERSECT
    SELECT cr_order_number FROM cr
  )

SELECT
  fc.order_number,
  SUM(COALESCE(fc.cs_net_paid,0) + COALESCE(fc.ws_net_paid,0) + COALESCE(fc.sr_return_amt,0)) AS total_amount,
  COUNT(*)                                              AS txn_count,
  MIN(fc.cs_net_profit)                                 AS min_profit,
  MAX(fc.cs_net_profit)                                 AS max_profit,
  AVG(fc.cs_net_profit)                                 AS avg_profit
FROM full_combined fc
WHERE EXISTS (
        SELECT 1 FROM intersect_orders io
        WHERE io.cs_order_number = fc.order_number
      )
  AND fc.order_number IS NOT NULL
GROUP BY
  fc.order_number,
  fc.d_year,
  fc.t_am_pm,
  fc.sm_ship_mode_id
ORDER BY total_amount DESC
LIMIT 100
