WITH
  store_sales_agg AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      SUM(ss.ss_ext_sales_price) AS total_store_sales,
      SUM(ss.ss_net_profit) AS total_store_profit
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    GROUP BY ss.ss_sold_date_sk, ss.ss_sold_time_sk, ss.ss_item_sk
  ),
  catalog_returns_agg AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_catalog_page_sk,
      cr.cr_warehouse_sk,
      cr.cr_refunded_addr_sk,
      cr.cr_refunded_hdemo_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_returned_time_sk, cr.cr_catalog_page_sk, cr.cr_warehouse_sk, cr.cr_refunded_addr_sk, cr.cr_refunded_hdemo_sk
  ),
  web_sales_agg AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_web_site_sk,
      ws.ws_warehouse_sk,
      SUM(ws.ws_ext_sales_price) AS total_web_sales,
      SUM(ws.ws_net_profit) AS total_web_profit
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_sold_time_sk, ws.ws_item_sk, ws.ws_web_site_sk, ws.ws_warehouse_sk
  ),
  store_returns_agg AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_item_sk,
      SUM(sr.sr_return_amt) AS total_store_return_amount,
      SUM(sr.sr_net_loss) AS total_store_return_loss
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_return_time_sk, sr.sr_item_sk
  )
SELECT
  sub.hour_of_day,
  sub.warehouse_name,
  sub.department,
  sub.state,
  sub.buy_potential,
  SUM(sub.total_store_sales) AS sum_store_sales,
  SUM(sub.total_return_amount) AS sum_return_amount,
  SUM(sub.total_web_sales) AS sum_web_sales,
  SUM(sub.total_store_return_amount) AS sum_store_return_amount,
  AVG(sub.warehouse_time_web_sales) AS avg_warehouse_time_web_sales,
  SUM(CASE WHEN sub.total_store_sales > sub.avg_return_amount THEN 1 ELSE 0 END) AS count_store_sales_above_avg_return
FROM (
  SELECT
    t1.t_hour AS hour_of_day,
    wh.w_warehouse_name AS warehouse_name,
    cp.cp_department AS department,
    ca.ca_state AS state,
    hd.hd_buy_potential AS buy_potential,
    ss.total_store_sales,
    cr.total_return_amount,
    ws.total_web_sales,
    sr.total_store_return_amount,
    (
      SELECT SUM(ws2.ws_ext_sales_price)
      FROM web_sales ws2
      WHERE ws2.ws_warehouse_sk = wh.w_warehouse_sk
        AND ws2.ws_sold_time_sk = t1.t_time_sk
    ) AS warehouse_time_web_sales,
    (
      SELECT AVG(cr3.cr_return_amount)
      FROM catalog_returns cr3
    ) AS avg_return_amount
  FROM (store_sales_agg ss
        JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk)
  FULL OUTER JOIN (catalog_returns_agg cr
        JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk)
        ON t1.t_time_sk = t2.t_time_sk
  JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN store_returns_agg sr
    ON sr.sr_return_time_sk = t1.t_time_sk
   AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN web_sales_agg ws
    ON ws.ws_sold_time_sk = t1.t_time_sk
   AND ws.ws_item_sk = ss.ss_item_sk
  LEFT JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  WHERE t1.t_hour BETWEEN 8 AND 16
    AND wh.w_state = 'CA'
    AND hd.hd_income_band_sk = 12
    AND cp.cp_department = 'Electronics'
) sub
GROUP BY sub.hour_of_day, sub.warehouse_name, sub.department, sub.state, sub.buy_potential
ORDER BY sum_store_sales DESC
LIMIT 100
