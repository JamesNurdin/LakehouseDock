WITH
  cr_base AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_item_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      d.d_year AS d_year,
      i.i_category,
      c.c_customer_id,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      cc.cc_name,
      cp.cp_department,
      sm.sm_type,
      r.r_reason_desc
    FROM catalog_returns cr
    JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i                   ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c               ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN call_center cc          ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm             ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r                 ON cr.cr_reason_sk = r.r_reason_sk
  ),
  inv_base AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      d.d_year AS inv_year
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i    ON inv.inv_item_sk = i.i_item_sk
  ),
  full_join AS (
    SELECT
      cr.cr_item_sk,
      cr.d_year,
      cr.i_category,
      cr.cr_return_amount,
      inv.inv_quantity_on_hand
    FROM cr_base cr
    FULL OUTER JOIN inv_base inv
      ON cr.cr_item_sk = inv.inv_item_sk
  ),
  ws_base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_net_profit,
      d.d_year AS sale_year,
      i.i_category AS item_category,
      c.c_customer_id AS buyer_id,
      hd.hd_income_band_sk AS buyer_income_band,
      ib.ib_lower_bound AS income_lower,
      wp.wp_type AS web_page_type,
      sm.sm_type AS ship_type
    FROM web_sales ws
    JOIN date_dim d          ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i              ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c          ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp         ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  ),
  wr_base AS (
    SELECT
      wr.wr_order_number,
      wr.wr_item_sk,
      wr.wr_return_amt_inc_tax,
      r.r_reason_desc AS wr_reason_desc
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  ),
  intersect_orders AS (
    SELECT ws_order_number FROM ws_base
    INTERSECT
    SELECT wr_order_number FROM wr_base
  ),
  union_data AS (
    SELECT
      fj.d_year AS year,
      fj.i_category AS category,
      SUM(fj.cr_return_amount) AS metric_val,
      SUM(fj.inv_quantity_on_hand) AS metric_aux,
      'CR' AS source
    FROM full_join fj
    GROUP BY fj.d_year, fj.i_category

    UNION DISTINCT

    SELECT
      ws.sale_year AS year,
      ws.item_category AS category,
      SUM(ws.ws_net_profit) AS metric_val,
      CAST(NULL AS BIGINT) AS metric_aux,
      'WS' AS source
    FROM ws_base ws
    WHERE ws.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
    GROUP BY ws.sale_year, ws.item_category
  )
SELECT
  source,
  year,
  category,
  metric_val,
  metric_aux,
  CASE
    WHEN source = 'WS' AND metric_val > 0 THEN 'Profit'
    WHEN source = 'WS' AND metric_val <= 0 THEN 'Loss'
    ELSE 'N/A'
  END AS profit_status
FROM union_data
ORDER BY year DESC, category
LIMIT 100
