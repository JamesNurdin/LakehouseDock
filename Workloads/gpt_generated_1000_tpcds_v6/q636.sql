WITH sales_summary AS (
    SELECT
        td.t_time_sk,
        i.i_category,
        sm.sm_carrier,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_color IN ('red', 'purple')
      AND sm.sm_carrier = 'USPS'
      AND cd.cd_credit_rating = 'Good'
      AND cd.cd_marital_status = 'M'
      AND td.t_hour BETWEEN 8 AND 17
    GROUP BY td.t_time_sk, i.i_category, sm.sm_carrier
)
SELECT
    ss.i_category,
    ss.sm_carrier,
    SUM(ss.total_sales) AS sum_sales,
    SUM(ss.total_profit) AS sum_profit,
    COUNT(DISTINCT ss.t_time_sk) AS distinct_time_slots,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_return_amount,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_catalog_return_amount
FROM sales_summary ss
LEFT JOIN store_returns sr ON ss.t_time_sk = sr.sr_return_time_sk
LEFT JOIN item i_sr ON sr.sr_item_sk = i_sr.i_item_sk
LEFT JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN catalog_returns cr ON ss.t_time_sk = cr.cr_returned_time_sk
LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN customer_demographics cd_cr ON cr.cr_refunded_cdemo_sk = cd_cr.cd_demo_sk
WHERE i_sr.i_category = ss.i_category
  AND cd_sr.cd_credit_rating = 'Good'
GROUP BY GROUPING SETS (
    (ss.i_category, ss.sm_carrier),
    (ss.i_category),
    (ss.sm_carrier)
)
HAVING SUM(ss.total_sales) > (
    SELECT AVG(total_sales) FROM sales_summary
)
ORDER BY sum_sales DESC
LIMIT 100
