WITH sales_agg AS (
  SELECT
    d.d_year,
    p.p_promo_sk,
    p.p_promo_name,
    wp.wp_type,
    wp.wp_url,
    SUM(ws.ws_ext_sales_price) AS total_ext_sales,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_net_profit) AS avg_net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_date >= DATE '2000-01-01'
    AND d.d_date < DATE '2002-01-01'
  GROUP BY d.d_year, p.p_promo_sk, p.p_promo_name, wp.wp_type, wp.wp_url
)
SELECT
  sa.d_year,
  sa.p_promo_name,
  sa.wp_type,
  sa.total_ext_sales,
  sa.total_quantity,
  ROUND(sa.avg_net_profit, 2) AS avg_net_profit,
  CASE WHEN regexp_like(sa.p_promo_name, '[0-9]{2}%') THEN 'Discount' ELSE 'NoDiscount' END AS discount_flag,
  regexp_extract(sa.p_promo_name, '([0-9]{2})%') AS discount_percent,
  CASE WHEN sa.wp_url LIKE '%/promo/%' THEN 'PromoURL' ELSE 'OtherURL' END AS url_category,
  substring(sa.wp_url, 1, 30) AS url_prefix,
  concat('Year ', CAST(sa.d_year AS varchar)) AS year_label,
  ROW_NUMBER() OVER (PARTITION BY sa.p_promo_name ORDER BY sa.total_ext_sales DESC) AS promo_rank_by_sales
FROM sales_agg sa
WHERE (regexp_like(sa.p_promo_name, 'sale') OR sa.wp_type LIKE 'article%')
ORDER BY sa.total_ext_sales DESC
LIMIT 100
