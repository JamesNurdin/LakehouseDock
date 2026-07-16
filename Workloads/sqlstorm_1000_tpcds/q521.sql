WITH sales AS (
  SELECT ss.ss_sold_date_sk AS date_sk, ss.ss_net_paid AS net_paid, ss.ss_net_profit AS net_profit, 'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT cs.cs_sold_date_sk, cs.cs_net_paid, cs.cs_net_profit, 'catalog'
  FROM catalog_sales cs
  UNION ALL
  SELECT ws.ws_sold_date_sk, ws.ws_net_paid, ws.ws_net_profit, 'web'
  FROM web_sales ws
),
returns AS (
  SELECT sr.sr_returned_date_sk AS date_sk, -sr.sr_return_amt AS net_paid, CAST(0 AS decimal(7,2)) AS net_profit, 'store' AS channel
  FROM store_returns sr
  UNION ALL
  SELECT cr.cr_returned_date_sk, -cr.cr_return_amount, CAST(0 AS decimal(7,2)), 'catalog'
  FROM catalog_returns cr
  UNION ALL
  SELECT wr.wr_returned_date_sk, -wr.wr_return_amt, CAST(0 AS decimal(7,2)), 'web'
  FROM web_returns wr
)
SELECT d.d_year,
       month(d.d_date) AS month,
       s.channel,
       sum(s.net_paid) AS total_net_paid,
       sum(s.net_profit) AS total_net_profit
FROM (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM returns
) s
JOIN date_dim d ON s.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, month(d.d_date), s.channel
ORDER BY d.d_year, month, s.channel
