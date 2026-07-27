WITH filtered AS (
   SELECT
       cp.cp_department AS department,
       regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
       d.d_year AS year,
       cr.cr_return_amount AS return_amount,
       ws.ws_net_profit AS net_profit,
       cp.cp_catalog_page_id AS catalog_page_id,
       wp.wp_web_page_sk AS web_page_sk,
       CONCAT(wp.wp_url, '_', CAST(d.d_year AS VARCHAR)) AS url_year
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   WHERE regexp_like(cp.cp_description, '(?i)promo')
     AND wp.wp_url LIKE '%example.com%'
)
SELECT DISTINCT
    department,
    domain,
    year,
    url_year,
    SUM(return_amount) AS total_return_amount,
    SUM(net_profit) AS total_net_profit,
    COUNT(DISTINCT catalog_page_id) AS distinct_catalog_pages,
    COUNT(DISTINCT web_page_sk) AS distinct_web_pages,
    RANK() OVER (PARTITION BY department ORDER BY SUM(return_amount) DESC) AS dept_return_rank
FROM filtered
GROUP BY department, domain, year, url_year
ORDER BY total_return_amount DESC, dept_return_rank
LIMIT 100
