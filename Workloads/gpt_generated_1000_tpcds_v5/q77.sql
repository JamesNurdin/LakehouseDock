WITH ss_join AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    ss.ss_store_sk,
    ss.ss_cdemo_sk,
    ss.ss_net_paid,
    ss.ss_net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
    AND cd.cd_gender = 'M'
),
cs_join AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_ext_sales_price,
    cs.cs_ext_ship_cost
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cs.cs_ext_sales_price > 1000
    AND cd.cd_gender = 'M'
    AND d.d_year = 2001
),
wp_join AS (
  SELECT
    wp.wp_access_date_sk,
    wp.wp_link_count,
    wp.wp_url
  FROM web_page wp
  JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
  WHERE wp.wp_link_count > 10
    AND d.d_year = 2001
)
SELECT
  s.s_store_id,
  s.s_store_name,
  d.d_date,
  SUM(ss.ss_net_paid) AS total_net_paid,
  SUM(ss.ss_net_profit) AS total_net_profit,
  COUNT(DISTINCT cs.cs_sold_date_sk) AS catalog_sales_days,
  AVG(wp.wp_link_count) AS avg_page_links,
  RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
FROM ss_join ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN cs_join cs ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN wp_join wp ON wp.wp_access_date_sk = d.d_date_sk
GROUP BY
  s.s_store_id,
  s.s_store_name,
  d.d_date
ORDER BY profit_rank
LIMIT 100
