WITH returns_agg AS (
  SELECT
    sm.sm_type,
    td.t_hour,
    wsite.web_name,
    COALESCE(SUM(cr.cr_return_amount), 0) + COALESCE(SUM(sr.sr_return_amt), 0) + COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
    CAST(0 AS decimal(7,2)) AS total_sales_price,
    CAST(0 AS decimal(7,2)) AS total_net_profit
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk AND sr.sr_customer_sk = c.c_customer_sk
  JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk AND ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk AND wp.wp_customer_sk = c.c_customer_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
      AND wr.wr_refunded_customer_sk = c.c_customer_sk
      AND wr.wr_order_number = ws.ws_order_number
      AND wr.wr_item_sk = ws.ws_item_sk
      AND wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE sm.sm_type = 'OVERNIGHT'
    AND sm.sm_contract = 'I3uCelXtjP'
    AND td.t_hour = 14
    AND wp.wp_rec_end_date = DATE '2000-09-02'
  GROUP BY GROUPING SETS (
    (sm.sm_type, td.t_hour, wsite.web_name),
    (sm.sm_type, td.t_hour),
    (sm.sm_type, wsite.web_name),
    (td.t_hour, wsite.web_name),
    (sm.sm_type),
    (td.t_hour),
    (wsite.web_name),
    ()
  )
),
sales_agg AS (
  SELECT
    sm.sm_type,
    td.t_hour,
    wsite.web_name,
    CAST(0 AS decimal(7,2)) AS total_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    SUM(ws.ws_net_profit) AS total_net_profit
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk AND sr.sr_customer_sk = c.c_customer_sk
  JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk AND ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk AND wp.wp_customer_sk = c.c_customer_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
      AND wr.wr_refunded_customer_sk = c.c_customer_sk
      AND wr.wr_order_number = ws.ws_order_number
      AND wr.wr_item_sk = ws.ws_item_sk
      AND wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE sm.sm_type = 'EXPRESS'
    AND sm.sm_contract = 'hGoF18SLDDPBj'
    AND td.t_minute = 5
    AND wsite.web_rec_start_date >= DATE '1999-01-01'
  GROUP BY GROUPING SETS (
    (sm.sm_type, td.t_hour, wsite.web_name),
    (sm.sm_type, td.t_hour),
    (sm.sm_type, wsite.web_name),
    (td.t_hour, wsite.web_name),
    (sm.sm_type),
    (td.t_hour),
    (wsite.web_name),
    ()
  )
)
SELECT *
FROM returns_agg
UNION ALL
SELECT *
FROM sales_agg
ORDER BY sm_type, t_hour, web_name
LIMIT 100
