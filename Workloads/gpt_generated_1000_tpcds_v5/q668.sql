WITH sales_agg AS (
  SELECT
    ss.ss_item_sk,
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    i.i_category,
    i.i_brand,
    d.d_year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_transactions,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_qty,
    MAX(r.r_reason_desc) AS frequent_return_reason,
    hd.hd_income_band_sk
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  GROUP BY
    ss.ss_item_sk,
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    i.i_category,
    i.i_brand,
    d.d_year,
    hd.hd_income_band_sk
)
SELECT
  d_sales.d_year,
  sa.i_category,
  sa.i_brand,
  sa.total_sales,
  sa.total_profit,
  sa.total_return_loss,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  cc.cc_name,
  cp.cp_description,
  ws.ws_quantity,
  wp.wp_url,
  wsite.web_name,
  inv.inv_quantity_on_hand,
  d_ws_sold.d_month_seq,
  sa.frequent_return_reason
FROM sales_agg sa
JOIN date_dim d_sales ON sa.ss_sold_date_sk = d_sales.d_date_sk
JOIN income_band ib ON sa.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory inv ON inv.inv_item_sk = sa.ss_item_sk
                     AND inv.inv_date_sk = d_sales.d_date_sk
JOIN call_center cc ON cc.cc_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN catalog_returns cr ON cr.cr_item_sk = sa.ss_item_sk
                         AND cr.cr_returned_date_sk = d_sales.d_date_sk
JOIN date_dim d_cr_ret ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
JOIN web_sales ws ON ws.ws_item_sk = sa.ss_item_sk
                     AND ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
ORDER BY sa.total_sales DESC
LIMIT 100
