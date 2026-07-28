WITH store_sales_agg AS (
    SELECT
        regexp_extract(s.s_city, '^([A-Za-z]{2})', 1) AS category,
        d.d_year AS year,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE s.s_city LIKE '%ville%'
      AND regexp_like(s.s_city, '[A-Za-z]{2}ville')
    GROUP BY regexp_extract(s.s_city, '^([A-Za-z]{2})', 1), d.d_year
),
web_sales_agg AS (
    SELECT
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS category,
        d.d_year AS year,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*sports.*')
      AND NOT EXISTS (
          SELECT 1 FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
      )
    GROUP BY regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1), d.d_year
)
SELECT category, year, total_sales
FROM store_sales_agg
UNION ALL
SELECT category, year, total_sales
FROM web_sales_agg
LIMIT 100
