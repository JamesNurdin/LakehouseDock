WITH monthly_sales AS (
   SELECT
       d.d_year AS year,
       d.d_month_seq AS month_seq,
       cs.cs_net_profit,
       sr.sr_return_amt,
       sr.sr_return_tax,
       ws.web_gmt_offset
   FROM catalog_sales cs
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t
     ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN store_returns sr
     ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN web_site ws
     ON ws.web_open_date_sk = d.d_date_sk
   WHERE d.d_fy_year = 1905
     AND cs.cs_ext_sales_price > 1000
     AND sr.sr_return_tax > 5
     AND t.t_hour BETWEEN 9 AND 17
     AND ws.web_gmt_offset = (
         SELECT MAX(web_gmt_offset) FROM web_site
     )
),
aggregated AS (
   SELECT
       year,
       month_seq,
       cs_net_profit,
       sr_return_amt
   FROM monthly_sales
)
SELECT
    year,
    month_seq,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(sr_return_amt) AS total_return_amount,
    COUNT(*) AS sales_count,
    AVG(SUM(cs_net_profit)) OVER () AS avg_monthly_profit
FROM aggregated
GROUP BY year, month_seq
HAVING SUM(cs_net_profit) > 5000
ORDER BY total_net_profit DESC
LIMIT 100
