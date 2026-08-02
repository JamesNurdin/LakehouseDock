WITH base_data AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    cr.cr_return_amount,
    cr.cr_fee,
    r.r_reason_desc AS store_reason_desc,
    sm.sm_type AS catalog_ship_mode_type,
    cp.cp_department AS catalog_department,
    wp.wp_autogen_flag AS web_page_autogen_flag,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ws.ws_bill_customer_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    tw.t_hour,
    tw.t_shift,
    r_wr.r_reason_desc AS web_reason_desc,
    sm_ws.sm_type AS web_ship_mode_type
  FROM store_sales ss
  INNER JOIN time_dim tw
    ON ss.ss_sold_time_sk = tw.t_time_sk
  LEFT JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = tw.t_time_sk
  LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN web_sales ws
    ON ws.ws_sold_time_sk = tw.t_time_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
  LEFT JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
)
SELECT
  store_reason_desc AS reason_desc,
  catalog_department AS department,
  catalog_ship_mode_type AS ship_mode_type,
  COUNT(DISTINCT ss_customer_sk) AS distinct_customer_cnt,
  SUM(DISTINCT cr_return_amount) AS distinct_return_amount_sum,
  SUM(ss_net_profit) AS total_store_net_profit,
  SUM(ws_net_profit) AS total_web_net_profit,
  SUM(sr_return_amt) AS total_store_return_amount,
  SUM(wr_return_amt) AS total_web_return_amount,
  AVG(ss_ext_sales_price) AS avg_store_ext_sales_price,
  AVG(ws_ext_sales_price) AS avg_web_ext_sales_price
FROM base_data
WHERE
  t_hour BETWEEN 10 AND 18
  AND ss_quantity > 0
  AND web_page_autogen_flag = 'N'
  AND catalog_department = 'Books'
  AND catalog_ship_mode_type = 'AIR'
  AND store_reason_desc IS NOT NULL
GROUP BY
  store_reason_desc,
  catalog_department,
  catalog_ship_mode_type
HAVING
  SUM(ss_net_profit) > 10000
  AND COUNT(DISTINCT ss_customer_sk) >= 5
  AND SUM(cr_return_amount) > 0

UNION ALL

SELECT
  web_reason_desc AS reason_desc,
  catalog_department AS department,
  web_ship_mode_type AS ship_mode_type,
  COUNT(DISTINCT ws_bill_customer_sk) AS distinct_customer_cnt,
  SUM(DISTINCT ws_ext_sales_price) AS distinct_ext_sales_price_sum,
  SUM(ss_net_profit) AS total_store_net_profit,
  SUM(ws_net_profit) AS total_web_net_profit,
  SUM(sr_return_amt) AS total_store_return_amount,
  SUM(wr_return_amt) AS total_web_return_amount,
  AVG(ss_ext_sales_price) AS avg_store_ext_sales_price,
  AVG(ws_ext_sales_price) AS avg_web_ext_sales_price
FROM base_data
WHERE
  t_shift = 'Eve'
  AND ws_quantity > 0
  AND web_page_autogen_flag = 'Y'
  AND catalog_department = 'Electronics'
  AND web_ship_mode_type = 'GROUND'
  AND web_reason_desc IS NOT NULL
GROUP BY
  web_reason_desc,
  catalog_department,
  web_ship_mode_type
HAVING
  AVG(ws_net_profit) > 0
  AND COUNT(DISTINCT ws_bill_customer_sk) >= 3
