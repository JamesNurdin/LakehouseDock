WITH
  store_agg AS (
    SELECT
      ss.ss_item_sk AS item_sk,
      CAST('store' AS VARCHAR) AS channel,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ss.ss_ticket_number) AS txn_count
    FROM tpcds.store_sales ss
    JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_item_sk
  ),
  web_agg AS (
    SELECT
      ws.ws_item_sk AS item_sk,
      CAST('web' AS VARCHAR) AS channel,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ws.ws_order_number) AS txn_count
    FROM tpcds.web_sales ws
    JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY ws.ws_item_sk
  )
SELECT DISTINCT
  s.item_sk,
  s.channel,
  s.total_sales,
  s.txn_count
FROM (
  SELECT
    item_sk,
    channel,
    total_sales,
    txn_count
  FROM store_agg
  WHERE total_sales > (SELECT AVG(total_sales) FROM store_agg)

  UNION ALL

  SELECT
    item_sk,
    channel,
    total_sales,
    txn_count
  FROM web_agg
  WHERE total_sales > (SELECT AVG(total_sales) FROM web_agg)
) s
WHERE EXISTS (
  SELECT 1
  FROM tpcds.promotion p
  WHERE p.p_item_sk = s.item_sk
    AND p.p_start_date_sk <= (SELECT MIN(cr.cr_returned_date_sk) FROM tpcds.catalog_returns cr)
    AND p.p_end_date_sk   >= (SELECT MAX(cr.cr_returned_date_sk) FROM tpcds.catalog_returns cr)
)
ORDER BY s.total_sales DESC
LIMIT 100
