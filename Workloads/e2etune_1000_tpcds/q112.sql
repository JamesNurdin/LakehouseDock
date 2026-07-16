WITH daily_agg AS (
  SELECT
    ss_store_sk,
    ss_sold_date_sk,
    SUM(ss_ext_sales_price) AS daily_sales,
    SUM(ss_net_profit) AS daily_profit,
    AVG(ss_ext_discount_amt) AS avg_discount
  FROM store_sales
  WHERE ss_store_sk IN (34, 574, 211, 350, 746)
    AND ss_sold_date_sk BETWEEN 2451400 AND 2452200
  GROUP BY ss_store_sk, ss_sold_date_sk
),
store_total AS (
  SELECT
    ss_store_sk,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss_sold_date_sk) AS days_sold
  FROM store_sales
  WHERE ss_store_sk IN (34, 574, 211, 350, 746)
    AND ss_sold_date_sk BETWEEN 2451400 AND 2452200
  GROUP BY ss_store_sk
)
SELECT
  d.ss_store_sk,
  d.ss_sold_date_sk,
  d.daily_sales,
  d.daily_profit,
  d.avg_discount,
  s.total_sales,
  s.total_profit,
  RANK() OVER (PARTITION BY d.ss_sold_date_sk ORDER BY d.daily_sales DESC) AS daily_sales_rank,
  (d.daily_sales / NULLIF(s.total_sales, 0)) * 100 AS daily_sales_pct_of_store_total,
  SUM(d.daily_sales) OVER (PARTITION BY d.ss_store_sk ORDER BY d.ss_sold_date_sk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_sales
FROM daily_agg d
JOIN store_total s
  ON d.ss_store_sk = s.ss_store_sk
WHERE d.daily_sales > 1000
ORDER BY d.ss_sold_date_sk, daily_sales_rank
