WITH
  store_agg AS (
    SELECT
      'store' AS sales_source,
      s.s_store_sk AS entity_id,
      d.d_year AS year,
      d.d_moy AS month,
      SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'N'
      AND d.d_year = 2001
    GROUP BY s.s_store_sk, d.d_year, d.d_moy
  ),
  web_agg AS (
    SELECT
      'web' AS sales_source,
      wp.wp_web_page_sk AS entity_id,
      d.d_year AS year,
      d.d_moy AS month,
      SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'N'
      AND d.d_year = 2001
    GROUP BY wp.wp_web_page_sk, d.d_year, d.d_moy
  ),
  combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
  )
SELECT
  sales_source,
  entity_id,
  year,
  month,
  total_sales,
  ROW_NUMBER() OVER (PARTITION BY sales_source ORDER BY total_sales DESC) AS sales_rank
FROM combined
WHERE total_sales > (
  SELECT AVG(total_sales) FROM combined
)
ORDER BY sales_source, sales_rank
LIMIT 100
