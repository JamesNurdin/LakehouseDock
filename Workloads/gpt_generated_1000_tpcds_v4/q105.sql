WITH
  store_sales_agg AS (
    SELECT
      s.s_store_id AS store_id,
      d.d_date AS sales_date,
      SUM(ss.ss_net_paid_inc_tax) AS net_sales,
      SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, d.d_date
  ),
  store_sales_final AS (
    SELECT
      store_id,
      sales_date,
      net_sales,
      CASE WHEN total_profit >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
      ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY sales_date DESC) AS rn
    FROM store_sales_agg
  ),
  store_returns_agg AS (
    SELECT
      s.s_store_id AS store_id,
      d.d_date AS sales_date,
      SUM(-sr.sr_refunded_cash) AS net_sales,
      SUM(sr.sr_net_loss) AS total_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, d.d_date
  ),
  store_returns_final AS (
    SELECT
      store_id,
      sales_date,
      net_sales,
      CASE WHEN total_loss <= 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
      ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY sales_date DESC) AS rn
    FROM store_returns_agg
  )
SELECT
  store_id,
  sales_date,
  net_sales,
  profit_flag,
  rn
FROM (
  SELECT store_id, sales_date, net_sales, profit_flag, rn FROM store_sales_final
  UNION ALL
  SELECT store_id, sales_date, net_sales, profit_flag, rn FROM store_returns_final
) combined
ORDER BY store_id, sales_date DESC
LIMIT 100
