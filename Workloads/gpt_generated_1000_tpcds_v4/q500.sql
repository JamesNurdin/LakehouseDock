WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_warehouse_sk,
        ws_web_site_sk,
        SUM(ws_net_paid)        AS total_net_paid,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(*)                AS sales_cnt
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ws_quantity > 1
      AND ws_ship_mode_sk IN (1, 2)
    GROUP BY ws_item_sk, ws_warehouse_sk, ws_web_site_sk
)
SELECT
    i.i_category                     AS item_category,
    w.w_state                        AS warehouse_state,
    ws.web_name                      AS website_name,
    cc.cc_name                       AS call_center_name,
    cp.cp_department                 AS catalog_department,
    ib.ib_upper_bound                AS income_band_upper,
    SUM(ws_agg.total_net_paid)       AS total_sales_net_paid,
    SUM(ws_agg.total_sales)          AS total_sales_amount,
    SUM(ws_agg.sales_cnt)            AS total_sales_transactions,
    SUM(cr.cr_return_amount)         AS total_catalog_return_amount,
    SUM(sr.sr_return_amt)            AS total_store_return_amount,
    SUM(wr.wr_return_amt)            AS total_web_return_amount,
    AVG(i.i_current_price)           AS avg_item_price,
    COUNT(DISTINCT ws_agg.ws_item_sk) AS distinct_items_sold
FROM ws_agg
JOIN item i
  ON ws_agg.ws_item_sk = i.i_item_sk
JOIN warehouse w
  ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws
  ON ws_agg.ws_web_site_sk = ws.web_site_sk

-- catalog returns and its related dimensions
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim td_cr
  ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN customer_demographics cd_ref_cr
  ON cr.cr_refunded_cdemo_sk = cd_ref_cr.cd_demo_sk
JOIN customer_demographics cd_ret_cr
  ON cr.cr_returning_cdemo_sk = cd_ret_cr.cd_demo_sk
JOIN household_demographics hd_ref_cr
  ON cr.cr_refunded_hdemo_sk = hd_ref_cr.hd_demo_sk
JOIN household_demographics hd_ret_cr
  ON cr.cr_returning_hdemo_sk = hd_ret_cr.hd_demo_sk
JOIN household_demographics hd_cr_warehouse
  ON cr.cr_warehouse_sk = w.w_warehouse_sk

-- store returns and its related dimensions
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim td_sr
  ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN customer_demographics cd_sr
  ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr
  ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN income_band ib
  ON hd_sr.hd_income_band_sk = ib.ib_income_band_sk

-- web returns and its related dimensions
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN time_dim td_wr
  ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN customer_demographics cd_ref_wr
  ON wr.wr_refunded_cdemo_sk = cd_ref_wr.cd_demo_sk
JOIN customer_demographics cd_ret_wr
  ON wr.wr_returning_cdemo_sk = cd_ret_wr.cd_demo_sk
JOIN household_demographics hd_ref_wr
  ON wr.wr_refunded_hdemo_sk = hd_ref_wr.hd_demo_sk
JOIN household_demographics hd_ret_wr
  ON wr.wr_returning_hdemo_sk = hd_ret_wr.hd_demo_sk
JOIN web_sales ws_raw
  ON wr.wr_order_number = ws_raw.ws_order_number
JOIN time_dim td_ws_raw
  ON ws_raw.ws_sold_time_sk = td_ws_raw.t_time_sk

WHERE i.i_brand = 'Brand#45'
  AND w.w_state = 'CA'
  AND ws.web_class = 'Unknown'
  AND cc.cc_name = 'Call Center 1'
  AND cp.cp_department = 'Electronics'
  AND ib.ib_upper_bound > 50000
  AND td_sr.t_hour BETWEEN 9 AND 17

GROUP BY
    i.i_category,
    w.w_state,
    ws.web_name,
    cc.cc_name,
    cp.cp_department,
    ib.ib_upper_bound

ORDER BY total_sales_net_paid DESC

LIMIT 100
