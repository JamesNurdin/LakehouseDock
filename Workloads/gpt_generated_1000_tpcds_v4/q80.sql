SELECT
    d_sold.d_year AS sales_year,
    i.i_category AS item_category,
    cd.cd_gender,
    hd.hd_buy_potential,
    ws.web_name,
    sm.sm_type,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    SUM(ss.ss_net_profit) AS total_profit,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
FROM store_sales ss
JOIN date_dim d_sold
  ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
  AND inv.inv_date_sk = d_sold.d_date_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_page wp
  ON 1 = 1
JOIN date_dim d_wp
  ON wp.wp_creation_date_sk = d_wp.d_date_sk
JOIN web_site ws
  ON 1 = 1
JOIN date_dim d_ws
  ON ws.web_open_date_sk = d_ws.d_date_sk
GROUP BY
    d_sold.d_year,
    i.i_category,
    cd.cd_gender,
    hd.hd_buy_potential,
    ws.web_name,
    sm.sm_type
ORDER BY total_sales DESC
LIMIT 100
