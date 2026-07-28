WITH
  store_agg AS (
    SELECT
      c.c_customer_sk AS customer_sk,
      'store' AS source,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first'
    GROUP BY c.c_customer_sk
  ),
  web_agg AS (
    SELECT
      wr.wr_refunded_customer_sk AS customer_sk,
      'web' AS source,
      SUM(wr.wr_return_amt) AS total_sales,
      SUM(wr.wr_net_loss) AS total_profit,
      CASE WHEN SUM(wr.wr_net_loss) > 0 THEN 'LOSS' ELSE 'NO_LOSS' END AS profit_flag
    FROM tpcds.web_returns wr
    JOIN tpcds.customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first'
    GROUP BY wr.wr_refunded_customer_sk
  ),
  combined AS (
    SELECT customer_sk, source, total_sales, total_profit, profit_flag FROM store_agg
    UNION ALL
    SELECT customer_sk, source, total_sales, total_profit, profit_flag FROM web_agg
  )
SELECT
  c.customer_sk,
  c.source,
  c.total_sales,
  c.total_profit,
  c.profit_flag,
  (
    SELECT COUNT(DISTINCT ss.ss_item_sk)
    FROM tpcds.store_sales ss
    JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_customer_sk = c.customer_sk
      AND td.t_shift = 'first'
  ) AS distinct_items_sold,
  CASE WHEN c.total_sales > (
         SELECT AVG(total_sales)
         FROM combined cc
         WHERE cc.source = c.source
       ) THEN 'ABOVE_AVG' ELSE 'BELOW_AVG' END AS sales_relative_to_avg
FROM combined c
WHERE c.total_profit IS NOT NULL
ORDER BY c.source, c.total_sales DESC
LIMIT 100
