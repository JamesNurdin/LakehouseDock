WITH
  returns_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS item_category,
      SUM(cr.cr_return_amount) AS metric_amount,
      COUNT(*) AS metric_count,
      AVG(cr.cr_return_tax) AS metric_avg
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
      AND i.i_brand = 'Brand#12'
      AND cr.cr_return_quantity > 1
    GROUP BY d.d_year, i.i_category
    HAVING SUM(cr.cr_return_amount) > 10000
  ),
  sales_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS item_category,
      SUM(ws.ws_net_paid) AS metric_amount,
      COUNT(*) AS metric_count,
      AVG(ws.ws_ext_tax) AS metric_avg
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
      AND ws.ws_net_paid > 500
      AND i.i_color = 'Blue'
    GROUP BY d.d_year, i.i_category
    HAVING SUM(ws.ws_net_paid) > 5000
  ),
  combined_agg AS (
    SELECT year, item_category, metric_amount, metric_count, metric_avg FROM returns_agg
    UNION DISTINCT
    SELECT year, item_category, metric_amount, metric_count, metric_avg FROM sales_agg
  ),
  reason_agg AS (
    SELECT
      r.r_reason_desc,
      COUNT(cr.cr_return_quantity) AS cnt_returns,
      SUM(cr.cr_return_amount) AS sum_returns
    FROM catalog_returns cr
    RIGHT OUTER JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
    HAVING COUNT(cr.cr_return_quantity) > 0
  ),
  full_date_cc AS (
    SELECT
      cc.cc_name,
      d.d_year,
      cc.cc_state
    FROM call_center cc
    FULL OUTER JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
  )
SELECT
  ca.year,
  ca.item_category,
  ca.metric_amount,
  ca.metric_count,
  ca.metric_avg,
  (
    SELECT ARRAY_AGG(item_category)
    FROM (
      SELECT item_category FROM returns_agg
      EXCEPT
      SELECT item_category FROM sales_agg
    ) diff
  ) AS categories_without_sales,
  (SELECT COUNT(*) FROM reason_agg) AS total_reason_counts,
  (SELECT MAX(d_year) FROM full_date_cc) AS max_year_in_cc,
  (SELECT MIN(cc_name) FROM full_date_cc) AS example_cc_name
FROM combined_agg ca
ORDER BY ca.metric_amount DESC
LIMIT 100
