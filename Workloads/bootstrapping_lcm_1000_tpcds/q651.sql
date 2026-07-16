WITH aggregated_sales AS (
  SELECT
    s.s_store_name,
    s.s_state,
    wp.wp_type,
    COUNT(*) AS num_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_net_paid) AS avg_paid,
    MIN(td.t_time) AS earliest_sale_time,
    MAX(wp_access_date.d_date) AS last_access_date
  FROM catalog_sales cs
  JOIN date_dim sold_date
    ON cs.cs_sold_date_sk = sold_date.d_date_sk
  JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN date_dim ship_date
    ON cs.cs_ship_date_sk = ship_date.d_date_sk
  JOIN store s
    ON s.s_closed_date_sk = sold_date.d_date_sk
  JOIN web_page wp
    ON wp.wp_creation_date_sk = sold_date.d_date_sk
  JOIN date_dim wp_access_date
    ON wp.wp_access_date_sk = wp_access_date.d_date_sk
  WHERE cs.cs_net_profit > 0
    AND s.s_state = 'CA'
    AND wp.wp_type = 'product'
  GROUP BY s.s_store_name, s.s_state, wp.wp_type
)
SELECT
  s_store_name,
  s_state,
  wp_type,
  num_sales,
  total_profit,
  avg_paid,
  earliest_sale_time,
  last_access_date,
  ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_profit DESC) AS profit_rank_state
FROM aggregated_sales
ORDER BY total_profit DESC
LIMIT 20
