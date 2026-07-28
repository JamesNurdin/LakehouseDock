WITH daily_sales AS (
  SELECT
    d.d_date,
    d.d_year,
    d.d_quarter_seq,
    we.web_site_sk,
    ss.ss_net_paid,
    ws.ws_net_paid,
    CASE WHEN ss.ss_net_paid > 5000 THEN 'High' ELSE 'Low' END AS store_sales_category,
    CASE WHEN ws.ws_net_paid > 5000 THEN 'High' ELSE 'Low' END AS web_sales_category
  FROM date_dim d
  LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  LEFT JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
  LEFT JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND d.d_quarter_seq IN (8, 9, 10, 11, 12)
    AND we.web_country = 'United States'
    AND cc.cc_state = 'CA'
    AND cp.cp_type = 'C'
    AND ss.ss_quantity > 0
    AND ws.ws_quantity > 0
),
agg_sales AS (
  SELECT
    d_date,
    d_year,
    d_quarter_seq,
    web_site_sk,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    COUNT(*) FILTER (WHERE store_sales_category = 'High') AS high_store_sales_cnt,
    COUNT(*) FILTER (WHERE web_sales_category = 'High') AS high_web_sales_cnt
  FROM daily_sales
  GROUP BY
    d_date,
    d_year,
    d_quarter_seq,
    web_site_sk
)
SELECT
  d_date,
  d_year,
  d_quarter_seq,
  web_site_sk,
  total_store_sales,
  total_web_sales,
  high_store_sales_cnt,
  high_web_sales_cnt,
  RANK() OVER (PARTITION BY d_year ORDER BY (total_store_sales + total_web_sales) DESC) AS sales_rank,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY d_date) AS day_seq
FROM agg_sales
ORDER BY sales_rank
LIMIT 100
