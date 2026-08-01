WITH
  -- Store returns aggregated per year, state and vehicle count
  sr AS (
    SELECT
      d.d_year,
      s.s_state,
      hd.hd_vehicle_count,
      SUM(sr.sr_net_loss) AS net_loss,
      COUNT(*) AS cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND hd.hd_dep_count > 2
      AND ib.ib_lower_bound >= 50000
    GROUP BY d.d_year, s.s_state, hd.hd_vehicle_count
  ),

  -- Catalog returns aggregated per year, state and vehicle count
  cr AS (
    SELECT
      d.d_year,
      ca.ca_state,
      hd.hd_vehicle_count,
      SUM(cr.cr_net_loss) AS net_loss,
      COUNT(*) AS cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND hd.hd_dep_count > 2
      AND ib.ib_upper_bound <= 150000
    GROUP BY d.d_year, ca.ca_state, hd.hd_vehicle_count
  ),

  -- Web sales aggregated per year, state and vehicle count
  ws AS (
    SELECT
      d.d_year,
      ca.ca_state,
      hd.hd_vehicle_count,
      SUM(ws.ws_net_paid_inc_ship) AS net_paid,
      COUNT(*) AS cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND hd.hd_vehicle_count >= 1
      AND ib.ib_lower_bound >= 40000
      AND ws.ws_net_paid_inc_ship > 2000
    GROUP BY d.d_year, ca.ca_state, hd.hd_vehicle_count
  ),

  -- Union of the three aggregates, normalising column names
  combined AS (
    SELECT d_year, s_state AS state, hd_vehicle_count,
           net_loss,
           NULL AS net_paid,
           cnt,
           'store_returns' AS source
    FROM sr
    UNION ALL
    SELECT d_year, ca_state AS state, hd_vehicle_count,
           net_loss,
           NULL AS net_paid,
           cnt,
           'catalog_returns' AS source
    FROM cr
    UNION ALL
    SELECT d_year, ca_state AS state, hd_vehicle_count,
           NULL AS net_loss,
           net_paid,
           cnt,
           'web_sales' AS source
    FROM ws
  ),

  -- States with high total net loss (used in EXISTS filter)
  high_loss_states AS (
    SELECT state
    FROM combined
    WHERE net_loss IS NOT NULL
    GROUP BY state
    HAVING SUM(net_loss) > 100000
  ),

  -- Distinct years present in store returns and web sales (used in INTERSECT)
  sr_years AS (SELECT DISTINCT d_year FROM sr),
  ws_years AS (SELECT DISTINCT d_year FROM ws),

  -- Years present in catalog returns (used in EXCEPT)
  cr_years AS (SELECT DISTINCT d_year FROM cr)

SELECT
  c.d_year,
  c.state,
  c.hd_vehicle_count,
  SUM(CASE WHEN c.source = 'store_returns' THEN c.net_loss ELSE 0 END) AS total_net_loss,
  SUM(CASE WHEN c.source = 'web_sales'   THEN c.net_paid ELSE 0 END) AS total_net_paid,
  COUNT(*) AS total_rows,
  MAX(c.cnt) AS max_cnt
FROM combined c
WHERE c.state IN (SELECT state FROM high_loss_states)
  AND EXISTS (SELECT 1 FROM store s WHERE s.s_state = c.state AND s.s_number_employees > 0)
  AND NOT EXISTS (SELECT 1 FROM store s WHERE s.s_state = c.state AND s.s_number_employees > 500)
  AND c.d_year IN (
        SELECT d_year FROM sr_years
        INTERSECT
        SELECT d_year FROM ws_years
      )
  AND c.d_year NOT IN (
        SELECT d_year FROM cr_years
        EXCEPT
        SELECT d_year FROM sr_years
      )
GROUP BY GROUPING SETS (
        (c.d_year, c.state, c.hd_vehicle_count),
        (c.d_year, c.state),
        (c.d_year),
        ()
      )
ORDER BY c.d_year DESC, total_net_loss DESC
LIMIT 100
