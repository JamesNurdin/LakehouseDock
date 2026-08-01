WITH filtered_dates AS (
   SELECT
      d_date_sk,
      d_date_id,
      d_day_name,
      d_quarter_name,
      d_holiday,
      d_fy_year,
      regexp_extract(d_date_id, '^([0-9]{4})', 1) AS year_str,
      concat(d_day_name, '-', d_quarter_name) AS day_quarter,
      substr(d_quarter_name, 1, 3) AS quarter_prefix
   FROM date_dim
   WHERE
      regexp_like(d_day_name, '^S')
      AND d_holiday LIKE '%DAY%'
)
SELECT
   fd.day_quarter,
   fd.quarter_prefix,
   fd.year_str,
   COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
   SUM(cs.cs_net_profit) AS total_profit,
   AVG(cs.cs_net_profit) AS avg_profit
FROM filtered_dates fd
JOIN catalog_sales cs
   ON cs.cs_sold_date_sk = fd.d_date_sk
WHERE
   cs.cs_net_paid_inc_ship > 1000
   AND EXISTS (
       SELECT 1
       FROM catalog_sales cs3
       WHERE cs3.cs_ship_date_sk = cs.cs_ship_date_sk
         AND cs3.cs_net_profit > 5000
   )
GROUP BY
   fd.day_quarter,
   fd.quarter_prefix,
   fd.year_str
ORDER BY
   total_profit DESC
LIMIT 100
