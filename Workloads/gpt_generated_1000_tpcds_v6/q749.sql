WITH sales_agg AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    w.w_warehouse_id,
    w.w_warehouse_sk,
    w.w_city,
    d_date.d_year AS year,
    cd.cd_gender,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    CASE
      WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH'
      WHEN SUM(ss.ss_ext_sales_price) > 50000 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS sales_category
  FROM call_center cc
  INNER JOIN date_dim d_date
    ON cc.cc_closed_date_sk = d_date.d_date_sk
  INNER JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_date.d_date_sk
  INNER JOIN time_dim t_time
    ON ss.ss_sold_time_sk = t_time.t_time_sk
  INNER JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  INNER JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_date.d_date_sk
   AND ws.ws_sold_time_sk = t_time.t_time_sk
   AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  INNER JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE
    d_date.d_year = 2001
    AND cd.cd_gender = 'M'
    AND w.w_city IN ('Ash Laurel', 'Miller Broadway')
    AND t_time.t_hour BETWEEN 9 AND 17
    AND ss.ss_ext_sales_price > 20
    AND cc.cc_state = 'CA'
    AND EXISTS (
      SELECT 1 FROM warehouse w2
      WHERE w2.w_state = cc.cc_state
        AND w2.w_city = 'Ash Laurel'
    )
  GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    w.w_warehouse_id,
    w.w_warehouse_sk,
    w.w_city,
    d_date.d_year,
    cd.cd_gender
)
SELECT
  cc_call_center_id,
  cc_name,
  w_warehouse_id,
  w_city,
  year,
  cd_gender,
  store_sales_total,
  web_sales_total,
  (store_sales_total + web_sales_total) AS total_sales,
  sales_category,
  ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY (store_sales_total + web_sales_total) DESC) AS rn,
  (SELECT AVG(ws2.ws_net_paid)
     FROM web_sales ws2
    WHERE ws2.ws_warehouse_sk = sales_agg.w_warehouse_sk) AS avg_warehouse_net_paid
FROM sales_agg
WHERE (store_sales_total + web_sales_total) > 50000
ORDER BY total_sales DESC
LIMIT 100
