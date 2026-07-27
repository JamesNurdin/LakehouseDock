WITH sales_join AS (
  SELECT
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_ext_ship_cost,
    d.d_year,
    d.d_day_name,
    w.w_city,
    w.w_state,
    w.w_suite_number
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE w.w_city LIKE '%York%'
    AND regexp_like(w.w_suite_number, '^Suite [A-Z]$')
)
SELECT
  concat_ws(', ', w_city, w_state) AS location,
  d_year,
  CASE
    WHEN sum(cs_net_profit) > 0 THEN 'Overall Profit'
    ELSE 'Overall Loss'
  END AS profit_status,
  sum(cs_net_paid) AS total_net_paid,
  avg(cs_ext_ship_cost) AS avg_ship_cost,
  regexp_extract(w_suite_number, 'Suite (\\w+)', 1) AS suite_code,
  substring(d_day_name, 1, 3) AS day_abbrev
FROM sales_join
GROUP BY
  concat_ws(', ', w_city, w_state),
  d_year,
  regexp_extract(w_suite_number, 'Suite (\\w+)', 1),
  substring(d_day_name, 1, 3)
HAVING sum(cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
