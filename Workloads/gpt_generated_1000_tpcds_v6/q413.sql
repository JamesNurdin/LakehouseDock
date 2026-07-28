WITH
  sales_agg AS (
    SELECT
      d.d_year,
      'sale' AS type,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(*) AS order_cnt,
      AVG(ws.ws_list_price) AS avg_list_price,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ws.ws_list_price > 50
    GROUP BY d.d_year
  ),
  returns_agg AS (
    SELECT
      d.d_year,
      'return' AS type,
      SUM(sr.sr_return_amt_inc_tax) AS total_sales,
      SUM(-sr.sr_net_loss) AS total_profit,
      COUNT(*) AS order_cnt,
      (
        SELECT AVG(s2.ws_list_price)
        FROM web_sales s2
        JOIN date_dim d2 ON s2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d.d_year
      ) AS avg_list_price,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC) AS sales_rank
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND sr.sr_return_amt_inc_tax > 100
    GROUP BY d.d_year
  )
SELECT
  year,
  type,
  total_sales,
  total_profit,
  order_cnt,
  avg_list_price,
  CASE WHEN total_profit > 0 THEN 'positive' ELSE 'negative' END AS profit_flag,
  SUM(total_sales) OVER (PARTITION BY type ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM (
  SELECT d_year AS year, type, total_sales, total_profit, order_cnt, avg_list_price
  FROM sales_agg
  UNION ALL
  SELECT d_year AS year, type, total_sales, total_profit, order_cnt, avg_list_price
  FROM returns_agg
) combined
ORDER BY year, type
