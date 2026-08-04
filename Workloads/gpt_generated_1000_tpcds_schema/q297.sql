WITH
  cr_join AS (
    SELECT
      cr.cr_returned_date_sk,
      d.d_date AS d_date,
      cr.cr_item_sk,
      i.i_category,
      i.i_current_price,
      cr.cr_return_amount,
      cr.cr_net_loss,
      cc.cc_name,
      sm.sm_type,
      w.w_warehouse_name,
      cd.cd_gender,
      hd.hd_buy_potential,
      ib.ib_lower_bound AS ib_lower_bound,
      ib.ib_upper_bound AS ib_upper_bound
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),
  wr_join AS (
    SELECT
      wr.wr_returned_date_sk,
      d.d_date AS d_date,
      wr.wr_item_sk,
      i.i_category,
      i.i_current_price,
      wr.wr_return_amt,
      wr.wr_net_loss,
      wp.wp_type,
      cd.cd_gender,
      hd.hd_buy_potential,
      ib.ib_lower_bound AS ib_lower_bound,
      ib.ib_upper_bound AS ib_upper_bound
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),
  aggregated_returns AS (
    SELECT
      COALESCE(cr.d_date, wr.d_date) AS return_date,
      COALESCE(cr.i_category, wr.i_category) AS category,
      COALESCE(cr.cd_gender, wr.cd_gender) AS gender,
      SUM(COALESCE(cr.cr_return_amount, 0) + COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
      SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
      MAX(COALESCE(cr.ib_lower_bound, wr.ib_lower_bound)) AS income_lower,
      MAX(COALESCE(cr.ib_upper_bound, wr.ib_upper_bound)) AS income_upper
    FROM cr_join cr
    FULL OUTER JOIN wr_join wr
      ON cr.d_date = wr.d_date
     AND cr.i_category = wr.i_category
     AND cr.cd_gender = wr.cd_gender
    GROUP BY 1,2,3
  ),
  sales_agg AS (
    SELECT
      d.d_date AS sales_date,
      i.i_category AS category,
      SUM(ss.ss_quantity) AS total_quantity,
      SUM(ss.ss_net_paid) AS total_sales_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY 1,2
  ),
  web_site_cte AS (
    SELECT
      ws.web_site_sk,
      ws.web_name,
      d.d_date AS open_date,
      ws.web_gmt_offset,
      ws.web_tax_percentage
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
  )
SELECT
  ar.return_date,
  ar.category,
  ar.gender,
  ar.total_return_amount,
  ar.total_net_loss,
  sa.total_quantity,
  sa.total_sales_net_paid,
  ws.web_name,
  lat.avg_sales_net_paid,
  (SELECT COUNT(*) FROM item i_sub WHERE i_sub.i_formulation LIKE '%goldenrod%') AS goldenrod_item_count
FROM aggregated_returns ar
LEFT JOIN sales_agg sa
  ON ar.return_date = sa.sales_date
 AND ar.category = sa.category
LEFT JOIN web_site_cte ws
  ON ws.open_date = ar.return_date
LEFT JOIN LATERAL (
  SELECT AVG(ss3.ss_net_paid) AS avg_sales_net_paid
  FROM store_sales ss3
  JOIN date_dim d3 ON ss3.ss_sold_date_sk = d3.d_date_sk
  JOIN item i3 ON ss3.ss_item_sk = i3.i_item_sk
  WHERE i3.i_category = ar.category
) lat ON TRUE
WHERE ar.return_date >= DATE '2000-01-01'
  AND ar.return_date <= DATE '2000-12-31'
  AND ar.category IN ('Electronics', 'Clothing')
  AND ar.gender = 'F'
  AND ar.total_return_amount > 1000
  AND ar.total_net_loss < 5000
  AND EXISTS (SELECT 1 FROM call_center cc WHERE cc.cc_name LIKE 'North%')
ORDER BY ar.total_net_loss DESC, ar.return_date
LIMIT 100
