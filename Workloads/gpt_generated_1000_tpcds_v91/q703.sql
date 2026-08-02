WITH sub1 AS (
  SELECT
    d.d_year AS sales_year,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    SUM(ss.ss_net_paid) AS total_net_paid,
    (SELECT avg(ss2.ss_net_paid)
     FROM store_sales ss2
     JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
     WHERE d2.d_year = d.d_year) AS avg_year_net_paid
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE ss.ss_wholesale_cost >= 20
    AND d.d_current_week = 'N'
  GROUP BY d.d_year
),
sub2 AS (
  SELECT
    d.d_year AS sales_year,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    SUM(ss.ss_net_paid) AS total_net_paid,
    (SELECT avg(ss2.ss_net_paid)
     FROM store_sales ss2
     JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
     WHERE d2.d_year = d.d_year) AS avg_year_net_paid
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE ss.ss_list_price > 50
    AND d.d_weekend = 'Y'
  GROUP BY d.d_year
)
SELECT sales_year, profit_flag, total_net_paid, avg_year_net_paid
FROM sub1
INTERSECT
SELECT sales_year, profit_flag, total_net_paid, avg_year_net_paid
FROM sub2
ORDER BY sales_year DESC, total_net_paid DESC
LIMIT 100
