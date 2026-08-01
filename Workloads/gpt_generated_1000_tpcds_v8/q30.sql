WITH sales_agg AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_bill_customer_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_warehouse_sk,
    ws.ws_web_site_sk,
    SUM(ws.ws_net_paid)          AS total_net_paid,
    SUM(ws.ws_ext_sales_price)   AS total_sales_price,
    COUNT(*)                     AS line_cnt
  FROM web_sales ws
  GROUP BY
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_bill_customer_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_warehouse_sk,
    ws.ws_web_site_sk
)
SELECT
  c.c_customer_id,
  cd.cd_gender,
  d.d_year,
  w.w_warehouse_name,
  wsit.web_name                     AS website_name,
  cp.cp_catalog_page_number,
  wsagg.total_net_paid,
  wsagg.total_sales_price,
  COALESCE(sr.sr_net_loss, 0)       AS store_return_loss,
  COALESCE(wr.wr_net_loss, 0)       AS web_return_loss,
  (wsagg.total_net_paid - COALESCE(sr.sr_net_loss, 0) - COALESCE(wr.wr_net_loss, 0)) AS net_contribution,
  RANK() OVER (PARTITION BY cd.cd_gender ORDER BY wsagg.total_net_paid DESC) AS gender_rank,
  LAG(wsagg.total_net_paid) OVER (PARTITION BY cd.cd_gender ORDER BY wsagg.total_net_paid DESC) AS lag_net_paid,
  (
    SELECT SUM(ws2.ws_net_paid)
    FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
      AND ws2.ws_sold_date_sk > d.d_date_sk
  ) AS future_sales_sum
FROM sales_agg wsagg
JOIN customer c               ON wsagg.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd  ON wsagg.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d                ON wsagg.ws_sold_date_sk = d.d_date_sk
JOIN warehouse w               ON wsagg.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site wsit             ON wsagg.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN catalog_page cp      ON (cp.cp_start_date_sk = d.d_date_sk OR cp.cp_end_date_sk = d.d_date_sk)
LEFT JOIN store_returns sr     ON sr.sr_customer_sk = c.c_customer_sk
                               AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns wr       ON wr.wr_returning_customer_sk = c.c_customer_sk
                               AND wr.wr_returned_date_sk = d.d_date_sk
WHERE
  d.d_year = 2001
  AND cd.cd_gender = 'M'
  AND c.c_preferred_cust_flag = 'Y'
  AND d.d_date >= DATE '2001-01-01'
  AND d.d_date < DATE '2002-01-01'
ORDER BY net_contribution DESC
LIMIT 100
