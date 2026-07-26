WITH sales_by_month AS (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    d.d_moy AS month,
    cs.cs_net_profit AS profit,
    cs.cs_quantity AS quantity,
    d.d_holiday
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  UNION ALL
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    d.d_moy AS month,
    ws.ws_net_profit AS profit,
    ws.ws_quantity AS quantity,
    d.d_holiday
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
page_stats AS (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    d.d_moy AS month,
    AVG(wp.wp_char_count) AS avg_char_count,
    COUNT(*) AS page_views
  FROM web_page wp
  JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq, d.d_moy
)
SELECT
  s.year,
  s.month_seq,
  s.month,
  s.total_profit,
  s.total_quantity,
  s.month_type,
  s.profit_rank,
  COALESCE(p.avg_char_count, 0) AS avg_page_char_count,
  COALESCE(p.page_views, 0) AS page_views
FROM (
  SELECT
    year,
    month_seq,
    month,
    SUM(profit) AS total_profit,
    SUM(quantity) AS total_quantity,
    CASE WHEN MAX(d_holiday) = 'Y' THEN 'Holiday' ELSE 'Regular' END AS month_type,
    RANK() OVER (ORDER BY SUM(profit) DESC) AS profit_rank
  FROM sales_by_month
  GROUP BY year, month_seq, month
) s
LEFT JOIN page_stats p
  ON s.year = p.year AND s.month_seq = p.month_seq AND s.month = p.month
ORDER BY s.profit_rank
LIMIT 10
