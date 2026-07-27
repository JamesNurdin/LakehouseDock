WITH ss_daily AS (
       SELECT
           ss_sold_date_sk,
           ss_store_sk,
           SUM(ss_ext_sales_price)      AS daily_sales,
           SUM(ss_net_profit)           AS daily_profit,
           COUNT(*)                     AS sales_txn
       FROM store_sales
       WHERE ss_ext_sales_price > 1000
         AND ss_net_profit <> 0
       GROUP BY ss_sold_date_sk, ss_store_sk
   ),
   wr_daily AS (
       SELECT
           wr_returned_date_sk,
           SUM(wr_return_amt) AS total_return_amt,
           COUNT(*)           AS return_cnt
       FROM web_returns
       WHERE wr_return_amt > 0
         AND wr_fee < 100
       GROUP BY wr_returned_date_sk
   )
SELECT
    d.d_date,
    ws.web_name,
    ss.ss_store_sk,
    ss.daily_sales,
    ss.daily_profit,
    ss.sales_txn,
    COALESCE(wr.total_return_amt, 0) AS total_return_amt,
    COALESCE(wr.return_cnt, 0)       AS return_cnt,
    CASE WHEN ss.daily_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    RANK() OVER (PARTITION BY d.d_date ORDER BY ss.daily_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (ORDER BY ss.daily_sales DESC)                AS sales_rank
FROM ss_daily ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN wr_daily wr ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND d.d_weekend = 'N'
  AND d.d_current_quarter = 'Y'
ORDER BY d.d_date DESC, ss.daily_sales DESC
LIMIT 100
